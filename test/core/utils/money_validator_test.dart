import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/utils/money.dart';

/// [validateMoneyAmount] backs every money input in the app — expense amounts,
/// selling prices, purchase costs. Returning null means "accepted".
void main() {
  test('required by default, optional on request', () {
    expect(validateMoneyAmount(''), 'Amount is required');
    expect(validateMoneyAmount(null), 'Amount is required');
    expect(validateMoneyAmount('   '), 'Amount is required');
    expect(validateMoneyAmount('', isRequired: false), isNull);
  });

  test('rejects values that are not numbers', () {
    expect(validateMoneyAmount('abc'), 'Enter a valid amount');
    expect(validateMoneyAmount('1.2.3'), 'Enter a valid amount');
    expect(validateMoneyAmount('NaN'), 'Enter a valid amount');
    expect(validateMoneyAmount('Infinity'), 'Enter a valid amount');
  });

  test('zero is rejected unless explicitly allowed', () {
    expect(validateMoneyAmount('0'), 'Amount must be greater than zero');
    expect(validateMoneyAmount('0.00'), 'Amount must be greater than zero');
    expect(validateMoneyAmount('0', allowZero: true), isNull);
  });

  test('negatives are rejected even when zero is allowed', () {
    expect(validateMoneyAmount('-1'), 'Amount cannot be negative');
    expect(validateMoneyAmount('-0.01', allowZero: true),
        'Amount cannot be negative');
  });

  test('caps at kMaxMoneyAmount', () {
    expect(validateMoneyAmount('9999999.99'), isNull);
    expect(validateMoneyAmount('10000000'),
        'Amount cannot exceed $kMaxMoneyAmountLabel');
    expect(validateMoneyAmount('999999999999999'),
        'Amount cannot exceed $kMaxMoneyAmountLabel');
  });

  test('the cap keeps whole cents exactly representable', () {
    // Every accepted amount must survive a cents round-trip unchanged —
    // that is the property the cap exists to protect.
    for (final v in [0.01, 1.0, 1234.56, 999999.99, kMaxMoneyAmount]) {
      expect(roundMoney(v), v, reason: '$v must round-trip');
      expect((v * 100).roundToDouble() / 100, v);
    }
  });

  test('noun leads the message so each field names itself', () {
    expect(validateMoneyAmount('', noun: 'Price'), 'Price is required');
    expect(validateMoneyAmount('0', noun: 'Price'),
        'Price must be greater than zero');
    expect(validateMoneyAmount('abc', noun: 'Purchase price'),
        'Enter a valid purchase price');
  });

  test('accepts ordinary amounts', () {
    for (final v in ['0.01', '5', '5.5', '1234.56', '9999999.99']) {
      expect(validateMoneyAmount(v), isNull, reason: '$v should be accepted');
    }
  });
}
