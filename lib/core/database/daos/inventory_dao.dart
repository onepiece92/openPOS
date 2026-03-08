import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/products_table.dart';
import '../tables/stock_adjustments_table.dart';

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

  Future<int> logAdjustment(StockAdjustmentsCompanion entry) =>
      into(stockAdjustments).insert(entry);
}
