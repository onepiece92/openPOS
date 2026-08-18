import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart' show TaxRate;
import 'package:pos_app/features/cart/domain/cart_calculator.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/cart_session.dart';

/// Pure-math coverage for [CartCalculator]. No DB, no Riverpod.
void main() {
  // ── Fixtures ───────────────────────────────────────────────────────────────

  CartItem item(
    int id, {
    required double price,
    int qty = 1,
    bool taxable = true,
    double lineDiscount = 0,
  }) =>
      CartItem(
        productId: id,
        name: 'Item $id',
        unitPrice: price,
        quantity: qty,
        isTaxable: taxable,
        lineDiscount: lineDiscount,
      );

  CartSession session({
    double discount = 0,
    bool isPercent = false,
    bool taxEnabled = true,
    int redeem = 0,
  }) =>
      CartSession(
        ticketNumber: '#0001',
        openedAt: DateTime(2026, 1, 1),
        orderDiscount: discount,
        orderDiscountIsPercent: isPercent,
        taxEnabled: taxEnabled,
        loyaltyPointsToRedeem: redeem,
      );

  TaxRate rate(
    int id,
    double fraction, {
    bool inclusive = false,
    String rounding = 'half_up',
  }) =>
      TaxRate(
        id: id,
        name: 'Tax $id',
        rate: fraction,
        inclusionType: inclusive ? 'inclusive' : 'exclusive',
        roundingMode: rounding,
        isCompound: false,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  Matcher money(double v) => closeTo(v, 1e-9);

  /// Passes when `v == double.parse(v.toStringAsFixed(2))`, i.e. no float noise.
  final roundTripsAt2dp = predicate<double>(
    (v) => v == double.parse(v.toStringAsFixed(2)),
    'is an exact 2-dp value',
  );

  // ── Baseline behaviour (pinned) ────────────────────────────────────────────

  group('subtotal & discounts', () {
    test('empty cart yields zeros', () {
      final s = CartCalculator.compute(
          items: const [], session: session(), selectedRates: const []);
      expect(s.subtotal, 0);
      expect(s.orderDiscount, 0);
      expect(s.taxAmount, 0);
      expect(s.total, 0);
      expect(s.taxLines, isEmpty);
      expect(s.pointsToEarn, 0);
    });

    test('subtotal sums unit × qty minus line discounts', () {
      final s = CartCalculator.compute(
        items: [
          item(1, price: 10, qty: 2), // 20
          item(2, price: 5, qty: 3, lineDiscount: 1), // 14
        ],
        session: session(),
        selectedRates: const [],
      );
      expect(s.subtotal, money(34));
      expect(s.total, money(34));
    });

    test('percent order discount', () {
      final s = CartCalculator.compute(
        items: [item(1, price: 200)],
        session: session(discount: 10, isPercent: true),
        selectedRates: const [],
      );
      expect(s.orderDiscount, money(20));
      expect(s.total, money(180));
    });

    test('flat order discount is clamped to [0, subtotal]', () {
      final over = CartCalculator.compute(
        items: [item(1, price: 50)],
        session: session(discount: 80),
        selectedRates: const [],
      );
      expect(over.orderDiscount, money(50));
      expect(over.total, 0);

      final negative = CartCalculator.compute(
        items: [item(1, price: 50)],
        session: session(discount: -5),
        selectedRates: const [],
      );
      expect(negative.orderDiscount, 0);
      expect(negative.total, money(50));
    });
  });

  group('tax — baseline', () {
    test('exclusive tax is added on top of the total', () {
      final s = CartCalculator.compute(
        items: [item(1, price: 100)],
        session: session(),
        selectedRates: [rate(1, 0.13)],
      );
      expect(s.taxLines, hasLength(1));
      expect(s.taxLines.single.amount, money(13));
      expect(s.taxAmount, money(13));
      expect(s.total, money(113));
    });

    test('inclusive tax is reported but does not change the total', () {
      final s = CartCalculator.compute(
        items: [item(1, price: 113)],
        session: session(),
        selectedRates: [rate(1, 0.13, inclusive: true)],
      );
      expect(s.taxLines.single.amount, money(13));
      expect(s.taxLines.single.taxableAmount, money(100));
      expect(s.taxAmount, money(13));
      expect(s.total, money(113));
    });

    test('non-taxable items are skipped', () {
      final s = CartCalculator.compute(
        items: [item(1, price: 100), item(2, price: 100, taxable: false)],
        session: session(),
        selectedRates: [rate(1, 0.10)],
      );
      expect(s.taxLines.single.amount, money(10));
      expect(s.taxLines.single.taxableAmount, money(100));
      expect(s.total, money(210));
    });

    test('taxEnabled=false zeroes totals but keeps the would-be line amount',
        () {
      final s = CartCalculator.compute(
        items: [item(1, price: 100)],
        session: session(taxEnabled: false),
        selectedRates: [rate(1, 0.13)],
      );
      expect(s.taxEnabled, isFalse);
      expect(s.taxLines.single.amount, money(13)); // UI shows it greyed out
      expect(s.taxAmount, 0);
      expect(s.total, money(100));
    });

    test('one line per selected rate, each computed independently', () {
      final s = CartCalculator.compute(
        items: [item(1, price: 100)],
        session: session(),
        selectedRates: [rate(1, 0.13), rate(2, 0.02)],
      );
      expect(s.taxLines.map((l) => l.amount), [money(13), money(2)]);
      expect(s.total, money(115));
    });
  });

  // ── Fixes ─────────────────────────────────────────────────────────────────

  group('tax — order discount is prorated across lines', () {
    test('mixed taxable / non-taxable cart taxes only the taxable net', () {
      // Old code subtracted (discount × rate) from the whole tax line,
      // treating the non-taxable item as if it were taxable: 13 − 2.6 = 10.40.
      final s = CartCalculator.compute(
        items: [item(1, price: 100), item(2, price: 100, taxable: false)],
        session: session(discount: 10, isPercent: true),
        selectedRates: [rate(1, 0.13)],
      );
      final line = s.taxLines.single;
      expect(line.taxableAmount, money(90)); // 100 × 0.9
      expect(line.amount, money(11.70)); // 13% of 90
      expect(s.total, money(180 + 11.70));
    });

    test('inclusive rate reflects the discounted base', () {
      // Old code ignored the order discount for inclusive rates (reported 13).
      final s = CartCalculator.compute(
        items: [item(1, price: 113)],
        session: session(discount: 10, isPercent: true),
        selectedRates: [rate(1, 0.13, inclusive: true)],
      );
      final line = s.taxLines.single;
      expect(line.amount, money(11.70)); // 101.70 − 101.70/1.13
      expect(line.taxableAmount, money(90));
      expect(s.total, money(101.70));
    });

    test('flat discount is prorated by line weight', () {
      // 300 subtotal, 30 flat discount → keep 90 % of every line.
      final s = CartCalculator.compute(
        items: [item(1, price: 100), item(2, price: 200, taxable: false)],
        session: session(discount: 30),
        selectedRates: [rate(1, 0.10)],
      );
      expect(s.taxLines.single.taxableAmount, money(90));
      expect(s.taxLines.single.amount, money(9));
      expect(s.total, money(270 + 9));
    });
  });

  group('tax — rounding', () {
    test('a discounted line is rounded once, not twice', () {
      // 1.25 line, 0.05 line discount → net 1.20 → 13 % = 0.156 → 0.16.
      // Old code: round(0.1625) − round(0.0065) = 0.16 − 0.01 = 0.15.
      final s = CartCalculator.compute(
        items: [item(1, price: 1.25, lineDiscount: 0.05)],
        session: session(),
        selectedRates: [rate(1, 0.13)],
      );
      expect(s.taxLines.single.amount, money(0.16));
    });

    test('honours tax_rates.rounding_mode', () {
      // net 0.25 × 50 % = 0.125 exactly — the classic half-cent case.
      final items = [item(1, price: 0.25)];
      double amt(String mode) => CartCalculator.compute(
            items: items,
            session: session(),
            selectedRates: [rate(1, 0.5, rounding: mode)],
          ).taxLines.single.amount;

      expect(amt('half_up'), money(0.13));
      expect(amt('half_even'), money(0.12));
      expect(amt('truncate'), money(0.12));
    });
  });

  group('rounding boundary — every output is a clean 2-dp value', () {
    test('percent discount does not leak float noise into the total', () {
      // 10 − 33 % used to produce total = 6.699999999999999 (stored as-is).
      final s = CartCalculator.compute(
        items: [item(1, price: 10)],
        session: session(discount: 33, isPercent: true),
        selectedRates: const [],
      );
      expect(s.orderDiscount, 3.30);
      expect(s.total, 6.70); // exact equality on purpose
    });

    test('line subtotal is rounded before it reaches order_items', () {
      final i = item(1, price: 1.1, qty: 3); // 3.3000000000000003 raw
      expect(i.lineSubtotal, 3.30);
    });

    test('summed tax lines and total are clean', () {
      final s = CartCalculator.compute(
        items: [item(1, price: 1.25, lineDiscount: 0.05), item(2, price: 0.99)],
        session: session(),
        selectedRates: [rate(1, 0.13), rate(2, 0.02)],
      );
      // 0.16 + 0.13 and 0.02 + 0.02 — float sums would carry …0004 noise.
      expect(s.taxAmount, 0.33);
      expect(s.total, 2.19 + 0.33);
      for (final l in s.taxLines) {
        expect(l.amount, roundTripsAt2dp);
        expect(l.taxableAmount, roundTripsAt2dp);
      }
    });

    test('points are earned on the rounded total', () {
      // Raw total 6.999999… would floor to 6 pts; rounded 7.00 → 7.
      final s = CartCalculator.compute(
        items: [item(1, price: 10)],
        session: session(discount: 30, isPercent: true),
        selectedRates: const [],
        loyaltyEnabled: true,
        loyaltyEarnRate: 1,
      );
      expect(s.total, 7.00);
      expect(s.pointsToEarn, 7);
    });
  });

  group('loyalty', () {
    test('redeemed points reduce the total by pointValue each', () {
      final s = CartCalculator.compute(
        items: [item(1, price: 100)],
        session: session(redeem: 30),
        selectedRates: const [],
        loyaltyEnabled: true,
        loyaltyPointValue: 0.5,
        loyaltyEarnRate: 0.1,
      );
      expect(s.loyaltyDiscount, money(15));
      expect(s.total, money(85));
      expect(s.pointsToEarn, 8); // floor(85 × 0.1)
    });

    test('total is clamped at zero when points exceed the bill', () {
      final s = CartCalculator.compute(
        items: [item(1, price: 10)],
        session: session(redeem: 500),
        selectedRates: const [],
        loyaltyEnabled: true,
        loyaltyPointValue: 1,
      );
      expect(s.total, 0);
    });

    test('disabled loyalty neither discounts nor earns', () {
      // Old provider ignored the enabled flag, so a customer attached to an
      // order still accrued points with loyalty switched off in settings.
      final s = CartCalculator.compute(
        items: [item(1, price: 100)],
        session: session(redeem: 30),
        selectedRates: const [],
        loyaltyEnabled: false,
        loyaltyPointValue: 1,
        loyaltyEarnRate: 1,
      );
      expect(s.loyaltyDiscount, 0);
      expect(s.total, money(100));
      expect(s.pointsToEarn, 0);
    });
  });
}
