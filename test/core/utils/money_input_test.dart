import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/utils/money.dart';

void main() {
  group('parseMoneyInput', () {
    test('plain amounts, either decimal separator', () {
      expect(parseMoneyInput('0'), 0);
      expect(parseMoneyInput('1234'), 1234);
      expect(parseMoneyInput('1234.50'), 1234.5);
      expect(parseMoneyInput('1234,5'), 1234.5);
      expect(parseMoneyInput(' 12.05 '), 12.05);
      expect(parseMoneyInput('12.'), 12);
      expect(parseMoneyInput('.5'), 0.5);
    });

    test('ambiguous grouping is refused, never misread as 1.23', () {
      expect(parseMoneyInput('1,234'), isNull);
      expect(parseMoneyInput('1.234'), isNull);
      expect(parseMoneyInput('1.234,50'), isNull);
      expect(parseMoneyInput('1,234.50'), isNull);
      expect(parseMoneyInput('1 234'), isNull);
    });

    test('more decimals than the currency allows are refused', () {
      expect(parseMoneyInput('1.2345'), isNull);
      expect(parseMoneyInput('5.5', decimalDigits: 0), isNull);
      expect(parseMoneyInput('5', decimalDigits: 0), 5);
      expect(parseMoneyInput('1,234', decimalDigits: 0), isNull);
      expect(parseMoneyInput('1.234', decimalDigits: 3), isNull);
    });

    test('junk, signs, empty and too large are refused', () {
      for (final bad in ['', ' ', '.', 'abc', '-5', '+5', '1e3', '\$5']) {
        expect(parseMoneyInput(bad), isNull, reason: bad);
      }
      expect(parseMoneyInput('9999999.99'), kMaxMoneyAmount);
      expect(parseMoneyInput('10000000'), isNull);
    });

    test('the hint', () {
      expect(kMoneyInputHint,
          'Enter the amount as a number, for example 1234.50');
    });
  });
}
