import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/utils/tax_calculator.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

// ─── Cart session (ticket metadata) ──────────────────────────────────────────

class CartSession {
  const CartSession({
    required this.ticketNumber,
    required this.openedAt,
    this.customerId,
    this.orderDiscount = 0.0,
    this.orderDiscountIsPercent = false,
    this.taxEnabled = true,
    this.loyaltyPointsToRedeem = 0,
  });

  final String ticketNumber;
  final DateTime openedAt;
  final int? customerId;
  final double orderDiscount;
  final bool orderDiscountIsPercent;
  final bool taxEnabled;
  final int loyaltyPointsToRedeem;

  CartSession copyWith({
    int? customerId,
    double? orderDiscount,
    bool? orderDiscountIsPercent,
    bool? taxEnabled,
    int? loyaltyPointsToRedeem,
    bool clearCustomer = false,
  }) =>
      CartSession(
        ticketNumber: ticketNumber,
        openedAt: openedAt,
        customerId: clearCustomer ? null : (customerId ?? this.customerId),
        orderDiscount: orderDiscount ?? this.orderDiscount,
        orderDiscountIsPercent:
            orderDiscountIsPercent ?? this.orderDiscountIsPercent,
        taxEnabled: taxEnabled ?? this.taxEnabled,
        loyaltyPointsToRedeem:
            loyaltyPointsToRedeem ?? this.loyaltyPointsToRedeem,
      );

  static CartSession fresh() {
    final now = DateTime.now();
    final seq = now.millisecondsSinceEpoch % 10000;
    return CartSession(
      ticketNumber: '#${seq.toString().padLeft(4, '0')}',
      openedAt: now,
    );
  }
}

class CartSessionNotifier extends Notifier<CartSession> {
  @override
  CartSession build() => CartSession.fresh();

  void setCustomer(int? id) => id == null
      ? state = state.copyWith(clearCustomer: true)
      : state = state.copyWith(customerId: id);
  void setOrderDiscount(double amount, {required bool isPercent}) =>
      state = state.copyWith(
          orderDiscount: amount, orderDiscountIsPercent: isPercent);
  void setTaxEnabled(bool enabled) =>
      state = state.copyWith(taxEnabled: enabled);
  void setLoyaltyPoints(int points) =>
      state = state.copyWith(loyaltyPointsToRedeem: points.clamp(0, 999999));
  void reset() => state = CartSession.fresh();
}

final cartSessionProvider =
    NotifierProvider<CartSessionNotifier, CartSession>(CartSessionNotifier.new);

// ─── Selected tax rates ───────────────────────────────────────────────────────

class SelectedTaxRatesNotifier extends Notifier<List<int>> {
  @override
  List<int> build() {
    final defaultId = ref.watch(defaultTaxIdProvider);
    return defaultId != null ? [defaultId] : [];
  }

  void add(int id) {
    if (!state.contains(id)) state = [...state, id];
  }

  void remove(int id) => state = state.where((x) => x != id).toList();

  void reset() {
    final defaultId = ref.read(defaultTaxIdProvider);
    state = defaultId != null ? [defaultId] : [];
  }
}

final selectedTaxRatesProvider =
    NotifierProvider<SelectedTaxRatesNotifier, List<int>>(
        SelectedTaxRatesNotifier.new);

// ─── Tax line ─────────────────────────────────────────────────────────────────

class TaxLine {
  const TaxLine({
    required this.taxRateId,
    required this.name,
    required this.rate,
    required this.amount, // always computed (regardless of taxEnabled)
    required this.isInclusive,
    required this.taxableAmount,
  });

  final int taxRateId;
  final String name;
  final double rate;
  final double amount;
  final bool isInclusive;
  final double taxableAmount;
}

// ─── Cart summary ─────────────────────────────────────────────────────────────

class CartSummary {
  const CartSummary({
    required this.subtotal,
    required this.orderDiscount,
    required this.loyaltyDiscount,
    required this.taxLines,
    required this.taxAmount,
    required this.total,
    required this.taxEnabled,
    required this.pointsToEarn,
  });

  final double subtotal;
  final double orderDiscount;
  final double loyaltyDiscount; // currency value of redeemed points
  final List<TaxLine> taxLines;
  final double taxAmount;
  final double total;
  final bool taxEnabled;
  final int pointsToEarn; // pts customer will earn for this purchase

  static const zero = CartSummary(
    subtotal: 0,
    orderDiscount: 0,
    loyaltyDiscount: 0,
    taxLines: [],
    taxAmount: 0,
    total: 0,
    taxEnabled: true,
    pointsToEarn: 0,
  );
}

// ─── Cart notifier ────────────────────────────────────────────────────────────

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addProduct(Product p) {
    final existing = state.indexWhere((i) => i.productId == p.id);
    if (existing >= 0) {
      final updated = [...state];
      updated[existing] =
          updated[existing].copyWith(quantity: updated[existing].quantity + 1);
      state = updated;
    } else {
      state = [
        ...state,
        CartItem(
          productId: p.id,
          name: p.name,
          unitPrice: p.price,
          quantity: 1,
          isTaxable: p.isTaxable,
        ),
      ];
    }
  }

  void setQuantity(int productId, int qty) {
    if (qty <= 0) {
      remove(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.productId == productId) item.copyWith(quantity: qty) else item,
    ];
  }

  void remove(int productId) {
    state = state.where((i) => i.productId != productId).toList();
  }

  void setDiscount(int productId, double discount) {
    state = [
      for (final item in state)
        if (item.productId == productId)
          item.copyWith(lineDiscount: discount.clamp(0, item.lineSubtotal))
        else
          item,
    ];
  }

  /// Adds a [CartItem] directly — used when resuming a held order.
  void addItem(CartItem item) {
    final existing = state.indexWhere((i) => i.productId == item.productId);
    if (existing >= 0) {
      final updated = [...state];
      updated[existing] = updated[existing]
          .copyWith(quantity: updated[existing].quantity + item.quantity);
      state = updated;
    } else {
      state = [...state, item];
    }
  }

  void clear() {
    state = [];
    ref.read(cartSessionProvider.notifier).reset();
    ref.read(selectedTaxRatesProvider.notifier).reset();
  }

  int get itemCount => state.fold(0, (sum, i) => sum + i.quantity);
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

// ─── Cart summary provider (derived) ─────────────────────────────────────────

final cartSummaryProvider = Provider<CartSummary>((ref) {
  final items = ref.watch(cartProvider);
  final session = ref.watch(cartSessionProvider);
  final selectedIds = ref.watch(selectedTaxRatesProvider);
  final taxAsync = ref.watch(taxRatesStreamProvider);
  final allRates = taxAsync.valueOrNull ?? [];
  final earnRate = ref.watch(loyaltyEarnRateProvider);
  final pointValue = ref.watch(loyaltyPointValueProvider);

  // Resolve selected tax rate objects
  final selectedRates = selectedIds
      .map((id) {
        try {
          return allRates.firstWhere((r) => r.id == id);
        } catch (_) {
          return null;
        }
      })
      .whereType<TaxRate>()
      .toList();

  // Compute subtotal from cart items
  double subtotal = 0;
  for (final item in items) {
    subtotal += item.lineSubtotal;
  }

  // Order-level discount
  final discountAmt = session.orderDiscountIsPercent
      ? subtotal * (session.orderDiscount / 100)
      : session.orderDiscount;
  final effectiveDiscount = discountAmt.clamp(0.0, subtotal);
  final discountedSubtotal = subtotal - effectiveDiscount;

  // Compute a TaxLine per selected rate (always, regardless of taxEnabled)
  final taxLines = <TaxLine>[];
  for (final rate in selectedRates) {
    final isInclusive = rate.inclusionType == 'inclusive';
    double lineAmt = 0;
    for (final item in items) {
      if (item.isTaxable && rate.rate > 0) {
        lineAmt += TaxCalculator.lineItemTax(
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          rate: rate.rate,
          isInclusive: isInclusive,
        );
        if (item.lineDiscount > 0 && item.quantity > 0) {
          lineAmt -= TaxCalculator.lineItemTax(
            unitPrice: item.lineDiscount / item.quantity,
            quantity: item.quantity,
            rate: rate.rate,
            isInclusive: isInclusive,
          );
        }
      }
    }
    // Adjust exclusive tax for order-level discount
    if (!isInclusive && effectiveDiscount > 0 && rate.rate > 0) {
      lineAmt = (lineAmt - effectiveDiscount * rate.rate)
          .clamp(0.0, double.infinity);
    }
    taxLines.add(TaxLine(
      taxRateId: rate.id,
      name: rate.name,
      rate: rate.rate,
      amount: lineAmt.clamp(0.0, double.infinity),
      isInclusive: isInclusive,
      taxableAmount: discountedSubtotal,
    ));
  }

  final taxAmount = session.taxEnabled
      ? taxLines.fold(0.0, (s, l) => s + l.amount)
      : 0.0;

  // For inclusive tax the tax is already inside subtotal — only add exclusive tax
  final exclusiveTax = session.taxEnabled
      ? taxLines
          .where((l) => !l.isInclusive)
          .fold(0.0, (s, l) => s + l.amount)
      : 0.0;

  // Loyalty redemption: convert redeemed points to currency discount
  final loyaltyDiscount =
      (session.loyaltyPointsToRedeem * pointValue).clamp(0.0, double.infinity);

  final total = (discountedSubtotal + exclusiveTax - loyaltyDiscount)
      .clamp(0.0, double.infinity);

  // Points customer will earn = total spent * earnRate (rounded down)
  final pointsToEarn = (total * earnRate).floor();

  return CartSummary(
    subtotal: subtotal,
    orderDiscount: effectiveDiscount,
    loyaltyDiscount: loyaltyDiscount,
    taxLines: taxLines,
    taxAmount: taxAmount,
    total: total,
    taxEnabled: session.taxEnabled,
    pointsToEarn: pointsToEarn,
  );
});
