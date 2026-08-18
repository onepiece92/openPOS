import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/utils/money.dart';

void main() {
  group('roundMoney · halfUp (default)', () {
    test('cleans binary float noise', () {
      expect(roundMoney(6.699999999999999), 6.70);
      expect(roundMoney(0.1 + 0.2), 0.30);
      expect(roundMoney(1.1 * 3), 3.30);
    });

    test('rounds half-cents up, even when the float sits just below', () {
      // 0.145 is stored as 0.14499999…; naive (v*100).round() gives 0.14.
      expect(roundMoney(0.145), 0.15);
      expect(roundMoney(1.005), 1.01);
      expect(roundMoney(2.675), 2.68);
    });

    test('is a no-op on already-clean values', () {
      expect(roundMoney(12.34), 12.34);
      expect(roundMoney(100), 100);
      expect(roundMoney(0), 0);
    });

    test('negative values round symmetrically (away from zero on half)', () {
      expect(roundMoney(-0.145), -0.15);
      expect(roundMoney(-6.699999999999999), -6.70);
    });

    test('passes NaN / infinity through', () {
      expect(roundMoney(double.nan).isNaN, isTrue);
      expect(roundMoney(double.infinity), double.infinity);
    });
  });

  group('roundMoney · truncate', () {
    test('drops the third decimal without float undershoot', () {
      expect(roundMoney(0.156, RoundingMode.truncate), 0.15);
      // 0.29 * 100 = 28.999999…; naive truncate gives 0.28.
      expect(roundMoney(0.29, RoundingMode.truncate), 0.29);
      expect(roundMoney(0.149, RoundingMode.truncate), 0.14);
    });
  });

  group('roundMoney · halfEven', () {
    test('half-cents go to the even neighbour', () {
      expect(roundMoney(0.125, RoundingMode.halfEven), 0.12);
      expect(roundMoney(0.135, RoundingMode.halfEven), 0.14);
      expect(roundMoney(0.145, RoundingMode.halfEven), 0.14);
    });

    test('non-half values round normally', () {
      expect(roundMoney(0.126, RoundingMode.halfEven), 0.13);
      expect(roundMoney(0.124, RoundingMode.halfEven), 0.12);
    });
  });
}
