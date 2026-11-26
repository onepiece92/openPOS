import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/returns/domain/reverse_sale.dart';

/// Atomically voids a previously-completed order.
///
/// Puts back what the sale still owes the shelf (see [RestockPlan]: a
/// stock-linked order from its own adjustment rows, a CSV import nothing,
/// another legacy order its lines while [trackStock] is on), reverses the order's loyalty points, flips the order status
/// to `'voided'`, and writes one audit-log entry. All inside a single
/// transaction.
///
/// No manager PIN gate yet — the UI uses a typed-VOID confirmation
/// for now. PIN enforcement is a Phase 7 security pass.
///
/// Throws if the order doesn't exist or is not `completed` (already voided,
/// fully refunded, or still held).
Future<void> voidOrder(
  AppDatabase db,
  AuditService audit, {
  required int orderId,
  required String reason,
  required bool trackStock,
}) {
  return db.transaction(() async {
    final order = await db.ordersDao.getById(orderId);
    if (order == null) {
      throw StateError('Order #$orderId not found');
    }
    if (order.status != 'completed') {
      throw StateError(
          'Order #$orderId is already ${order.status} and cannot be voided');
    }

    // Read inside the transaction: a concurrent refund can't restock twice.
    final plan = await readRestockPlan(db, order, trackStock: trackStock);
    await applyRestock(db, order, plan, reasonCode: 'void', note: 'Void Order');
    await reverseLoyalty(db, order);

    await db.ordersDao.voidOrder(orderId);

    await audit.orderVoided(orderId, reason: reason);
  });
}
