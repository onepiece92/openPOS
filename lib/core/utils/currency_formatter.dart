import 'package:intl/intl.dart';

/// App-wide currency formatting helper.
/// Reads locale and symbol from the store settings (injected at construction).
class CurrencyFormatter {
  CurrencyFormatter({
    required this.symbol,
    required this.locale,
    this.decimalDigits = 2,
  }) : _fmt = NumberFormat.currency(
          locale: locale,
          symbol: symbol,
          decimalDigits: decimalDigits,
        ),
        _plainFmt = NumberFormat('#,##0.${'0' * decimalDigits}', locale);

  final String symbol;
  final String locale;
  final int decimalDigits;
  final NumberFormat _fmt;

  /// Built once: [formatPlain] runs per list tile and per receipt line.
  final NumberFormat _plainFmt;

  String format(double amount) => _fmt.format(amount);

  /// Format without the currency symbol (e.g. for input fields).
  String formatPlain(double amount) => _plainFmt.format(amount);

  /// Parse a formatted string back to double. Returns null on failure.
  double? tryParse(String input) {
    try {
      return _fmt.parse(input).toDouble();
    } catch (_) {
      return null;
    }
  }
}
