import 'package:drift/drift.dart';

/// Named bundles of multiple tax rates applied together at checkout.
/// e.g. 'Restaurant Tax' = GST + Service Charge.
class TaxGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
