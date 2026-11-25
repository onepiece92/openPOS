/// All monetary values are passed and returned as doubles (store currency units).
/// Tax is an invoice-level figure: [CartCalculator] calls [TaxCalculator.invoiceTax]
/// once per rate with the order's whole taxable amount, so it is rounded once.
library;

import 'package:pos_app/core/utils/money.dart';

export 'package:pos_app/core/utils/money.dart' show RoundingMode;

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

  /// Tax on a whole invoice's taxable [amount] at [rate], rounded once.
  ///
  /// [isInclusive] false: the tax to add on top, `amount × rate`.
  /// [isInclusive] true: the tax already inside [amount],
  /// `amount × rate / (1 + rate)`.
  ///
  /// Worked in whole cents and millionths of a percent with integers, so the
  /// result is exact however large the invoice is — a double product such as
  /// `1.5 × 0.13` lands a hair under the half-cent it should round up from.
  static double invoiceTax({
    required double amount,
    required double rate,
    required bool isInclusive,
    RoundingMode roundingMode = RoundingMode.halfUp,
  }) {
    if (!amount.isFinite || !rate.isFinite || amount <= 0 || rate <= 0) {
      return 0;
    }
    const scale = 100000000; // rate as an integer: 0.0825 → 8 250 000
    final cents = BigInt.from((amount * 100).round());
    final r = BigInt.from((rate * scale).round());
    final denominator = BigInt.from(scale) + (isInclusive ? r : BigInt.zero);
    final numerator = cents * r;
    var taxCents = numerator ~/ denominator; // floor: both are positive
    final twiceRemainder = (numerator % denominator) * BigInt.two;
    switch (roundingMode) {
      case RoundingMode.truncate:
        break;
      case RoundingMode.halfUp:
        if (twiceRemainder >= denominator) taxCents += BigInt.one;
      case RoundingMode.halfEven:
        if (twiceRemainder > denominator ||
            (twiceRemainder == denominator && taxCents.isOdd)) {
          taxCents += BigInt.one;
        }
    }
    return taxCents.toInt() / 100;
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

  static double _round(double value, RoundingMode mode) =>
      roundMoney(value, mode);
}
