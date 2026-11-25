/// Rules for a product's secondary-unit conversion ("1 dozen = 12 pcs").
///
/// Stock is counted in whole main units, so the conversion has to be a
/// whole number — half a piece cannot be taken off the shelf count — and
/// at least [kMinConversionRate]: 1 would be the main unit under another
/// name.
library;

const int kMinConversionRate = 2;

/// Far beyond any real pack size; keeps quantity × conversion well inside
/// what stock arithmetic can hold.
const int kMaxConversionRate = 1000000;

/// True when [rate] is a usable conversion. Products saved before this rule
/// may hold a fractional rate (or 1); they keep working, and the product
/// form asks for a valid one the next time they are edited.
bool isValidConversionRate(double rate) =>
    rate.isFinite &&
    rate == rate.roundToDouble() &&
    rate >= kMinConversionRate &&
    rate <= kMaxConversionRate;

/// The conversion typed in [raw], or null when it is not valid.
int? parseConversionRate(String? raw) {
  final value = double.tryParse(raw?.trim() ?? '');
  if (value == null || !isValidConversionRate(value)) return null;
  return value.toInt();
}

/// Form validator for the conversion field (used only when the product has
/// a secondary unit).
String? validateConversionRate(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return 'Required';
  final value = double.tryParse(text);
  if (value == null || !value.isFinite) return 'Enter a number';
  if (value != value.roundToDouble()) return 'Whole number only';
  if (value < kMinConversionRate) return 'Must be $kMinConversionRate or more';
  if (value > kMaxConversionRate) return 'Too large';
  return null;
}
