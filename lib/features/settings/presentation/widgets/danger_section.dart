import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';

// ── Danger Zone ───────────────────────────────────────────────────────────────

class DangerSection extends ConsumerWidget {
  const DangerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: cs.errorContainer.withValues(alpha: 0.2),
      child: ListTile(
        leading: Icon(Icons.delete_forever_rounded, color: cs.error),
        title: Text(
          'Factory Reset',
          style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Erase all data and restart onboarding'),
        trailing: Icon(Icons.chevron_right_rounded, color: cs.error),
        onTap: () => _confirmReset(context, ref),
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Factory Reset?'),
        content: const Text(
          'This will permanently delete ALL products, orders, customers, '
          'expenses, and settings. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _doReset(context, ref);
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _doReset(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final box = ref.read(settingsBoxProvider);

    try {
      await db.transaction(() async {
        await db.delete(db.stockAdjustments).go();
        await db.delete(db.orderTaxOverrides).go();
        await db.delete(db.orderTaxes).go();
        await db.delete(db.orderItems).go();
        await db.delete(db.returns).go();
        await db.delete(db.orders).go();
        await db.delete(db.expenses).go();
        await db.delete(db.productTaxes).go();
        await db.delete(db.productComponents).go();
        await db.delete(db.products).go();
        await db.delete(db.customers).go();
        await db.delete(db.categories).go();
        await db.delete(db.taxGroupMembers).go();
        await db.delete(db.taxGroups).go();
        await db.delete(db.taxRates).go();
        await db.delete(db.expenseCategories).go();
        await db.delete(db.auditLog).go();
      });

      await box.clear();
      // State + router redirect update synchronously from the emptied box.
      ref.read(settingsProvider.notifier).reload();

      if (context.mounted) context.go('/onboarding');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e')),
        );
      }
    }
  }
}
