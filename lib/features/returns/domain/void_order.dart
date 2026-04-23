import 'package:drift/drift.dart' show Value;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';

/// Atomically voids a previously-completed order.
///
/// Reverses every stock deduction made by `placeOrder` (composite-aware),
/// flips the order status to `'voided'`, and writes one audit-log entry.
/// All inside a single transaction.
///
/// No manager PIN gate yet — the UI uses a typed-VOID confirmation
/// for now. PIN enforcement is a Phase 7 security pass.
///
/// Throws if the order doesn't exist or is already voided.
Future<void> voidOrder(
  AppDatabase db,
  AuditService audit, {
  required int orderId,
  required String reason,
}) {
  return db.transaction(() async {
    final order = await db.ordersDao.getById(orderId);
    if (order == null) {
      throw StateError('Order #$orderId not found');
    }
    if (order.status == 'voided') {
      throw StateError('Order #$orderId is already voided');
    }

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
              reasonCode: 'void',
              notes: Value('Void Order #$orderId (via ${item.productName})'),
            ),
          );
        }
      } else {
        await db.productsDao.adjustStock(item.productId, item.quantity);
        await db.inventoryDao.logAdjustment(
          StockAdjustmentsCompanion.insert(
            productId: item.productId,
            delta: item.quantity,
            reasonCode: 'void',
            notes: Value('Void Order #$orderId'),
          ),
        );
      }
    }

    await db.ordersDao.voidOrder(orderId);

    await audit.orderVoided(orderId, reason: reason);
  });
}
