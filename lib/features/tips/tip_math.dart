import 'package:pos_app/core/utils/money.dart';
import 'package:pos_app/features/cart/domain/cart_summary.dart';

/// The amount a tip percentage applies to.
///
/// Default (pre-tax): the goods after every discount, without tax —
/// subtotal − order discount − loyalty redemption, minus any tax that is
/// already inside the prices ([inclusiveTax]). Exclusive tax is never part
/// of it, since it is added on top of the subtotal.
///
/// With [postTax] the base is the whole [total] the customer is charged.
/// Never negative.
double tipBase({
  required double subtotal,
  required double orderDiscount,
  required double loyaltyDiscount,
  required double inclusiveTax,
  required double total,
  bool postTax = false,
}) {
  final base = postTax
      ? total
      : subtotal - orderDiscount - loyaltyDiscount - inclusiveTax;
  return base > 0 ? roundMoney(base) : 0.0;
}

/// [tipBase] for a cart summary. Inclusive tax only counts when tax is on.
double tipBaseOf(CartSummary s, {bool postTax = false}) => tipBase(
      subtotal: s.subtotal,
      orderDiscount: s.orderDiscount,
      loyaltyDiscount: s.loyaltyDiscount,
      inclusiveTax: s.taxEnabled
          ? s.taxLines
              .where((l) => l.isInclusive)
              .fold(0.0, (sum, l) => sum + l.amount)
          : 0.0,
      total: s.total,
      postTax: postTax,
    );

/// [percent] of [base], rounded to the cent.
double tipForPercent(double base, double percent) =>
    roundMoney(base * percent / 100);

/// A tip may be at most this many times the sale total. A tip of 10x the
/// sale is already a typo (1500 for 15); real tips are a small fraction.
const kTipMaxFactor = 10;

/// The most a tip may be on an order with no total (a free or fully
/// discounted sale): 1,000 in the shop's currency, a generous tip on a free
/// order that still stops a stray extra digit.
const kTipMaxOnFreeOrder = 1000.0;

/// The largest tip [placeOrder] accepts for a sale of [total].
double maxTipFor(double total) {
  final cap = total > 0 ? total * kTipMaxFactor : kTipMaxOnFreeOrder;
  return roundMoney(cap < kMaxMoneyAmount ? cap : kMaxMoneyAmount);
}

/// What the customer pays in all: the sale plus the tip.
double paidWithTip(double total, double tip) => roundMoney(total + tip);
