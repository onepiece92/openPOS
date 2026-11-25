/// Percent labels and inputs that show the real figure — 13, 8.25, 12.5,
/// 8.875 — never a rounded stand-in. (Fixed one-decimal labels printed an
/// 8.25 % rate as "8.3%", zero-decimal ones as "8%", and a two-decimal
/// pre-fill turned 8.875 % into 8.88 % when the form was saved.)
library;

/// The most decimals a percentage can carry anywhere in the app. Rate
/// inputs accept no more than this, so what is typed, stored, shown and
/// pre-filled for editing are always the same number.
const int kPercentDecimals = 4;

/// Input pattern for a percentage field: digits with up to
/// [kPercentDecimals] decimals.
final RegExp kPercentInputPattern = RegExp(r'^\d*\.?\d{0,4}');

/// [value] (already in percent) as plain digits with no trailing zeros:
/// 13.0 → "13", 12.50 → "12.5", 8.875 → "8.875". This is what edit fields
/// are pre-filled with.
String formatPercentNumber(double value) {
  var text = value.toStringAsFixed(kPercentDecimals);
  if (text.contains('.')) {
    text =
        text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return text == '-0' ? '0' : text;
}

/// [value] is already in percent: 8.25 → "8.25%".
String formatPercent(double value) => '${formatPercentNumber(value)}%';

/// [rate] is a fraction, as tax rates are stored: 0.0825 → "8.25%".
String formatRatePercent(double rate) => formatPercent(rate * 100);

/// A stored tax [rate] (fraction) as the digits to edit: 0.08875 → "8.875".
String formatRateForEdit(double rate) => formatPercentNumber(rate * 100);
