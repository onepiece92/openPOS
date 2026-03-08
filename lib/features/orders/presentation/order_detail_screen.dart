import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/audit_service_provider.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';
import 'package:pos_app/features/receipts/presentation/receipt_pdf_service.dart';

// ─── Data bundle ──────────────────────────────────────────────────────────────

class _DetailData {
  const _DetailData({
    required this.receipt,
    required this.order,
  });
  final ReceiptBodyData receipt;
  final Order order; // kept for status / action bar
}

final _orderDetailProvider =
    FutureProvider.family<_DetailData, int>((ref, orderId) async {
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
  return _DetailData(
    receipt: ReceiptBodyData(
      order: order,
      items: items,
      taxes: taxes,
      businessName: businessName,
      customer: customer,
    ),
    order: order,
  );
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(_orderDetailProvider(orderId));
    final symbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$orderId'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              final data = detailAsync.valueOrNull;
              if (data == null) return;
              switch (v) {
                case 'pdf':
                  await downloadReceiptPdf(context, data.receipt, symbol);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'pdf',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined),
                  title: Text('Download PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'print',
                child: ListTile(
                  leading: Icon(Icons.print_outlined),
                  title: Text('Print'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share_outlined),
                  title: Text('Share'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: detailAsync.when(
        data: (data) => _DetailBody(
            data: data, symbol: symbol, orderId: orderId, ref: ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.data,
    required this.symbol,
    required this.orderId,
    required this.ref,
  });
  final _DetailData data;
  final String symbol;
  final int orderId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final order = data.order;
    final isActionable = order.status == 'completed';

    return Column(
      children: [
        // ── Status + date header ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _StatusChip(status: order.status),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    order.paymentMethod == 'cash'
                        ? Icons.payments_rounded
                        : Icons.credit_card_rounded,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(order.paymentMethod.toUpperCase(),
                      style: tt.labelMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd MMM yyyy  HH:mm').format(order.createdAt),
                    style:
                        tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Receipt body ──────────────────────────────────────────────────
        Expanded(
          child: ReceiptBody(data: data.receipt, symbol: symbol),
        ),

        // ── Action bar ────────────────────────────────────────────────────
        if (isActionable)
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Refund'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: cs.tertiary),
                      onPressed: () => _showRefundDialog(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.block_rounded),
                      label: const Text('Void'),
                      style: FilledButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError),
                      onPressed: () => _showVoidDialog(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Void ──────────────────────────────────────────────────────────────────

  Future<void> _showVoidDialog(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void transaction?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'This will mark the order as voided. Stock will NOT be restocked automatically.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
                foregroundColor: Theme.of(ctx).colorScheme.onError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Void'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final db = ref.read(databaseProvider);
    final audit = ref.read(auditServiceProvider);
    await db.ordersDao.voidOrder(orderId);
    await audit.orderVoided(
      orderId,
      reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order voided')),
      );
      Navigator.pop(context);
    }
  }

  // ── Refund ────────────────────────────────────────────────────────────────

  Future<void> _showRefundDialog(BuildContext context) async {
    final amountCtrl = TextEditingController(
        text: data.order.total.toStringAsFixed(2));
    final reasonCtrl = TextEditingController();
    bool restock = false;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Refund order?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Refund amount',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                title: const Text('Restock items'),
                subtitle: const Text('Return quantities to inventory'),
                value: restock,
                onChanged: (v) => setState(() => restock = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Refund'),
            ),
          ],
        ),
      ),
    );
    if (confirm != true || !context.mounted) return;

    final amount =
        double.tryParse(amountCtrl.text) ?? data.order.total;
    final reason =
        reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim();

    final db = ref.read(databaseProvider);
    final audit = ref.read(auditServiceProvider);

    await db.ordersDao.insertReturn(
      ReturnsCompanion.insert(
        orderId: orderId,
        amount: amount,
        restock: Value(restock),
        reason: Value(reason),
      ),
    );
    await db.ordersDao.refundOrder(orderId);

    if (restock) {
      for (final item in data.receipt.items) {
        await db.productsDao.adjustStock(item.productId, item.quantity);
      }
    }

    await audit.log(
      entityType: 'order',
      entityId: orderId,
      action: 'refund',
      newValue: {'amount': amount, 'restock': restock},
      metadata: reason != null ? {'reason': reason} : null,
    );

    if (context.mounted) {
      ref.invalidate(_orderDetailProvider(orderId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Refund of ${amount.toStringAsFixed(2)} recorded')),
      );
      Navigator.pop(context);
    }
  }
}

// ─── Status chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      'voided' => ('Voided', cs.error),
      'refunded' => ('Refunded', cs.tertiary),
      'held' => ('Held', cs.secondary),
      _ => ('Completed', cs.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
