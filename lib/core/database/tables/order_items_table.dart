import 'package:drift/drift.dart';

import 'package:pos_app/core/database/tables/orders_table.dart';
import 'package:pos_app/core/database/tables/product_variants_table.dart';
import 'package:pos_app/core/database/tables/products_table.dart';

/// Line items within an order.
/// product_name is a snapshot of the name at time of sale
/// (product may be renamed later; the receipt must remain accurate).
class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get variantId =>
      integer().nullable().references(ProductVariants, #id)();
  TextColumn get productName => text()(); // snapshot
  RealColumn get unitPrice => real()(); // snapshot
  IntColumn get quantity => integer()();
  RealColumn get discount =>
      real().withDefault(const Constant(0.0))(); // flat amount off line
  RealColumn get taxAmount =>
      real().withDefault(const Constant(0.0))();
  RealColumn get lineTotal => real()(); // (unitPrice * qty) - discount
}
