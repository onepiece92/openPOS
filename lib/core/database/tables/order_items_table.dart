import 'package:drift/drift.dart';

import 'package:pos_app/core/database/tables/orders_table.dart';
import 'package:pos_app/core/database/tables/products_table.dart';

/// Line items within an order.
/// product_name is a snapshot of the name at time of sale
/// (product may be renamed later; the receipt must remain accurate).
class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()(); // snapshot
  RealColumn get unitPrice => real()(); // snapshot, per unit_label unit
  IntColumn get quantity => integer()();
  /// '' = main unit; else the secondary unit sold (e.g. 'dozen'). Snapshot.
  TextColumn get unitLabel => text().withDefault(const Constant(''))();
  /// Main units per quantity step at sale time (1.0 for the main unit).
  RealColumn get unitsPerQty =>
      real().withDefault(const Constant(1.0))();
  RealColumn get discount =>
      real().withDefault(const Constant(0.0))(); // flat amount off line
  RealColumn get taxAmount =>
      real().withDefault(const Constant(0.0))();
  RealColumn get lineTotal => real()(); // (unitPrice * qty) - discount
}
