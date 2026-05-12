import 'package:drift/drift.dart';

import 'package:pos_app/core/database/tables/products_table.dart';

/// Manual stock adjustment log.
/// delta > 0 = stock added, delta < 0 = stock removed.
///
/// reason_code: 'damage' | 'shrink' | 'count' | 'receive' | 'return' | 'other'
class StockAdjustments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get delta => integer()();
  TextColumn get reasonCode => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
