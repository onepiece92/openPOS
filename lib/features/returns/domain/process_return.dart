import 'package:drift/drift.dart' show Value;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';

/// Atomically commits a refund against a completed order.
///
/// All DB writes run inside a single transaction — the Returns row, any
/// stock restock with matching audit-log entries, the order status flip,
/// and the audit-log refund entry all persist together or not at all.
///
/// `restock = true` re-adds every line item from the original order back
/// into inventory. Composite products restock their components (mirroring
/// `placeOrder`'s deduction logic). Per-line partial restock is a future
/// extension — Returns schema only tracks per-order amount today.
///
/// Throws if the order doesn't exist. Caller handles UI error display.
Future<int> processReturn(
  AppDatabase db,
  AuditService audit, {
  required int orderId,
  required double amount,
  required bool restock,
  String? reason,
}) {
  return db.transaction(() async {
    final order = await db.ordersDao.getById(orderId);
    if (order == null) {
      throw StateError('Order #$orderId not found');
    }

    final returnId = await db.ordersDao.insertReturn(
      ReturnsCompanion.insert(
        orderId: orderId,
        amount: amount,
        restock: Value(restock),
        reason: Value(reason),
      ),
    );

    if (restock) {
      final items = await db.ordersDao.getItems(orderId);
      for (final item in items) {
        final product = await db.productsDao.getById(item.productId);
        if (product != null && product.isComposite) {
          final components = await db.productsDao.getComponents(item.productId);
          for (final comp in components) {
            final addBack = comp.quantity * item.quantity;
            await db.productsDao.adjustStock(comp.componentProductId, addBack);
            await db.inventoryDao.logAdjustment(
              StockAdjustmentsCompanion.insert(
                productId: comp.componentProductId,
                delta: addBack,
                reasonCode: 'return',
                notes: Value('Refund for Order #$orderId (via ${item.productName})'),
              ),
            );
          }
        } else {
          await db.productsDao.adjustStock(item.productId, item.quantity);
          await db.inventoryDao.logAdjustment(
            StockAdjustmentsCompanion.insert(
              productId: item.productId,
              delta: item.quantity,
              reasonCode: 'return',
              notes: Value('Refund for Order #$orderId'),
            ),
          );
        }
      }
    }

    await db.ordersDao.refundOrder(orderId);

    await audit.orderRefunded(
      orderId,
      amount: amount,
      restocked: restock,
      reason: reason,
    );

    return returnId;
  });
}
