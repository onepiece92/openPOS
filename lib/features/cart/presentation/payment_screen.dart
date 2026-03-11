import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/cart/domain/cart_notifier.dart';
import 'package:pos_app/features/customers/domain/customers_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

// ─── Payment screen (/checkout/payment) ──────────────────────────────────────

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _paymentMethod = 'cash';
  final _tenderedCtrl = TextEditingController();
  final _loyaltyCtrl = TextEditingController();
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    final total = ref.read(cartSummaryProvider).total;
    final rounds = (total / 1000).ceil();
    final defaultAmt = (rounds < 1 ? 1 : rounds) * 1000;
    _tenderedCtrl.text = defaultAmt.toString();
  }

  @override
  void dispose() {
    _tenderedCtrl.dispose();
    _loyaltyCtrl.dispose();
    super.dispose();
  }

  double get _tendered => double.tryParse(_tenderedCtrl.text) ?? 0.0;

  Future<void> _placeOrder() async {
    final summary = ref.read(cartSummaryProvider);
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    if (_paymentMethod == 'cash' && _tendered < summary.total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tendered amount is less than the total')),
      );
      return;
    }

    setState(() => _placing = true);
    final db = ref.read(databaseProvider);

    final session = ref.read(cartSessionProvider);
    final orderId = await db.ordersDao.insertOrder(
      OrdersCompanion.insert(
        subtotal: summary.subtotal,
        taxTotal: Value(summary.taxAmount),
        discountTotal: Value(summary.orderDiscount),
        total: summary.total,
        paymentMethod: _paymentMethod,
        tenderedAmount: _paymentMethod == 'cash'
            ? Value(_tendered)
            : const Value.absent(),
        changeAmount: _paymentMethod == 'cash'
            ? Value((_tendered - summary.total).clamp(0, double.infinity))
            : const Value.absent(),
        customerId: session.customerId != null
            ? Value(session.customerId!)
            : const Value.absent(),
      ),
    );

    await db.ordersDao.insertItems([
      for (final item in cart)
        OrderItemsCompanion.insert(
          orderId: orderId,
          productId: item.productId,
          productName: item.name,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          discount: Value(item.lineDiscount),
          lineTotal: item.lineSubtotal,
        ),
    ]);

    if (summary.taxEnabled && summary.taxLines.isNotEmpty) {
      await db.ordersDao.insertTaxLines([
        for (final line in summary.taxLines)
          if (line.amount > 0)
            OrderTaxesCompanion.insert(
              orderId: orderId,
              taxRateId: line.taxRateId,
              taxRateName: line.name,
              taxRatePercent: line.rate,
              taxableAmount: line.taxableAmount,
              taxAmount: line.amount,
            ),
      ]);
    }

    for (final item in cart) {
      final product = await db.productsDao.getById(item.productId);
      if (product != null && product.isComposite) {
        // Deduct each component's stock instead of the composite itself
        final components =
            await db.productsDao.getComponents(item.productId);
        for (final comp in components) {
          await db.productsDao
              .deductStock(comp.componentProductId, comp.quantity * item.quantity);
        }
      } else {
        await db.productsDao.deductStock(item.productId, item.quantity);
      }
    }

    // Loyalty: redeem then earn
    if (session.customerId != null) {
      if (session.loyaltyPointsToRedeem > 0) {
        await db.customersDao.redeemLoyaltyPoints(
            session.customerId!, session.loyaltyPointsToRedeem);
      }
      if (summary.pointsToEarn > 0) {
        await db.customersDao
            .addLoyaltyPoints(session.customerId!, summary.pointsToEarn);
      }
    }

    ref.read(cartProvider.notifier).clear();
    if (mounted) {
      setState(() => _placing = false);
      context.go('/receipt/$orderId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(cartSummaryProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final loyaltyEnabled = ref.watch(loyaltyEnabledProvider);
    final customer = ref.watch(cartCustomerProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final change = (_tendered - summary.total).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      bottomNavigationBar: _PaymentActionBar(
        onConfirm: _placeOrder,
        placing: _placing,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Payment method', style: tt.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              _PaymentChip(
                label: 'Cash',
                icon: Icons.payments_rounded,
                selected: _paymentMethod == 'cash',
                onTap: () => setState(() => _paymentMethod = 'cash'),
              ),
              const SizedBox(width: 10),
              _PaymentChip(
                label: 'Card',
                icon: Icons.credit_card_rounded,
                selected: _paymentMethod == 'card',
                onTap: () => setState(() => _paymentMethod = 'card'),
              ),
            ],
          ),
          if (_paymentMethod == 'cash') ...[
            const SizedBox(height: 20),
            Text('Cash tendered', style: tt.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _tenderedCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount received from customer',
                prefixText: '$symbol ',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_tendered >= summary.total && summary.total > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Change',
                      style: tt.titleMedium
                          ?.copyWith(color: cs.onSecondaryContainer),
                    ),
                    Text(
                      '$symbol ${change.toStringAsFixed(2)}',
                      style: tt.headlineSmall?.copyWith(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          if (loyaltyEnabled && customer != null) ...[
            const SizedBox(height: 24),
            _LoyaltySection(
              customer: customer,
              summary: summary,
              symbol: symbol,
              loyaltyCtrl: _loyaltyCtrl,
              onChanged: (pts) {
                ref
                    .read(cartSessionProvider.notifier)
                    .setLoyaltyPoints(pts);
                setState(() {});
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Payment action bar ───────────────────────────────────────────────────────

class _PaymentActionBar extends ConsumerWidget {
  const _PaymentActionBar({
    required this.onConfirm,
    required this.placing,
  });

  final VoidCallback onConfirm;
  final bool placing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final summary = ref.watch(cartSummaryProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Material(
      color: cs.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: FilledButton(
            onPressed: (placing || cart.isEmpty) ? null : onConfirm,
            style: AppTheme.ctaButtonStyle(cs),
            child: placing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Confirm & Charge  $symbol ${summary.total.toStringAsFixed(2)}',
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Payment chip ─────────────────────────────────────────────────────────────

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      avatar: Icon(icon,
          size: 18, color: selected ? cs.onPrimary : cs.onSurfaceVariant),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: cs.primary,
      labelStyle: TextStyle(color: selected ? cs.onPrimary : null),
    );
  }
}

// ─── Loyalty section ──────────────────────────────────────────────────────────

class _LoyaltySection extends StatelessWidget {
  const _LoyaltySection({
    required this.customer,
    required this.summary,
    required this.symbol,
    required this.loyaltyCtrl,
    required this.onChanged,
  });

  final Customer customer;
  final CartSummary summary;
  final String symbol;
  final TextEditingController loyaltyCtrl;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final available = customer.loyaltyPoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Loyalty Points', style: tt.titleMedium),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.tertiaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.stars_rounded,
                  size: 20, color: cs.tertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${customer.name} has $available pts available',
                      style: tt.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (summary.pointsToEarn > 0)
                      Text(
                        'Will earn +${summary.pointsToEarn} pts from this sale',
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (available > 0) ...[
          const SizedBox(height: 12),
          TextField(
            controller: loyaltyCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Points to redeem (max $available)',
              prefixIcon: const Icon(Icons.redeem_rounded),
              border: const OutlineInputBorder(),
              helperText: summary.loyaltyDiscount > 0
                  ? 'Discount: $symbol ${summary.loyaltyDiscount.toStringAsFixed(2)}'
                  : null,
            ),
            onChanged: (v) {
              final pts = (int.tryParse(v) ?? 0).clamp(0, available);
              onChanged(pts);
            },
          ),
        ],
      ],
    );
  }
}
