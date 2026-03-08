import 'package:drift/drift.dart';

import 'orders_table.dart';

/// Records when a manager manually overrides the computed tax on an order.
/// Every row here must also have a corresponding audit_log entry.
/// Requires manager PIN verification before being written.
class OrderTaxOverrides extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId =>
      integer().unique().references(Orders, #id)(); // one override per order
  RealColumn get originalTax => real()();
  RealColumn get overrideTax => real()();
  TextColumn get reason => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
