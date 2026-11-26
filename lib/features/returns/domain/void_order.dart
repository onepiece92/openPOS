import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/returns/domain/reverse_sale.dart';

/// Atomically voids a previously-completed order.
///
/// Reverses every stock deduction made by `placeOrder` (composite- and
/// unit-aware), reverses the order's loyalty points, flips the order status
/// to `'voided'`, and writes one audit-log entry. All inside a single
/// transaction.
///
/// No manager PIN gate yet — the UI uses a typed-VOID confirmation
/// for now. PIN enforcement is a Phase 7 security pass.
///
/// [trackStock] false (Stock tracking switched off): nothing is restocked.
///
/// Throws if the order doesn't exist or is not `completed` (already voided,
/// fully refunded, or still held).
Future<void> voidOrder(
  AppDatabase db,
  AuditService audit, {
  required int orderId,
  required String reason,
  bool trackStock = true,
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

    // INTERIM rule: restock only while Stock tracking is on NOW. A sale made
    // while it was off deducted nothing, so putting it back would invent
    // stock. TODO(schema v16): stock_adjustments gets an order_id; then
    // restock exactly what THIS sale's own 'sale' rows deducted, whatever
    // the switch says now (sold on / refunded off, and the reverse).
    // A partial refund may already have put the items back on the shelf.
    if (trackStock && !await db.ordersDao.hasRestockedReturn(orderId)) {
      await restockOrderItems(db, order,
          reasonCode: 'void', note: 'Void Order');
    }
    await reverseLoyalty(db, order);

    await db.ordersDao.voidOrder(orderId);

    await audit.orderVoided(orderId, reason: reason);
  });
}
