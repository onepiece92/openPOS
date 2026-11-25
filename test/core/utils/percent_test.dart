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
    expect(formatRatePercent(0), '0%');
    expect(formatRatePercent(1), '100%');
  });

  test('a number already in percent', () {
    expect(formatPercent(13), '13%');
    expect(formatPercent(8.25), '8.25%');
    expect(formatPercent(33.33), '33.33%');
    expect(formatPercent(12.50), '12.5%');
    expect(formatPercent(100), '100%');
  });
}
