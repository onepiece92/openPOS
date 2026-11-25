import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/utils/percent.dart';

void main() {
  test('a rate is shown as it is: up to two decimals, no trailing zeros', () {
    expect(formatRatePercent(0.13), '13%');
    expect(formatRatePercent(0.0825), '8.25%');
    expect(formatRatePercent(0.125), '12.5%');
    expect(formatRatePercent(0.10), '10%');
    expect(formatRatePercent(0.07), '7%');
    expect(formatRatePercent(0.2), '20%');
    expect(formatRatePercent(0.055), '5.5%');
    expect(formatRatePercent(0.08875), '8.875%');
    expect(formatRatePercent(8.875 / 100), '8.875%');
    expect(formatRatePercent(0), '0%');
    expect(formatRatePercent(1), '100%');
  });

  test('edit fields are pre-filled with the exact rate, no trailing zeros', () {
    expect(formatRateForEdit(0.13), '13');
    expect(formatRateForEdit(0.08875), '8.875');
    expect(formatRateForEdit(0.125), '12.5');
    expect(formatRateForEdit(0.0825), '8.25');
    expect(formatPercentNumber(13.0), '13');
    expect(formatPercentNumber(7.5), '7.5');
    // What the field shows parses back to the same rate.
    for (final pct in [13.0, 8.875, 12.5, 8.25, 0.1, 99.9999]) {
      expect(double.parse(formatPercentNumber(pct)), pct);
    }
  });

  test('rate inputs take at most four decimals', () {
    String? accepted(String s) => kPercentInputPattern.stringMatch(s);
    expect(accepted('8.875'), '8.875');
    expect(accepted('8.8755'), '8.8755');
    expect(accepted('8.87555'), '8.8755');
  });

  test('a number already in percent', () {
    expect(formatPercent(13), '13%');
    expect(formatPercent(8.25), '8.25%');
    expect(formatPercent(33.33), '33.33%');
    expect(formatPercent(12.50), '12.5%');
    expect(formatPercent(100), '100%');
  });
}
