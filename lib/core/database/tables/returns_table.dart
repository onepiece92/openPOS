import 'package:drift/drift.dart';

import 'orders_table.dart';

/// Partial or full refunds linked to the original order.
/// restock = true means inventory is incremented back on the returned items.
class Returns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id)();
  RealColumn get amount => real()(); // amount refunded
  BoolColumn get restock =>
      boolean().withDefault(const Constant(false))();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
