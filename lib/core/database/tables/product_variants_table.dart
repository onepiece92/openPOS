import 'package:drift/drift.dart';

import 'products_table.dart';

/// Size/colour/type variants for a product.
/// price_delta is added to (or subtracted from) the base product price.
class ProductVariants extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get name => text()(); // e.g. 'Large', 'Red', 'Decaf'
  RealColumn get priceDelta =>
      real().withDefault(const Constant(0.0))();
  IntColumn get stockQuantity =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
