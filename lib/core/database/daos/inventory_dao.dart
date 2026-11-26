import 'package:drift/drift.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/tables/orders_table.dart';
import 'package:pos_app/core/database/tables/products_table.dart';
import 'package:pos_app/core/database/tables/stock_adjustments_table.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(tables: [Products, StockAdjustments, Orders])
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

  /// What putting [orderId]'s stock back would restore, read from its own
  /// adjustment rows: productId → net units (−Σ delta over the order's
  /// sale deductions and any restocks already done), only where that is
  /// positive. Bundles appear as their component rows — exactly what was
  /// taken, never recomputed from today's recipe. An empty map means
  /// nothing is owed (nothing was deducted, or it was all put back).
  ///
  /// Returns null for a legacy order (`stock_linked` NULL): its rows can't
  /// be trusted to be complete, so the caller keeps restocking by lines.
  /// Throws [StateError] if the order does not exist.
  ///
  /// Not wired into void/refund yet. One primary-key read plus a seek on
  /// idx_stock_adjustments_order_id.
  Future<Map<int, int>?> stockToRestock(int orderId) async {
    final order = await (select(orders)..where((o) => o.id.equals(orderId)))
        .getSingleOrNull();
    if (order == null) throw StateError('Order #$orderId not found');
    if (order.stockLinked == null) return null;
    final rows = await customSelect(
      'SELECT product_id, -SUM(delta) AS qty FROM stock_adjustments '
      'WHERE order_id = ? GROUP BY product_id HAVING qty > 0 '
      'ORDER BY product_id',
      variables: [Variable(orderId)],
      readsFrom: {stockAdjustments},
    ).get();
    return {
      for (final r in rows) r.read<int>('product_id'): r.read<int>('qty'),
    };
  }

  Future<int> logAdjustment(StockAdjustmentsCompanion entry) =>
      into(stockAdjustments).insert(entry);
}
