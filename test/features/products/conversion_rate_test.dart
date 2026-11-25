import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/products/domain/unit_conversion.dart';

/// A secondary unit is a whole number of main units (1 dozen = 12 pcs).
/// Stock is counted in whole main units, so a fractional conversion cannot
/// be deducted correctly; and 1 would just be the main unit again.
void main() {
  test('whole numbers from 2 up are accepted', () {
    for (final ok in ['2', '6', '12', '144', ' 24 ', '12.0', '12.']) {
      expect(validateConversionRate(ok), isNull, reason: ok);
    }
  });

  test('fractions are rejected', () {
    for (final bad in ['2.5', '0.5', '12.25', '1.999']) {
      expect(validateConversionRate(bad), isNotNull, reason: bad);
    }
  });

  test('1, zero, negatives, blanks and junk are rejected', () {
    for (final bad in ['1', '1.0', '0', '-12', '', '  ', 'abc', null]) {
      expect(validateConversionRate(bad), isNotNull, reason: '$bad');
    }
  });

  test('absurdly large values are rejected', () {
    expect(validateConversionRate('1000000'), isNull);
    expect(validateConversionRate('1000001'), isNotNull);
  });

  test('parseConversionRate returns the whole number, or null', () {
    expect(parseConversionRate('12'), 12);
    expect(parseConversionRate('12.0'), 12);
    expect(parseConversionRate('2.5'), isNull);
    expect(parseConversionRate('1'), isNull);
  });

  test('an existing fractional rate is flagged for the form', () {
    expect(isValidConversionRate(12), isTrue);
    expect(isValidConversionRate(2.5), isFalse);
    expect(isValidConversionRate(1), isFalse);
  });
}
