/// All monetary values are passed and returned as doubles (store currency units).
/// Rounding is applied once per line (not accumulated across lines) to avoid
/// penny discrepancies.
library;

enum RoundingMode { halfUp, halfEven, truncate }

class TaxCalculator {
  const TaxCalculator._();

  /// Calculate tax amount for a single order line.
  ///
  /// [unitPrice]      — price of one unit (post any per-line discount)
  /// [quantity]       — number of units
  /// [rate]           — tax rate as a fraction, e.g. 0.10 for 10 %
  /// [isInclusive]    — true = tax already embedded in unitPrice
  /// [roundingMode]   — how to round the final cent value
  static double lineItemTax({
    required double unitPrice,
    required int quantity,
    required double rate,
    required bool isInclusive,
    RoundingMode roundingMode = RoundingMode.halfUp,
  }) {
    final lineTotal = unitPrice * quantity;
    final rawTax = isInclusive
        ? lineTotal - (lineTotal / (1 + rate)) // extract embedded tax
        : lineTotal * rate; // add on top
    return _round(rawTax, roundingMode);
  }

  /// Calculate compound tax (tax-on-tax).
  /// [baseTax] is the already-computed first-layer tax amount.
  static double compoundTax({
    required double lineTotal,
    required double baseTax,
    required double compoundRate,
    RoundingMode roundingMode = RoundingMode.halfUp,
  }) {
    return _round((lineTotal + baseTax) * compoundRate, roundingMode);
  }

  /// Extract the pre-tax price from an inclusive-tax price.
  static double priceBeforeTax(double inclusivePrice, double rate) {
    return inclusivePrice / (1 + rate);
  }

  static double _round(double value, RoundingMode mode) {
    switch (mode) {
      case RoundingMode.halfUp:
        return (value * 100).roundToDouble() / 100;
      case RoundingMode.halfEven:
        // Banker's rounding to 2 decimal places
        final scaled = value * 100;
        final floor = scaled.floor();
        final fraction = scaled - floor;
        final rounded =
            (fraction == 0.5 && floor.isEven) ? floor.toDouble() : scaled.roundToDouble();
        return rounded / 100;
      case RoundingMode.truncate:
        return (value * 100).truncateToDouble() / 100;
    }
  }
}
