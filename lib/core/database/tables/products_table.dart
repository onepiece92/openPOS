import 'package:drift/drift.dart';

import 'package:pos_app/core/database/tables/categories_table.dart';

/// Core product record.
/// stock_quantity is the single source of truth for available stock.
/// Negative stock is permitted (configurable flag in settings).
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sku => text().unique()();
  TextColumn get name => text()();
  RealColumn get price => real()(); // base price in store currency
  IntColumn get stockQuantity =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isTaxable =>
      boolean().withDefault(const Constant(true))();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  TextColumn get imagePath => text().nullable()(); // local file path
  BoolColumn get isComposite =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isHiddenInPos =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isOutOfStock =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
