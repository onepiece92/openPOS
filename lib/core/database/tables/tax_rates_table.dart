import 'package:drift/drift.dart';

/// Stores named tax rates (e.g. GST 10%, VAT 15%).
/// inclusion_type: 'inclusive' = tax embedded in price | 'exclusive' = added on top.
/// rounding_mode: 'half_up' | 'half_even' | 'truncate' — applied per line or per order.
class TaxRates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get rate => real()(); // e.g. 0.10 for 10%
  TextColumn get inclusionType =>
      text().withDefault(const Constant('exclusive'))();
  TextColumn get roundingMode =>
      text().withDefault(const Constant('half_up'))();
  BoolColumn get isCompound =>
      boolean().withDefault(const Constant(false))(); // tax-on-tax
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
