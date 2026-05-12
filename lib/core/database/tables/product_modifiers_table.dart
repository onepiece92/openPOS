import 'package:drift/drift.dart';

import 'package:pos_app/core/database/tables/products_table.dart';

/// Optional add-ons for a product (e.g. burger toppings, coffee shots).
/// is_required = true means the cashier must pick at least one before adding to cart.
class ProductModifiers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get name => text()(); // e.g. 'Extra Cheese', 'Oat Milk'
  RealColumn get priceDelta =>
      real().withDefault(const Constant(0.0))();
  BoolColumn get isRequired =>
      boolean().withDefault(const Constant(false))();
}
