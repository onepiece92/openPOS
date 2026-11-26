import 'package:drift/drift.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/tables/products_table.dart';
import 'package:pos_app/core/database/tables/stock_adjustments_table.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(tables: [Products, StockAdjustments])
class InventoryDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryDaoMixin {
  InventoryDao(super.db);

  /// Watch all products with stock at or below their threshold.
  /// Threshold is currently a store-wide setting read from Hive (not per-product).
  Stream<List<Product>> watchLowStock(int threshold) => (select(products)
        ..where(
          (p) => p.stockQuantity.isSmallerOrEqualValue(threshold) &
              p.isActive.equals(true),
        ))
      .watch();

  Future<List<StockAdjustment>> getAdjustmentsForProduct(int productId) =>
      (select(stockAdjustments)
            ..where((s) => s.productId.equals(productId))
            ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
          .get();

  /// Every stock movement an order caused (sale deductions, void / refund
  /// restocks), oldest first — via idx_stock_adjustments_order_id.
  Future<List<StockAdjustment>> getAdjustmentsForOrder(int orderId) =>
      (select(stockAdjustments)
            ..where((s) => s.orderId.equals(orderId))
            ..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .get();

  Future<int> logAdjustment(StockAdjustmentsCompanion entry) =>
      into(stockAdjustments).insert(entry);
}
