import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/cart/domain/cart_summary.dart';
import 'package:pos_app/features/tips/tip_math.dart';
import 'package:pos_app/features/tips/tips_settings.dart';

void main() {
  tipBaseOfTests();
  group('tipBase', () {
    test('no tax, no discount: the subtotal', () {
      expect(
          tipBase(
              subtotal: 100,
              orderDiscount: 0,
              loyaltyDiscount: 0,
              inclusiveTax: 0,
              total: 100),
          100);
    });

    test('exclusive tax is not in the pre-tax base', () {
      // 100 + 13 tax = 113 total; the tip is on the 100.
      expect(
          tipBase(
              subtotal: 100,
              orderDiscount: 0,
              loyaltyDiscount: 0,
              inclusiveTax: 0,
              total: 113),
          100);
    });

    test('post-tax base is the whole total', () {
      expect(
          tipBase(
              subtotal: 100,
              orderDiscount: 0,
              loyaltyDiscount: 0,
              inclusiveTax: 0,
              total: 113,
              postTax: true),
          113);
    });

    test('inclusive tax is taken out of the pre-tax base', () {
      // 113 prices with 13 tax inside: total stays 113, base is 100.
      expect(
          tipBase(
              subtotal: 113,
              orderDiscount: 0,
              loyaltyDiscount: 0,
              inclusiveTax: 13,
              total: 113),
          100);
    });

    test('discount and loyalty come off', () {
      expect(
          tipBase(
              subtotal: 100,
              orderDiscount: 10,
              loyaltyDiscount: 5,
              inclusiveTax: 0,
              total: 85),
          85);
    });

    test('zero and over-discounted carts give zero', () {
      expect(
          tipBase(
              subtotal: 0,
              orderDiscount: 0,
              loyaltyDiscount: 0,
              inclusiveTax: 0,
              total: 0),
          0);
      expect(
          tipBase(
              subtotal: 10,
              orderDiscount: 10,
              loyaltyDiscount: 5,
              inclusiveTax: 0,
              total: 0),
          0);
    });

    test('rounds with roundMoney', () {
      expect(
          tipBase(
              subtotal: 0.1 + 0.2,
              orderDiscount: 0,
              loyaltyDiscount: 0,
              inclusiveTax: 0,
              total: 0.3),
          0.3);
      expect(tipForPercent(10.05, 15), 1.51); // 1.5075
      expect(tipForPercent(0.5, 15), 0.08); // 0.075 half-up
      expect(tipForPercent(0, 20), 0);
      expect(paidWithTip(0.1, 0.2), 0.3);
    });
  });

  group('parseTipPresets', () {
    test('accepts one to four percentages', () {
      final out = <double>[];
      expect(parseTipPresets('10, 15 20%', out), isNull);
      expect(out, [10, 15, 20]);
    });
    test('rejects empty, too many, zero, over 100, junk', () {
      final out = <double>[];
      expect(parseTipPresets('', out), isNotNull);
      expect(parseTipPresets('1 2 3 4 5', out), isNotNull);
      expect(parseTipPresets('0', out), isNotNull);
      expect(parseTipPresets('101', out), isNotNull);
      expect(parseTipPresets('abc', out), isNotNull);
      expect(parseTipPresets('100', out), isNull);
    });
    test('duplicates are dropped, order kept', () {
      final out = <double>[];
      expect(parseTipPresets('20, 15, 20 15 18', out), isNull);
      expect(out, [20, 15, 18]);
    });
    test('label', () {
      expect(tipPercentLabel(15), '15%');
      expect(tipPercentLabel(12.5), '12.5%');
    });
  });
}

CartSummary _summary({
  required double subtotal,
  required double total,
  required List<TaxLine> taxes,
  bool taxEnabled = true,
  double discount = 0,
}) =>
    CartSummary(
      subtotal: subtotal,
      orderDiscount: discount,
      loyaltyDiscount: 0,
      taxLines: taxes,
      taxAmount: taxes.fold(0.0, (s, t) => s + t.amount),
      total: total,
      taxEnabled: taxEnabled,
      pointsToEarn: 0,
    );

TaxLine _tax(double amount, {required bool inclusive}) => TaxLine(
    taxRateId: 1,
    name: 'VAT',
    rate: 0.13,
    amount: amount,
    isInclusive: inclusive,
    taxableAmount: 100);

void tipBaseOfTests() {
  group('tipBaseOf', () {
    test('inclusive 13% on 113 gives a base of 100', () {
      final s = _summary(
          subtotal: 113, total: 113, taxes: [_tax(13, inclusive: true)]);
      expect(tipBaseOf(s), 100);
      expect(tipBaseOf(s, postTax: true), 113);
    });
    test('tax off: the whole 113 is the base', () {
      final s = _summary(
          subtotal: 113,
          total: 113,
          taxes: [_tax(13, inclusive: true)],
          taxEnabled: false);
      expect(tipBaseOf(s), 113);
    });
    test('mixed inclusive and exclusive: only the inclusive tax comes off', () {
      // 113 prices (13 inside) + 5 exclusive tax = 118 total.
      final s = _summary(subtotal: 113, total: 118, taxes: [
        _tax(13, inclusive: true),
        _tax(5, inclusive: false),
      ]);
      expect(tipBaseOf(s), 100);
      expect(tipBaseOf(s, postTax: true), 118);
    });
    test('order discount comes off too: 113 - 13 incl - 11.50 = 88.50', () {
      final s = _summary(
          subtotal: 113,
          total: 101.5,
          discount: 11.5,
          taxes: [_tax(13, inclusive: true)]);
      expect(tipBaseOf(s), 88.5);
    });
  });
}
