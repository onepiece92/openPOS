/// One tax rate's contribution to the cart, computed by [CartCalculator].
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

  /// Net base this rate was applied to: the discounted value of the taxable
  /// lines only. For inclusive rates this is the pre-tax portion.
  final double taxableAmount;
}

/// Derived totals for the current cart. Immutable snapshot — see
/// [CartCalculator.compute] for the math.
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
