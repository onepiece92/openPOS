/// Percent labels that show the real figure: up to two decimals, no
/// trailing zeros — 13%, 8.25%, 12.5%. (Fixed one-decimal labels printed an
/// 8.25 % rate as "8.3%", and zero-decimal ones as "8%".)
library;

/// [value] is already in percent: 8.25 → "8.25%".
String formatPercent(double value) {
  var text = value.toStringAsFixed(2);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  if (text == '-0') text = '0';
  return '$text%';
}

/// [rate] is a fraction, as tax rates are stored: 0.0825 → "8.25%".
String formatRatePercent(double rate) => formatPercent(rate * 100);
