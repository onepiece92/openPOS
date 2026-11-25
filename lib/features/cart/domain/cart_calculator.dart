import 'package:pos_app/core/database/app_database.dart' show TaxRate;
import 'package:pos_app/core/utils/money.dart';
import 'package:pos_app/core/utils/tax_calculator.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/cart_session.dart';
import 'package:pos_app/features/cart/domain/cart_summary.dart';

/// Pure cart math — no Riverpod, no DB. Everything the receipt and
/// [placeOrder] need is derived here from plain inputs so it can be
/// unit-tested exhaustively.
///
/// Order of operations:
///   1. subtotal        = Σ line subtotals (unit × qty − line discount)
///   2. order discount  = % or flat, clamped to [0, subtotal]
///   3. each line's net = line subtotal × (1 − discount ratio)   ← prorated
///   4. tax per rate    = rate × Σ taxable lines' net, rounded once per invoice
///   5. total           = discounted subtotal + exclusive tax − loyalty
///      (loyalty needs a customer, and never takes more points than the
///      customer has or than the amount due can use)
///
/// Every monetary field on the returned [CartSummary] is passed through
/// [roundMoney] — this is the rounding boundary for the sale flow.
class CartCalculator {
  const CartCalculator._();

  static CartSummary compute({
    required List<CartItem> items,
    required CartSession session,
    required List<TaxRate> selectedRates,
    bool loyaltyEnabled = false,
    double loyaltyEarnRate = 0,
    double loyaltyPointValue = 0,
    int customerLoyaltyPoints = 0,
  }) {
    // 1. Subtotal
    double subtotal = 0;
    for (final item in items) {
      subtotal += item.lineSubtotal;
    }
    subtotal = roundMoney(subtotal);

    // 2. Order-level discount
    final rawDiscount = session.orderDiscountIsPercent
        ? subtotal * (session.orderDiscount / 100)
        : session.orderDiscount;
    final orderDiscount =
        subtotal > 0 ? roundMoney(rawDiscount.clamp(0.0, subtotal)) : 0.0;
    final discountedSubtotal = roundMoney(subtotal - orderDiscount);

    // 3. Prorate the order discount across lines so tax is computed on what
    //    the customer actually pays for each line (handles mixed carts of
    //    taxable / non-taxable items correctly).
    final keepRatio = subtotal > 0 ? discountedSubtotal / subtotal : 1.0;
    final netByLine = [
      for (final item in items)
        (item.lineSubtotal * keepRatio).clamp(0.0, double.infinity),
    ];

    // 4. Tax is an invoice-level figure: per rate, applied once to the
    //    order's whole taxable base and rounded once — never per line, which
    //    drifts by a cent per few lines (3 × 0.50 at 13 % is 0.20, not
    //    3 × 0.07). The base is rounded first so that the printed base times
    //    the rate reproduces the printed tax.
    //    One TaxLine per selected rate (always computed, even if taxEnabled
    //    is off — the UI shows the would-be amount greyed out).
    double taxableSum = 0;
    for (var i = 0; i < items.length; i++) {
      if (items[i].isTaxable) taxableSum += netByLine[i];
    }
    final taxableGross = roundMoney(taxableSum);
    final taxLines = <TaxLine>[];
    for (final rate in selectedRates) {
      final isInclusive = rate.inclusionType == 'inclusive';
      final mode = _roundingModeFor(rate.roundingMode);
      double amount = 0;
      double taxable = 0;
      if (rate.rate > 0 && taxableGross > 0) {
        amount = TaxCalculator.invoiceTax(
          amount: taxableGross,
          rate: rate.rate,
          isInclusive: isInclusive,
          roundingMode: mode,
        );
        // Inclusive: the summed amount already holds the tax, so the base
        // is what is left once it is taken out (base + tax = amount).
        taxable =
            isInclusive ? roundMoney(taxableGross - amount) : taxableGross;
      }
      taxLines.add(TaxLine(
        taxRateId: rate.id,
        name: rate.name,
        rate: rate.rate,
        amount: amount,
        isInclusive: isInclusive,
        taxableAmount: taxable,
      ));
    }

    final taxAmount = session.taxEnabled
        ? roundMoney(taxLines.fold(0.0, (s, l) => s + l.amount))
        : 0.0;
    // Inclusive tax already sits inside the subtotal — only exclusive adds on.
    final exclusiveTax = session.taxEnabled
        ? roundMoney(taxLines
            .where((l) => !l.isInclusive)
            .fold(0.0, (s, l) => s + l.amount))
        : 0.0;

    // 5. Loyalty redemption + total
    //    Points belong to a customer, so no customer means no redemption.
    //    The request is capped by the customer's balance and by the whole
    //    points the amount due can absorb, so none are spent for nothing.
    final due = roundMoney(discountedSubtotal + exclusiveTax);
    var maxRedeemablePoints = 0;
    if (loyaltyEnabled && session.customerId != null && loyaltyPointValue > 0) {
      // The nudge keeps 10 / 0.1 from flooring to 99.
      final absorbable = ((due + 1e-9) / loyaltyPointValue).floor();
      maxRedeemablePoints =
          absorbable < customerLoyaltyPoints ? absorbable : customerLoyaltyPoints;
      if (maxRedeemablePoints < 0) maxRedeemablePoints = 0;
    }
    final pointsRedeemed =
        session.loyaltyPointsToRedeem.clamp(0, maxRedeemablePoints);
    final loyaltyDiscount = roundMoney(pointsRedeemed * loyaltyPointValue);
    final total = roundMoney(
      (due - loyaltyDiscount).clamp(0.0, double.infinity),
    );
    // Same nudge as the redemption above: 4.35 × 100 is 434.99999… in
    // binary and must still earn 435.
    final pointsToEarn =
        loyaltyEnabled ? (total * loyaltyEarnRate + 1e-9).floor() : 0;

    return CartSummary(
      subtotal: subtotal,
      orderDiscount: orderDiscount,
      loyaltyDiscount: loyaltyDiscount,
      taxLines: taxLines,
      taxAmount: taxAmount,
      total: total,
      taxEnabled: session.taxEnabled,
      pointsToEarn: pointsToEarn,
      pointsRedeemed: pointsRedeemed,
      maxRedeemablePoints: maxRedeemablePoints,
    );
  }

  /// Maps the `tax_rates.rounding_mode` column onto [RoundingMode].
  static RoundingMode _roundingModeFor(String raw) => switch (raw) {
        'half_even' => RoundingMode.halfEven,
        'truncate' => RoundingMode.truncate,
        _ => RoundingMode.halfUp,
      };
}
