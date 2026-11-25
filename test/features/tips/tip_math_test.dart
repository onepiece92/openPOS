import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/tips/tip_math.dart';
import 'package:pos_app/features/tips/tips_settings.dart';

void main() {
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
    test('label', () {
      expect(tipPercentLabel(15), '15%');
      expect(tipPercentLabel(12.5), '12.5%');
    });
  });
}
