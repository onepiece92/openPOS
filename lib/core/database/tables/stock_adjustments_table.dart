import 'package:drift/drift.dart';

import 'package:pos_app/core/database/tables/orders_table.dart';
import 'package:pos_app/core/database/tables/products_table.dart';

/// Manual stock adjustment log.
/// delta > 0 = stock added, delta < 0 = stock removed.
///
/// reason_code: 'damage' | 'shrink' | 'count' | 'receive' | 'return' | 'other'
// One product's adjustment history, newest first.
@TableIndex(
    name: 'idx_stock_adjustments_product_created',
    columns: {#productId, #createdAt})
// An order's stock movements (sale, void, refund restock). Partial: manual
// adjustments (order_id NULL) never write to it.
@TableIndex.sql('CREATE INDEX idx_stock_adjustments_order_id '
    'ON stock_adjustments (order_id) WHERE order_id IS NOT NULL')
class StockAdjustments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get delta => integer()();
  TextColumn get reasonCode => text()();
  TextColumn get notes => text().nullable()();
  /// The order that moved this stock: its sale deduction, or its void /
  /// refund restock. NULL for manual adjustments and for rows written
  /// before schema v16.
  IntColumn get orderId => integer().nullable().references(Orders, #id)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
