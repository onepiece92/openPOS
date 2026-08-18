import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/app_root.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/backup/data/backup_repository.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isSnapshotting = false;

  // ── Full backup (zip snapshot) ─────────────────────────────────────────────

  Future<void> _createFullBackup() async {
    setState(() => _isSnapshotting = true);
    try {
      await ref.read(snapshotCoordinatorProvider).createAndShare();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSnapshotting = false);
    }
  }

  Future<void> _restoreFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: 'Choose a POS backup (.zip)',
    );
    final path = result?.files.single.path;
    if (path == null) return;
    await _confirmAndRestore(File(path));
  }

  Future<void> _showLocalSnapshots() async {
    final files = await ref.read(snapshotCoordinatorProvider).localSnapshots();
    if (!mounted) return;
    final picked = await showModalBottomSheet<File>(
      context: context,
      showDragHandle: true,
      builder: (_) => _LocalSnapshotsSheet(files: files),
    );
    if (picked != null && mounted) await _confirmAndRestore(picked);
  }

  Future<void> _confirmAndRestore(File zip) async {
    final SnapshotManifest manifest;
    try {
      manifest = await ref.read(snapshotCoordinatorProvider).inspect(zip);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not a usable backup: $e')),
        );
      }
      return;
    }
    if (!mounted) return;

    final when = DateFormat.yMMMd().add_jm().format(manifest.createdAt);
    final size = _fmtBytes(await zip.length());
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: Text(
          'Backup from $when ($size).\n\n'
          'This REPLACES all current data — products, orders, customers, '
          'settings — with the backup. The app will restart.\n\n'
          'Tip: create a fresh backup first if you might need today\'s data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore & restart'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // AppRoot tears down and rebuilds the whole app; this widget is gone by
    // the time it returns, so outcome is surfaced by AppRoot's own toast.
    try {
      await AppRoot.of(context).restoreFrom(zip);
    } catch (_) {/* reported by AppRoot */}
  }

  static String _fmtBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _runExport(String type, Future<void> Function() exportFn) async {
    setState(() => _isExporting = true);
    try {
      await exportFn();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$type exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _confirmAndImport(String type, bool isProducts,
      {bool isExpenses = false, bool isOrders = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import $type?'),
        content: Text(
            'This will add new records to your database. Existing items with the same identifiers may be updated. Are you sure you want to proceed?'
            '${isOrders ? "\n\nNote: Ensure Products and Customers are imported first for consistent order history." : ""}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      unawaited(
          _importData(isProducts, isExpenses: isExpenses, isOrders: isOrders));
    }
  }

  Future<void> _importData(bool isProducts,
      {bool isExpenses = false, bool isOrders = false}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) return;

    setState(() => _isImporting = true);
    try {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      final int count;
      final repo = ref.read(backupRepositoryProvider);

      if (isOrders) {
        count = await repo.importOrders(content);
      } else if (isExpenses) {
        count = await repo.importExpenses(content);
      } else if (isProducts) {
        count = await repo.importProducts(content);
      } else {
        count = await repo.importCustomers(content);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Successfully imported $count ${isOrders ? "orders" : (isExpenses ? "expenses" : (isProducts ? "products" : "customers"))}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final repo = ref.read(backupRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        actions: [
          IconButton(
            tooltip: 'Back up everything',
            icon: const Icon(Icons.archive_outlined),
            onPressed: _isSnapshotting ? null : _createFullBackup,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Full backup', cs, tt),
          _BackupTile(
            title: 'Back up everything',
            subtitle: 'Sales, catalog, customers & settings in one .zip',
            icon: Icons.archive_outlined,
            color: cs.primary,
            onTap: _isSnapshotting ? null : _createFullBackup,
            isLoading: _isSnapshotting,
          ),
          _BackupTile(
            title: 'Restore from file',
            subtitle: 'Replace all data with a backup .zip, then restart',
            icon: Icons.settings_backup_restore_rounded,
            color: cs.error,
            onTap: _isSnapshotting ? null : _restoreFromFile,
          ),
          _AutoBackupTile(onOpen: _showLocalSnapshots),
          const SizedBox(height: 20),
          _buildInfoCard(cs, tt),
          const SizedBox(height: 24),
          _SectionHeader('Products', cs, tt),
          _BackupTile(
            title: 'Export Products',
            subtitle: 'Download your catalog as CSV',
            icon: Icons.upload_rounded,
            color: cs.primary,
            onTap: _isExporting
                ? null
                : () => _runExport('Products', repo.exportProducts),
            isLoading: _isExporting,
          ),
          _BackupTile(
            title: 'Import Products',
            subtitle: 'Upload CSV to restore or update catalog',
            icon: Icons.download_rounded,
            color: cs.secondary,
            onTap:
                _isImporting ? null : () => _confirmAndImport('Products', true),
            isLoading: _isImporting,
          ),
          const SizedBox(height: 20),
          _SectionHeader('Customers', cs, tt),
          _BackupTile(
            title: 'Export Customers',
            subtitle: 'Download customer list as CSV',
            icon: Icons.people_outline_rounded,
            color: cs.primary,
            onTap: _isExporting
                ? null
                : () => _runExport('Customers', repo.exportCustomers),
            isLoading: _isExporting,
          ),
          _BackupTile(
            title: 'Import Customers',
            subtitle: 'Upload CSV to restore customers',
            icon: Icons.person_add_alt_1_rounded,
            color: cs.secondary,
            onTap: _isImporting
                ? null
                : () => _confirmAndImport('Customers', false),
            isLoading: _isImporting,
          ),
          const SizedBox(height: 20),
          _SectionHeader('Financials', cs, tt),
          _BackupTile(
            title: 'Export Expenses',
            subtitle: 'Download business expenses as CSV',
            icon: Icons.account_balance_wallet_outlined,
            color: cs.primary,
            onTap: _isExporting
                ? null
                : () => _runExport('Expenses', repo.exportExpenses),
            isLoading: _isExporting,
          ),
          _BackupTile(
            title: 'Import Expenses',
            subtitle: 'Upload CSV to restore expenses',
            icon: Icons.receipt_long_rounded,
            color: cs.secondary,
            onTap: _isImporting
                ? null
                : () => _confirmAndImport('Expenses', false, isExpenses: true),
            isLoading: _isImporting,
          ),
          const SizedBox(height: 20),
          _SectionHeader('Sales & History', cs, tt),
          _BackupTile(
            title: 'Export Order History',
            subtitle: 'Full database of orders and items',
            icon: Icons.history_rounded,
            color: cs.primary,
            onTap: _isExporting
                ? null
                : () => _runExport('Order History', repo.exportOrders),
            isLoading: _isExporting,
          ),
          _BackupTile(
            title: 'Import Order History',
            subtitle: 'Reconstruct orders from CSV',
            icon: Icons.upload_file_rounded,
            color: cs.secondary,
            onTap: _isImporting
                ? null
                : () => _confirmAndImport('Orders', false, isOrders: true),
            isLoading: _isImporting,
          ),
          _BackupTile(
            title: 'Export Sales Report',
            subtitle: 'Concise summary for accounting',
            icon: Icons.analytics_outlined,
            color: cs.tertiary,
            onTap: _isExporting
                ? null
                : () => _runExport('Sales Report', repo.exportSalesReport),
            isLoading: _isExporting,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 12),
              Text('Data Management Guide',
                  style: tt.labelLarge?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Full backup (.zip) is the complete, restorable copy — keep one off-device.\n'
            '• CSV exports below are for spreadsheets; CSV import cannot rebuild tax lines, stock history or audit log.\n'
            '• CSV IMPORT ORDER: Products → Customers → Expenses → Orders.',
            style:
                tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.cs, this.tt);
  final String title;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: tt.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _BackupTile extends StatelessWidget {
  const _BackupTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: tt.titleSmall),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Auto-backup tile ─────────────────────────────────────────────────────────

class _AutoBackupTile extends ConsumerWidget {
  const _AutoBackupTile({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final enabled = ref.watch(autoBackupEnabledProvider);
    final lastAt = ref.watch(autoBackupLastAtProvider);
    final last = lastAt == null
        ? 'never'
        : DateFormat.MMMd().add_jm().format(lastAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.history_toggle_off_rounded,
                    color: cs.tertiary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Device backups',
                        style: tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      enabled
                          ? 'Daily on launch · last $last · keeps $kAutoBackupKeep'
                          : 'Auto-backup off · tap to browse',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: (v) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setAutoBackupEnabled(v);
                  if (v) {
                    // Take one right away so the toggle has a visible effect.
                    unawaited(ref
                        .read(snapshotCoordinatorProvider)
                        .runAutoBackupIfDue());
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Local snapshots sheet ────────────────────────────────────────────────────

class _LocalSnapshotsSheet extends StatelessWidget {
  const _LocalSnapshotsSheet({required this.files});
  final List<File> files;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Text('Device backups', style: tt.titleMedium),
                const Spacer(),
                Text('${files.length} on device',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          if (files.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No automatic backups yet.\nOne is taken on first launch each day.',
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: files.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, i) {
                  final f = files[i];
                  final stat = f.statSync();
                  return ListTile(
                    leading: Icon(Icons.archive_outlined, color: cs.primary),
                    title: Text(
                      DateFormat.yMMMd().add_jm().format(stat.modified),
                    ),
                    subtitle: Text(
                      '${_BackupScreenState._fmtBytes(stat.size)} · ${p.basename(f.path)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.pop(context, f),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
