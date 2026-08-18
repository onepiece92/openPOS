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
///   4. tax per rate    = Σ over taxable lines of tax(net), rounded once/line
///   5. total           = discounted subtotal + exclusive tax − loyalty
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

    // 4. One TaxLine per selected rate (always computed, even if taxEnabled
    //    is off — the UI shows the would-be amount greyed out).
    final taxLines = <TaxLine>[];
    for (final rate in selectedRates) {
      final isInclusive = rate.inclusionType == 'inclusive';
      final mode = _roundingModeFor(rate.roundingMode);
      double amount = 0;
      double taxable = 0;
      if (rate.rate > 0) {
        for (var i = 0; i < items.length; i++) {
          if (!items[i].isTaxable) continue;
          final net = netByLine[i];
          if (net <= 0) continue;
          // Single rounding per line per rate.
          final lineTax = TaxCalculator.lineItemTax(
            unitPrice: net,
            quantity: 1,
            rate: rate.rate,
            isInclusive: isInclusive,
            roundingMode: mode,
          );
          amount += lineTax;
          taxable += isInclusive ? net - lineTax : net;
        }
      }
      taxLines.add(TaxLine(
        taxRateId: rate.id,
        name: rate.name,
        rate: rate.rate,
        amount: roundMoney(amount),
        isInclusive: isInclusive,
        taxableAmount: roundMoney(taxable),
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
    final loyaltyDiscount = loyaltyEnabled
        ? roundMoney((session.loyaltyPointsToRedeem * loyaltyPointValue)
            .clamp(0.0, double.infinity))
        : 0.0;
    final total = roundMoney(
      (discountedSubtotal + exclusiveTax - loyaltyDiscount)
          .clamp(0.0, double.infinity),
    );
    final pointsToEarn =
        loyaltyEnabled ? (total * loyaltyEarnRate).floor() : 0;

    return CartSummary(
      subtotal: subtotal,
      orderDiscount: orderDiscount,
      loyaltyDiscount: loyaltyDiscount,
      taxLines: taxLines,
      taxAmount: taxAmount,
      total: total,
      taxEnabled: session.taxEnabled,
      pointsToEarn: pointsToEarn,
    );
  }

  /// Maps the `tax_rates.rounding_mode` column onto [RoundingMode].
  static RoundingMode _roundingModeFor(String raw) => switch (raw) {
        'half_even' => RoundingMode.halfEven,
        'truncate' => RoundingMode.truncate,
        _ => RoundingMode.halfUp,
      };
}
