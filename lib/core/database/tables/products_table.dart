import 'package:drift/drift.dart';

import 'package:pos_app/core/database/tables/categories_table.dart';

/// Core product record.
/// stock_quantity is the single source of truth for available stock.
/// Negative stock is permitted (configurable flag in settings).
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sku => text().unique()();
  TextColumn get name => text()();
  RealColumn get price => real()(); // base selling price in store currency
  RealColumn get purchasePrice =>
      real().withDefault(const Constant(0.0))(); // cost price per main unit
  /// Main unit stock & price are expressed in (e.g. 'pcs', 'kg', 'ltr').
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  /// Optional larger unit (e.g. 'box', 'dozen'). Null = no secondary unit.
  TextColumn get secondaryUnit => text().nullable()();
  /// How many main units make up one secondary unit (1 box = N pcs).
  RealColumn get conversionRate =>
      real().withDefault(const Constant(1.0))();
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
