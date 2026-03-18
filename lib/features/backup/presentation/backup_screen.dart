import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup_repository.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _exportExpenses() async {
    setState(() => _isExporting = true);
    try {
      await ref.read(backupRepositoryProvider).exportExpenses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expenses exported successfully')),
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

  Future<void> _exportOrders() async {
    setState(() => _isExporting = true);
    try {
      await ref.read(backupRepositoryProvider).exportOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order history exported successfully')),
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

  Future<void> _exportSalesReport() async {
    setState(() => _isExporting = true);
    try {
      await ref.read(backupRepositoryProvider).exportSalesReport();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sales report exported successfully')),
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

  Future<void> _importData(bool isProducts, {bool isExpenses = false, bool isOrders = false}) async {
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
      if (isOrders) {
        count = await ref.read(backupRepositoryProvider).importOrders(content);
      } else if (isExpenses) {
        count = await ref.read(backupRepositoryProvider).importExpenses(content);
      } else if (isProducts) {
        count = await ref.read(backupRepositoryProvider).importProducts(content);
      } else {
        count = await ref.read(backupRepositoryProvider).importCustomers(content);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported $count ${isOrders ? "orders" : (isExpenses ? "expenses" : (isProducts ? "products" : "customers"))}')),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
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
            onTap: _isExporting ? null : _exportProducts,
            isLoading: _isExporting,
          ),
          _BackupTile(
            title: 'Import Products',
            subtitle: 'Upload CSV to restore or update catalog',
            icon: Icons.download_rounded,
            color: cs.secondary,
            onTap: _isImporting ? null : () => _importData(true),
            isLoading: _isImporting,
          ),
          const SizedBox(height: 20),
          _SectionHeader('Customers', cs, tt),
          _BackupTile(
            title: 'Export Customers',
            subtitle: 'Download customer list as CSV',
            icon: Icons.people_outline_rounded,
            color: cs.primary,
            onTap: _isExporting ? null : _exportCustomers,
            isLoading: _isExporting,
          ),
          _BackupTile(
            title: 'Import Customers',
            subtitle: 'Upload CSV to restore customers',
            icon: Icons.person_add_alt_1_rounded,
            color: cs.secondary,
            onTap: _isImporting ? null : () => _importData(false),
            isLoading: _isImporting,
          ),
          const SizedBox(height: 20),
          _SectionHeader('Financials', cs, tt),
          _BackupTile(
            title: 'Export Expenses',
            subtitle: 'Download business expenses as CSV',
            icon: Icons.account_balance_wallet_outlined,
            color: cs.primary,
            onTap: _isExporting ? null : _exportExpenses,
            isLoading: _isExporting,
          ),
          _BackupTile(
            title: 'Import Expenses',
            subtitle: 'Upload CSV to restore expenses',
            icon: Icons.receipt_long_rounded,
            color: cs.secondary,
            onTap: _isImporting ? null : () => _importData(false, isExpenses: true),
            isLoading: _isImporting,
          ),
          const SizedBox(height: 20),
          _SectionHeader('Sales & History', cs, tt),
          _BackupTile(
            title: 'Export Order History',
            subtitle: 'Full database of orders and items',
            icon: Icons.history_rounded,
            color: cs.primary,
            onTap: _isExporting ? null : _exportOrders,
            isLoading: _isExporting,
          ),
          _BackupTile(
            title: 'Import Order History',
            subtitle: 'Reconstruct orders from CSV',
            icon: Icons.upload_file_rounded,
            color: cs.secondary,
            onTap: _isImporting ? null : () => _importData(false, isOrders: true),
            isLoading: _isImporting,
          ),
          _BackupTile(
            title: 'Export Sales Report',
            subtitle: 'Concise summary for accounting',
            icon: Icons.analytics_outlined,
            color: cs.tertiary,
            onTap: _isExporting ? null : _exportSalesReport,
            isLoading: _isExporting,
          ),
        ],
      ),
    );
  }

  Future<void> _exportProducts() async {
    setState(() => _isExporting = true);
    try {
      await ref.read(backupRepositoryProvider).exportProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Products exported successfully')),
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

  Future<void> _exportCustomers() async {
    setState(() => _isExporting = true);
    try {
      await ref.read(backupRepositoryProvider).exportCustomers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customers exported successfully')),
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

  Widget _buildInfoCard(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Backups are exported in CSV format. You can open these files in Excel or Google Sheets. Matching during import is done via SKU for products.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
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
