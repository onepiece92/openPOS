import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/features/backup/data/backup_repository.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

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
      _importData(isProducts, isExpenses: isExpenses, isOrders: isOrders);
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
          if (!_isExporting)
            IconButton(
              tooltip: 'Export All (Zip forthcoming)',
              icon: const Icon(Icons.auto_awesome_rounded),
              onPressed: () async {
                // For now, sequential export is safest via share sheets
                await _runExport('Products', repo.exportProducts);
                await _runExport('Customers', repo.exportCustomers);
                await _runExport('Expenses', repo.exportExpenses);
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            '• Backups use CSV format (compatible with Excel/Sheets).\n'
            '• Use SKU to match existing products during import.\n'
            '• IMPORT ORDER: Products → Customers → Expenses → Orders.',
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
