import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/database/app_database.dart' show TaxRate;
import 'package:pos_app/features/cart/domain/cart_calculator.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/cart_session.dart';

import '../../_support/calc_oracle.dart';

CartSession sess({
  double discount = 0,
  bool pct = false,
  bool tax = true,
  int redeem = 0,
  int? customer,
}) =>
    CartSession(
      ticketNumber: '#1',
      openedAt: DateTime(2026, 1, 1),
      customerId: customer,
      orderDiscount: discount,
      orderDiscountIsPercent: pct,
      taxEnabled: tax,
      loyaltyPointsToRedeem: redeem,
    );

CartItem it(int id, double price, {int qty = 1, bool taxable = true}) =>
    CartItem(
        productId: id,
        name: 'p$id',
        unitPrice: price,
        quantity: qty,
        isTaxable: taxable);


TaxRate vat({double rate = 0.13, bool inclusive = false, int id = 1}) =>
    RefRate(id, (rate * 10000).round(), inclusive, 'half_up').toRate();

void main() {
  group('VAT is worked out once per invoice, not per line', () {
    test('three lines of 0.50 at 13 % → 0.20 (per line would give 0.21)', () {
      final s = CartCalculator.compute(
        items: [it(1, 0.50), it(2, 0.50), it(3, 0.50)],
        session: sess(),
        selectedRates: [vat()],
      );
      expect(s.taxLines.single.taxableAmount, 1.50);
      expect(s.taxAmount, 0.20);
      expect(s.total, 1.70);
    });

    test('ten lines of 0.35 at 13 % → 0.46 (per line would give 0.50)', () {
      final s = CartCalculator.compute(
        items: [for (var i = 0; i < 10; i++) it(i, 0.35)],
        session: sess(),
        selectedRates: [vat()],
      );
      expect(s.taxLines.single.taxableAmount, 3.50);
      expect(s.taxAmount, 0.46);
      expect(s.total, 3.96);
    });

    test('inclusive tax is extracted once from the summed amount', () {
      // 3 × 0.50 = 1.50 inclusive → 1.50 − 1.50/1.13 = 0.1726 → 0.17
      // (per line: 3 × 0.06 = 0.18).
      final s = CartCalculator.compute(
        items: [it(1, 0.50), it(2, 0.50), it(3, 0.50)],
        session: sess(),
        selectedRates: [vat(inclusive: true)],
      );
      expect(s.taxAmount, 0.17);
      expect(s.taxLines.single.taxableAmount, 1.33);
      expect(s.total, 1.50, reason: 'inclusive tax adds nothing');
    });

    test('the order discount reduces the base; non-taxable lines stay out', () {
      // 10 × 100 taxable + 1 × 500 not; 10 % off → base 900, VAT 117.
      final s = CartCalculator.compute(
        items: [it(1, 100, qty: 10), it(2, 500, taxable: false)],
        session: sess(discount: 10, pct: true),
        selectedRates: [vat()],
      );
      expect(s.orderDiscount, 150);
      expect(s.taxLines.single.taxableAmount, 900);
      expect(s.taxAmount, 117);
      expect(s.total, 1467);
    });

    test('loyalty is taken after tax; points are earned on what was paid', () {
      final s = CartCalculator.compute(
        items: [it(1, 100)],
        session: sess(redeem: 13, customer: 1),
        selectedRates: [vat()],
        loyaltyEnabled: true,
        loyaltyEarnRate: 1,
        loyaltyPointValue: 1,
        customerLoyaltyPoints: 50,
      );
      expect(s.taxAmount, 13, reason: 'redeeming points does not cut the VAT');
      expect(s.total, 100);
      expect(s.pointsToEarn, 100);
    });
  });

  group('loyalty earn does not lose a point to float noise', () {
    for (final (total, rate, want) in [
      (4.35, 100.0, 435),
      (1.15, 100.0, 115),
      (0.29, 100.0, 29),
      (8.2, 10.0, 82),
      (1.1, 10.0, 11),
      (9.99, 1.0, 9),
      (10.0, 0.1, 1),
    ]) {
      test('$total paid at $rate pts per unit earns $want', () {
        final s = CartCalculator.compute(
          items: [it(1, total, taxable: false)],
          session: sess(customer: 1),
          selectedRates: const [],
          loyaltyEnabled: true,
          loyaltyEarnRate: rate,
          loyaltyPointValue: 1,
        );
        expect(s.pointsToEarn, want);
      });
    }

    test('every total up to 10,000.00 at 10 and 100 pts per unit', () {
      var wrong = 0;
      for (final r in [10, 100]) {
        for (var c = 0; c <= 1000000; c += 7) {
          final s = CartCalculator.compute(
            items: [it(1, c / 100, taxable: false)],
            session: sess(customer: 1),
            selectedRates: const [],
            loyaltyEnabled: true,
            loyaltyEarnRate: r.toDouble(),
            loyaltyPointValue: 1,
          );
          if (s.pointsToEarn != (c * r) ~/ 100) wrong++;
        }
      }
      expect(wrong, 0);
    });
  });

  group('CartCalculator vs exact oracle on random carts (seed 42)', () {
    void run(String label, {required bool extreme, required int n}) {
      final rnd = Random(42);
      final mism = <String, int>{};
      final examples = <String>[];
      for (var k = 0; k < n; k++) {
        final nl = 1 + rnd.nextInt(6);
        final lines = <RefLine>[];
        for (var i = 0; i < nl; i++) {
          int pc;
          final pick = rnd.nextInt(10);
          if (pick == 0) {
            pc = [0, 1, 5, 99, 995, 1005, 33333, 4999][rnd.nextInt(8)];
          } else if (extreme && pick == 1) {
            pc = 999999999; // the money-input cap, 9,999,999.99
          } else {
            pc = rnd.nextInt(extreme ? 5000000 : 100000);
          }
          // Large carts stay under ~1e8 currency units in total: that is as
          // far as roundMoney's float-noise allowance is meaningful.
          final qty = (extreme && pc < 100000 && rnd.nextInt(4) == 0)
              ? 100 + rnd.nextInt(900)
              : 1 + rnd.nextInt(12);
          lines.add(RefLine(pc, qty, rnd.nextInt(5) != 0));
        }
        final nr = rnd.nextInt(3);
        final rates = [
          for (var i = 0; i < nr; i++)
            RefRate(
                i + 1,
                [1300, 1300, 1300, 500, 825, 1000, 1500, 2000, 750, 1][
                    rnd.nextInt(10)],
                rnd.nextInt(4) == 0,
                ['half_up', 'half_up', 'half_even', 'truncate'][rnd.nextInt(4)])
        ];
        int? pm;
        var flat = 0;
        final dk = rnd.nextInt(6);
        if (dk == 1) pm = [50, 100, 125, 333, 500, 1000, 1500, 75, 1][rnd.nextInt(9)];
        if (dk == 2) pm = rnd.nextInt(1001);
        if (dk == 3) flat = rnd.nextInt(extreme ? 100000000 : 50000);
        final taxOn = rnd.nextInt(10) != 0;
        final loy = rnd.nextInt(2) == 0;
        final cust = rnd.nextInt(4) != 0;
        final pv = [100, 10, 1, 25, 50, 500, 33][rnd.nextInt(7)];
        final earn = [
          [1, 1],
          [1, 10],
          [1, 100],
          [1, 20],
          [5, 2],
          [1, 50],
          [3, 100]
        ][rnd.nextInt(7)];
        final balance = rnd.nextInt(5000);
        final request = rnd.nextInt(3) == 0 ? rnd.nextInt(6000) : 0;

        final ref = refCompute(
            lines: lines,
            rates: rates,
            discPermille: pm,
            flatDiscCents: flat,
            taxEnabled: taxOn,
            loyalty: loy,
            hasCustomer: cust,
            pvCents: pv,
            balance: balance,
            request: request,
            earnNum: earn[0],
            earnDen: earn[1]);
        if (ref.baseOnHalfCent) continue;
        final items = [
          for (var i = 0; i < lines.length; i++)
            it(i, lines[i].priceCents / 100,
                qty: lines[i].qty, taxable: lines[i].taxable)
        ];
        final s = CartCalculator.compute(
          items: items,
          session: sess(
              discount: pm != null ? pm / 10 : flat / 100,
              pct: pm != null,
              tax: taxOn,
              redeem: request,
              customer: cust ? 1 : null),
          selectedRates: [for (final r in rates) r.toRate()],
          loyaltyEnabled: loy,
          loyaltyEarnRate: earn[0] / earn[1],
          loyaltyPointValue: pv / 100,
          customerLoyaltyPoints: balance,
        );
        void chk(String f, num got, num want) {
          if (got != want) {
            mism[f] = (mism[f] ?? 0) + 1;
            if (examples.length < 12) {
              examples.add('$f got=$got want=$want lines='
                  '${lines.map((l) => '${l.priceCents}x${l.qty}${l.taxable ? 't' : 'n'}').join(',')}'
                  ' rates=${rates.map((r) => '${r.bp}${r.inclusive ? 'i' : 'e'}${r.mode}').join(',')}'
                  ' pm=$pm flat=$flat pv=$pv earn=$earn total=${s.total}');
            }
          }
        }

        chk('subtotal', cents(s.subtotal), ref.subtotal);
        chk('discount', cents(s.orderDiscount), ref.discount);
        chk('taxAmount', cents(s.taxAmount), ref.taxAmount);
        chk('loyalty', cents(s.loyaltyDiscount), ref.loyalty);
        chk('total', cents(s.total), ref.total);
        chk('pointsRedeemed', s.pointsRedeemed, ref.pointsRedeemed);
        chk('pointsEarn', s.pointsToEarn, ref.pointsEarn);
        for (var i = 0; i < rates.length; i++) {
          chk('taxLine', cents(s.taxLines[i].amount), ref.taxLineAmounts[i]);
          chk('taxable', cents(s.taxLines[i].taxableAmount), ref.taxables[i]);
        }
        // Invariants on the code's own output.
        final excl = s.taxEnabled
            ? s.taxLines
                .where((l) => !l.isInclusive)
                .fold<int>(0, (a, l) => a + cents(l.amount))
            : 0;
        chk(
            'INV total=sub-disc+exclTax-loyalty',
            cents(s.total),
            cents(s.subtotal) -
                cents(s.orderDiscount) +
                excl -
                cents(s.loyaltyDiscount));
        chk('INV total>=0', s.total >= 0 ? 1 : 0, 1);
        for (final v in [
          s.subtotal,
          s.orderDiscount,
          s.taxAmount,
          s.loyaltyDiscount,
          s.total,
          ...s.taxLines.map((l) => l.amount),
          ...s.taxLines.map((l) => l.taxableAmount)
        ]) {
          chk('INV 2dp', isClean2dp(v) ? 1 : 0, 1);
        }
        // The printed base × the rate reproduces the printed tax.
        for (var i = 0; i < rates.length; i++) {
          if (rates[i].inclusive) continue;
          final again = (Frac.i(cents(s.taxLines[i].taxableAmount)) *
                  Frac.i(rates[i].bp) /
                  Frac.i(10000))
              .round(rates[i].mode)
              .toInt();
          chk('INV base x rate = tax', cents(s.taxLines[i].amount), again);
        }
      }
      expect(mism, isEmpty, reason: '$label\n  ${examples.join('\n  ')}');
    }

    test('realistic amounts', () => run('realistic', extreme: false, n: 6000));
    test('large amounts (cap prices, quantities in the hundreds)',
        () => run('extreme', extreme: true, n: 6000));
  });

}
