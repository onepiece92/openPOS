import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/audit_service_provider.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/utils/async_feedback.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/core/utils/money.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';
import 'package:pos_app/features/receipts/presentation/receipt_pdf_service.dart';
import 'package:pos_app/features/returns/domain/process_return.dart';
import 'package:pos_app/features/returns/domain/reverse_sale.dart';
import 'package:pos_app/features/returns/domain/void_order.dart' as void_svc;
import 'package:pos_app/features/orders/domain/order_number.dart';
import 'package:pos_app/features/printing/domain/auto_print.dart';
import 'package:pos_app/features/usage/usage_providers.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';

/// The void dialog's text: only what this void will actually do.
@visibleForTesting
String voidDialogText({required bool restocks, required bool points}) {
  final does = [
    if (restocks) 'reverses every stock deduction',
    if (points) 'reverses the loyalty points redeemed and earned on it',
  ];
  final what = switch (does.length) {
    0 => '',
    1 => ' and ${does.single}',
    _ => ', ${does.first} and ${does.last}',
  };
  return 'This marks the order as voided$what.'
      '${restocks ? ' Composite components are restocked automatically.' : ''}';
}

/// "3 units put back in stock." / "No stock to put back." — what a void or
/// refund actually restocked, as its transaction found it.
@visibleForTesting
String restockedText(RestockResult r, {String none = 'No stock to put back.'}) =>
    !r.any
        ? none
        : '${r.units} ${r.units == 1 ? 'unit' : 'units'} put back in stock.';

// ─── Data bundle ──────────────────────────────────────────────────────────────

class _DetailData {
  const _DetailData({
    required this.receipt,
    required this.order,
    required this.refundable,
    required this.restockFacts,
    this.tipLeft = 0,
  });
  final ReceiptBodyData receipt;
  final Order order; // kept for status / action bar
  final double refundable; // order total less refunds so far
  final RestockFacts restockFacts; // as void / refund read them
  final double tipLeft; // order tip not yet handed back by a refund

  /// What a void or refund would restock, by the same rule they apply. Only
  /// a guide: their transaction reads it afresh, and its result is shown.
  RestockPlan restockPlan({required bool trackStock}) =>
      planRestock(restockFacts, trackStock: trackStock);

  bool get isPartlyRefunded =>
      order.status == 'completed' && refundable < order.total;
}

final _orderDetailProvider =
    FutureProvider.family<_DetailData, int>((ref, orderId) async {
  final db = ref.read(databaseProvider);
  final order = await db.ordersDao.getById(orderId);
  if (order == null) throw Exception('Order #$orderId not found');
  final items = await db.ordersDao.getItems(orderId);
  final taxes = await db.ordersDao.getTaxBreakdown(orderId);
  final businessName = ref.read(settingsProvider).businessNameOrDefault;
  Customer? customer;
  if (order.customerId != null) {
    customer = await db.customersDao.getById(order.customerId!);
  }
  PosTable? table;
  if (order.tableId != null) {
    table = await db.tablesDao.getById(order.tableId!);
  }
  return _DetailData(
    receipt: ReceiptBodyData(
      order: order,
      items: items,
      taxes: taxes,
      businessName: businessName,
      customer: customer,
      table: table,
    ),
    order: order,
    refundable: await refundableAmount(db, order),
    restockFacts: await readRestockFacts(db, order),
    tipLeft: roundMoney(
        order.tipAmount - await db.ordersDao.refundedTipTotal(orderId)),
  );
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(_orderDetailProvider(orderId));
    final fmt = ref.watch(currencyFormatterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Order ${detailAsync.valueOrNull?.order.billNo ?? '#$orderId'}'),
        actions: [
          // The Builder gives the PDF share the menu button's own rectangle
          // to anchor to (iPad shows the share sheet as a popover).
          Builder(
              builder: (menuContext) => PopupMenuButton<String>(
                    onSelected: (v) async {
                      final data = detailAsync.valueOrNull;
                      if (data == null) return;
                      switch (v) {
                        case 'pdf':
                          await downloadReceiptPdf(
                              menuContext, data.receipt, fmt);
                        case 'print':
                          // With no printer paired, printOrder is a silent no-op
                          // (right for auto-print, confusing for a tapped Print).
                          if (ref.read(printerDeviceAddressProvider) == null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Text('No printer set up yet'),
                              action: SnackBarAction(
                                label: 'Set up',
                                onPressed: () =>
                                    context.push('/settings/printer'),
                              ),
                            ));
                            return;
                          }
                          final err = await ref
                              .read(autoPrintServiceProvider)
                              .printOrder(orderId);
                          if (err != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err)),
                            );
                          } else {
                            ref.invalidate(_orderDetailProvider(orderId));
                          }
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
                    ],
                  )),
        ],
      ),
      body: detailAsync.when(
        data: (data) =>
            _DetailBody(data: data, fmt: fmt, orderId: orderId, ref: ref),
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
    required this.fmt,
    required this.orderId,
    required this.ref,
  });
  final _DetailData data;
  final CurrencyFormatter fmt;
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
              _StatusChip(
                  status:
                      data.isPartlyRefunded ? 'partly_refunded' : order.status),
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
                      style:
                          tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd MMM yyyy  HH:mm').format(order.createdAt),
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Receipt body ──────────────────────────────────────────────────
        Expanded(
          child: ReceiptBody(data: data.receipt, fmt: fmt),
        ),

        // ── Action bar ────────────────────────────────────────────────────
        if (isActionable)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    final trackStock = ref.read(featureOnProvider(Feature.stockTracking));
    final text = voidDialogText(
      // Only when something is owed back to the shelf.
      restocks: data.restockPlan(trackStock: trackStock).any,
      points: data.order.pointsRedeemed > 0 || data.order.pointsEarned > 0,
    );
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void transaction?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, key: const ValueKey('void-text')),
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
    final usage = ref.read(usageCounterProvider);
    final reason = reasonCtrl.text.trim();

    final restocked = await withErrorSnackbar(
      context,
      () => void_svc.voidOrder(
        db,
        audit,
        orderId: orderId,
        reason: reason.isEmpty ? '(no reason given)' : reason,
        trackStock: trackStock,
      ),
      failurePrefix: 'Void failed',
    );
    if (restocked == null) return;
    usage.record(UsageEvent.orderVoided);

    if (context.mounted) {
      ref.invalidate(_orderDetailProvider(orderId));
      // What the transaction did, not what the dialog expected.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Order voided. ${restockedText(restocked)}')));
      Navigator.pop(context);
    }
  }

  // ── Refund ────────────────────────────────────────────────────────────────

  Future<void> _showRefundDialog(BuildContext context) async {
    final refundable = data.refundable;
    final alreadyRefunded = data.order.total - refundable;
    final amountCtrl =
        TextEditingController(text: refundable.toStringAsFixed(2));
    final reasonCtrl = TextEditingController();
    final trackStock = ref.read(featureOnProvider(Feature.stockTracking));
    // "Restock items" only when the refund would put something back.
    final canRestock = data.restockPlan(trackStock: trackStock).any;
    final tipLeft = data.tipLeft;
    // Nothing of the goods left (e.g. a zero-total order) but a tip still to
    // give back: the dialog is just that.
    final tipOnlyOrder = refundable <= 0 && tipLeft > 0;
    bool refundTip = tipOnlyOrder;
    // On by default for a full refund (the amount starts at the full
    // refundable), off once a partial amount is typed: it puts the whole
    // order's stock back. The cashier can still change it.
    bool restock = canRestock && !tipOnlyOrder;
    var restockTouched = false;
    if (tipOnlyOrder) amountCtrl.text = '0';

    // Mirrors processReturn's rules so the cashier sees the problem before
    // confirming rather than as a failure afterwards.
    String? amountError(String raw) {
      final value = double.tryParse(raw.trim());
      if (value == null) return 'Enter the amount to refund';
      if (value < 0 || (value == 0 && !(refundTip && tipLeft > 0))) {
        return 'Amount must be greater than zero';
      }
      if (value > refundable) {
        return 'At most ${fmt.format(refundable)} can be refunded';
      }
      return null;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final error = tipOnlyOrder ? null : amountError(amountCtrl.text);
          return AlertDialog(
            title: Text(tipOnlyOrder ? 'Refund tip?' : 'Refund order?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tipOnlyOrder)
                  Text('Refund tip only (${fmt.format(tipLeft)})')
                else
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) => setState(() {
                      if (!restockTouched) {
                        restock = (double.tryParse(amountCtrl.text.trim()) ??
                                0) >=
                            refundable - 0.005;
                      }
                    }),
                    decoration: InputDecoration(
                      labelText: 'Refund amount',
                      border: const OutlineInputBorder(),
                      errorText: error,
                      helperText: alreadyRefunded > 0
                          ? '${fmt.format(alreadyRefunded)} already refunded'
                          : 'Refund less than the total for a partial refund',
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
                if (tipLeft > 0 && !tipOnlyOrder)
                  if ((double.tryParse(amountCtrl.text.trim()) ?? 0) <
                      refundable - 0.005)
                    CheckboxListTile(
                      title: const Text('Also refund tip'),
                      subtitle: Text(
                          '${fmt.format(tipLeft)} · amount 0 refunds the tip only'),
                      value: refundTip,
                      onChanged: (v) => setState(() => refundTip = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                          'The tip of ${fmt.format(tipLeft)} is refunded too'),
                    ),
                if (canRestock && !tipOnlyOrder)
                  SwitchListTile(
                    key: const ValueKey('refund-restock'),
                    title: const Text('Restock items'),
                    subtitle: const Text('Puts every item of this order back in stock'),
                    value: restock,
                    onChanged: (v) => setState(() {
                      restock = v;
                      restockTouched = true;
                    }),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed:
                    error == null ? () => Navigator.pop(ctx, true) : null,
                child: Text(tipOnlyOrder ? 'Refund tip' : 'Refund'),
              ),
            ],
          );
        },
      ),
    );
    if (confirm != true || !context.mounted) return;

    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null) return;
    final reason =
        reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim();

    final db = ref.read(databaseProvider);
    final audit = ref.read(auditServiceProvider);
    final usage = ref.read(usageCounterProvider);

    final result = await withErrorSnackbar(
      context,
      () => processReturn(
        db,
        audit,
        orderId: orderId,
        amount: amount,
        restock: restock,
        reason: reason,
        trackStock: trackStock,
        refundTip: refundTip,
      ),
      failurePrefix: 'Refund failed',
    );
    if (result == null) return;
    usage.record(UsageEvent.refundIssued);

    if (context.mounted) {
      ref.invalidate(_orderDetailProvider(orderId));
      // The tip handed back: as the transaction applied it.
      final tipBack = result.tipReturned;
      final stock = restock && !tipOnlyOrder && amount > 0
          ? ' ${restockedText(result.restocked, none: 'No stock was put back.')}'
          : '';
      final text = tipOnlyOrder || amount == 0
          ? 'Tip of ${fmt.format(tipBack)} refunded.'
          : tipBack > 0
              ? 'Refund of ${fmt.format(amount)} '
                  '(+ tip ${fmt.format(tipBack)}) recorded.$stock'
              : 'Refund of ${fmt.format(amount)} recorded.$stock';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
      'partly_refunded' => ('Partly refunded', cs.tertiary),
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
