import 'package:drift/drift.dart';

import 'package:pos_app/core/database/tables/products_table.dart';

/// Maps a composite product to its component products with quantities.
/// A composite product's stock is virtual — components are deducted on sale.
class ProductComponents extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The composite (bundle) product that owns this component.
  IntColumn get compositeProductId =>
      integer().references(Products, #id, onDelete: KeyAction.cascade)();

  /// The component product being consumed.
  IntColumn get componentProductId =>
      integer().references(Products, #id, onDelete: KeyAction.restrict)();

  /// How many units of the component are consumed per 1 unit of the composite.
  IntColumn get quantity => integer().withDefault(const Constant(1))();
}
