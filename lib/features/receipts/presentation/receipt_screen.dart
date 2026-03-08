import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';

final _receiptProvider =
    FutureProvider.family<ReceiptBodyData, int>((ref, orderId) async {
  final db = ref.read(databaseProvider);
  final box = ref.read(settingsBoxProvider);
  final order = await db.ordersDao.getById(orderId);
  if (order == null) throw Exception('Order #$orderId not found');
  final items = await db.ordersDao.getItems(orderId);
  final taxes = await db.ordersDao.getTaxBreakdown(orderId);
  final businessName =
      box.get('business_name', defaultValue: 'My Store') as String;
  Customer? customer;
  if (order.customerId != null) {
    customer = await db.customersDao.getById(order.customerId!);
  }
  return ReceiptBodyData(
    order: order,
    items: items,
    taxes: taxes,
    businessName: businessName,
    customer: customer,
  );
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(_receiptProvider(orderId));
    final symbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: const _NewSaleBar(),
      body: receiptAsync.when(
        data: (data) => ReceiptBody(data: data, symbol: symbol),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ─── New sale bar ─────────────────────────────────────────────────────────────

class _NewSaleBar extends StatelessWidget {
  const _NewSaleBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Material(
      color: cs.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Sale'),
            onPressed: () => context.go('/pos'),
            style: AppTheme.ctaButtonStyle(cs),
          ),
        ),
      ),
    );
  }
}
