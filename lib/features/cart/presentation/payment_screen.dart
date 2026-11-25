import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/audit_service_provider.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/core/theme/tokens.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';
import 'package:pos_app/features/cart/data/place_order.dart';
import 'package:pos_app/features/customers/domain/customers_provider.dart';
import 'package:pos_app/features/printing/domain/auto_print.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/core/utils/money.dart';
import 'package:pos_app/features/tips/tip_math.dart';
import 'package:pos_app/features/tips/tips_settings.dart';
import 'package:pos_app/features/usage/usage_providers.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';

// ─── Payment screen (/checkout/payment) ──────────────────────────────────────

/// [amount] as the cash field shows it: two decimals, or none for a whole
/// amount ("12.50", "1000").
@visibleForTesting
String exactAmountText(double amount) {
  final text = amount.toStringAsFixed(2);
  return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
}

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

  // The tip lives only here until the order is placed: a chosen preset
  // percent, or a typed amount ([_customTip]). Neither = no tip.
  double? _tipPercent;
  bool _customTip = false;
  final _customTipCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final summary = ref.read(cartSummaryProvider);
    final total = summary.total;
    // Show the redemption already on this ticket (e.g. set before stepping
    // back to the cart) instead of an empty field over a live discount.
    if (summary.pointsRedeemed > 0) {
      _loyaltyCtrl.text = summary.pointsRedeemed.toString();
    }
    // Start at the exact amount due (change 0): the cashier types only when
    // handed more. It used to start at the next multiple of 1000, which put
    // "1000" and a change of 987.50 on a 12.50 sale.
    _tenderedCtrl.text = exactAmountText(total);
  }

  /// True once the cashier has typed in the cash field; until then it
  /// follows the amount due (e.g. when points are redeemed on this screen).
  bool _tenderedEdited = false;

  @override
  void dispose() {
    _tenderedCtrl.dispose();
    _loyaltyCtrl.dispose();
    _customTipCtrl.dispose();
    super.dispose();
  }

  /// The tip for [summary] under the current choice; 0 when tips are off.
  double _tipFor(CartSummary summary, TipsSettings tips) {
    if (!tips.enabled) return 0;
    if (_customTip) {
      final v = double.tryParse(_customTipCtrl.text) ?? 0.0;
      return roundMoney(v.clamp(0.0, kMaxMoneyAmount));
    }
    final pct = _tipPercent;
    if (pct == null) return 0;
    return tipForPercent(tipBaseOf(summary, postTax: tips.postTax), pct);
  }

  /// Keeps the untouched cash field on the amount due (sale plus tip).
  void _followDue() {
    if (_tenderedEdited) return;
    final summary = ref.read(cartSummaryProvider);
    final tip = _tipFor(summary, ref.read(tipsSettingsProvider));
    _tenderedCtrl.text = exactAmountText(paidWithTip(summary.total, tip));
  }

  double get _tendered => double.tryParse(_tenderedCtrl.text) ?? 0.0;

  Future<void> _placeOrder() async {
    // Checked synchronously: a second tap can arrive before the frame that
    // disables the button, and must not write a second order.
    if (_placing) return;
    final summary = ref.read(cartSummaryProvider);
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final tip = _tipFor(summary, ref.read(tipsSettingsProvider));
    final due = paidWithTip(summary.total, tip);

    // Half a cent of slack: the field holds two decimals.
    if (_paymentMethod == 'cash' && _tendered < due - 0.005) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tip > 0
                ? 'Tendered amount is less than the total with tip'
                : 'Tendered amount is less than the total')),
      );
      return;
    }

    setState(() => _placing = true);
    // Everything the cleanup needs is taken from `ref` now: once the order
    // is written the cart must be cleared and the held ticket retired even
    // if this screen was closed while it was saving, and `ref` is unusable
    // after dispose.
    final db = ref.read(databaseProvider);
    final audit = ref.read(auditServiceProvider);
    final session = ref.read(cartSessionProvider);
    final invoicePrefix = ref.read(invoicePrefixProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    // Only a sale resumed from a held ticket needs the held tickets.
    final heldOrders = session.heldTicketId == null
        ? null
        : ref.read(heldOrdersProvider.notifier);
    // Auto-print off: the print service is not even read.
    final printer = ref.read(featureOnProvider(Feature.autoPrint))
        ? ref.read(autoPrintServiceProvider)
        : null;
    final messenger = ScaffoldMessenger.of(context);
    final usage = ref.read(usageCounterProvider);
    final trackStock = ref.read(featureOnProvider(Feature.stockTracking));

    final int orderId;
    try {
      orderId = await placeOrder(
        db,
        audit,
        cart: cart,
        summary: summary,
        session: session,
        paymentMethod: _paymentMethod,
        tenderedAmount: _tendered,
        invoicePrefix: invoicePrefix,
        trackStock: trackStock,
        tipAmount: tip,
      );
    } catch (e) {
      _placing = false;
      if (mounted) setState(() {});
      if (messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Order failed: $e')),
        );
      }
      return;
    }

    // In-memory counts only; written later, off this path.
    usage.record(UsageEvent.saleCompleted);
    if (summary.pointsRedeemed > 0) {
      usage.record(UsageEvent.loyaltyPointsRedeemed);
    }

    // The cart may have been resumed from a held ticket, which now stays on
    // disk while it is edited — the sale is what retires it.
    final heldTicketId = session.heldTicketId;
    if (heldTicketId != null) {
      heldOrders?.delete(heldTicketId);
    }
    cartNotifier.clear();

    // Fire-and-forget print. Failures surface via snackbar but don't block
    // navigation to the receipt screen — receipts work paperless too.
    // The print runs through the service captured above and the error goes
    // to the captured `messenger`, which belongs to the app and outlives this
    // screen: by the time the print finishes we have navigated to the
    // receipt, so the screen's own `mounted` must not gate the error.
    // `messenger.mounted` only guards against the whole app being torn down.
    if (printer != null) {
      unawaited(printer.printOrder(orderId).then((err) {
        if (err != null && messenger.mounted) {
          messenger.showSnackBar(SnackBar(content: Text(err)));
        }
      }));
    }

    if (mounted) {
      setState(() => _placing = false);
      context.go('/receipt/$orderId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(cartSummaryProvider);
    // Keep the untouched cash field on the amount due when it changes.
    ref.listen(cartSummaryProvider.select((s) => s.total), (prev, next) {
      _followDue();
    });
    final tips = ref.watch(tipsSettingsProvider);
    final tip = _tipFor(summary, tips);
    final due = paidWithTip(summary.total, tip);
    final symbol = ref.watch(currencySymbolProvider);
    final fmt = ref.watch(currencyFormatterProvider);
    final loyalty = ref.watch(featureOnProvider(Feature.loyalty));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final change = (_tendered - due).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      bottomNavigationBar: _PaymentActionBar(
        onConfirm: _placeOrder,
        placing: _placing,
        tip: tip,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (tips.enabled) ...[
            Text('Tip', style: tt.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('No tip'),
                  selected: _tipPercent == null && !_customTip,
                  onSelected: (_) {
                    setState(() {
                      _tipPercent = null;
                      _customTip = false;
                    });
                    _followDue();
                  },
                ),
                for (final pct in tips.presets)
                  ChoiceChip(
                    label: Text(tipPercentLabel(pct)),
                    selected: !_customTip && _tipPercent == pct,
                    onSelected: (_) {
                      setState(() {
                        _tipPercent = pct;
                        _customTip = false;
                      });
                      _followDue();
                    },
                  ),
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: _customTip,
                  onSelected: (_) {
                    setState(() {
                      _tipPercent = null;
                      _customTip = true;
                    });
                    _followDue();
                  },
                ),
              ],
            ),
            if (_customTip) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customTipCtrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Tip amount',
                  prefixText: '$symbol ',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  setState(() {});
                  _followDue();
                },
              ),
            ],
            if (tip > 0) ...[
              const SizedBox(height: 12),
              _TipLine(label: 'Tip', value: fmt.format(tip)),
              _TipLine(
                  label: 'Total with tip',
                  value: fmt.format(due),
                  strong: true),
            ],
            const SizedBox(height: 20),
          ],
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
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount received from customer',
                prefixText: '$symbol ',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _tenderedEdited = true),
            ),
            if (_tendered >= due - 0.005 && due > 0) ...[
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
                      fmt.format(change),
                      style: tt.headlineSmall?.copyWith(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppFonts.mono, fontFamilyFallback: AppFonts.monoFallback,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          // Loyalty off (or Customers off): the cart's customer is never
          // looked up here.
          if (loyalty)
            _LoyaltyGate(
              summary: summary,
              fmt: fmt,
              loyaltyCtrl: _loyaltyCtrl,
              onChanged: (pts) {
                ref.read(cartSessionProvider.notifier).setLoyaltyPoints(pts);
                setState(() {});
              },
            ),
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
    this.tip = 0,
  });

  final VoidCallback onConfirm;
  final bool placing;
  final double tip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final summary = ref.watch(cartSummaryProvider);
    final fmt = ref.watch(currencyFormatterProvider);
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
                    'Confirm & Charge  ${fmt.format(paidWithTip(summary.total, tip))}',
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Tip line ─────────────────────────────────────────────────────────────────

class _TipLine extends StatelessWidget {
  const _TipLine({required this.label, required this.value, this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFamily: AppFonts.mono,
          fontWeight: strong ? FontWeight.bold : null,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
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

/// Only built while Loyalty is on: the one widget here that watches the
/// cart's customer.
class _LoyaltyGate extends ConsumerWidget {
  const _LoyaltyGate({
    required this.summary,
    required this.fmt,
    required this.loyaltyCtrl,
    required this.onChanged,
  });
  final CartSummary summary;
  final CurrencyFormatter fmt;
  final TextEditingController loyaltyCtrl;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(cartCustomerProvider);
    if (customer == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: _LoyaltySection(
        customer: customer,
        summary: summary,
        fmt: fmt,
        loyaltyCtrl: loyaltyCtrl,
        onChanged: onChanged,
      ),
    );
  }
}

class _LoyaltySection extends StatelessWidget {
  const _LoyaltySection({
    required this.customer,
    required this.summary,
    required this.fmt,
    required this.loyaltyCtrl,
    required this.onChanged,
  });

  final Customer customer;
  final CartSummary summary;
  final CurrencyFormatter fmt;
  final TextEditingController loyaltyCtrl;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final available = customer.loyaltyPoints;
    // Balance and what this order can use, whichever is smaller.
    final maxPoints = summary.maxRedeemablePoints;

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
              Icon(Icons.stars_rounded, size: 20, color: cs.tertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${customer.name} has $available pts available',
                      style:
                          tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (summary.pointsToEarn > 0)
                      Text(
                        'Will earn +${summary.pointsToEarn} pts from this sale',
                        style:
                            tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
              labelText: 'Points to redeem (max $maxPoints)',
              prefixIcon: const Icon(Icons.redeem_rounded),
              border: const OutlineInputBorder(),
              helperText: summary.loyaltyDiscount > 0
                  ? 'Discount: ${fmt.format(summary.loyaltyDiscount)}'
                  : null,
            ),
            onChanged: (v) {
              final typed = int.tryParse(v) ?? 0;
              final pts = typed.clamp(0, maxPoints);
              if (pts != typed) {
                // Keep the field honest about what will be redeemed.
                final text = pts.toString();
                loyaltyCtrl.value = TextEditingValue(
                  text: text,
                  selection: TextSelection.collapsed(offset: text.length),
                );
              }
              onChanged(pts);
            },
          ),
        ],
      ],
    );
  }
}
