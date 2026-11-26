import 'package:drift/drift.dart' show Value;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/core/utils/money.dart';
import 'package:pos_app/features/returns/domain/reverse_sale.dart';

/// Atomically commits a refund against a completed order.
///
/// All DB writes run inside a single transaction — the Returns row, any
/// stock restock with matching audit-log entries, the status flip and
/// loyalty reversal of a full refund, and the audit-log refund entry all
/// persist together or not at all.
///
/// [amount] must be greater than zero and may not take the order's
/// cumulative refunds above its total. A partial refund leaves the order
/// `completed` (reports net the refund off it) and leaves loyalty alone; the
/// refund that brings the cumulative amount up to the total flips the order
/// to `refunded` and reverses its loyalty points.
///
/// `restock = true` returns the whole order's items to inventory — a refund
/// is per order, not per line, so every line counts as refunded whatever
/// the amount. What goes back is decided by [RestockPlan]: a stock-linked
/// order gets exactly what its own adjustment rows still owe (never more,
/// so a sale capped by low stock restores only what it took, and a later
/// refund or void finds nothing left); a CSV import gets nothing; another
/// legacy order gets its lines while [trackStock] is on, once. If nothing is
/// owed by the time the transaction runs (another refund restocked it, say)
/// the refund still goes through, without restocking. The Returns row and
/// the audit entry record whether anything was actually put back, and so
/// does the [RefundResult].
///
/// Throws if the order doesn't exist, is voided, has nothing left to refund,
/// or the amount is invalid. Caller handles UI error display.
Future<RefundResult> processReturn(
  AppDatabase db,
  AuditService audit, {
  required int orderId,
  required double amount,
  required bool restock,
  String? reason,
  required bool trackStock,
}) {
  return db.transaction(() async {
    final order = await db.ordersDao.getById(orderId);
    if (order == null) {
      throw StateError('Order #$orderId not found');
    }
    if (order.status != 'completed' && order.status != 'refunded') {
      throw StateError(
          'Order #$orderId is ${order.status} and cannot be refunded');
    }

    final refundable = await refundableAmount(db, order);
    if (refundable <= 0) {
      throw StateError('Order #$orderId has nothing left to refund');
    }
    final refund = roundMoney(amount);
    if (!(refund > 0)) {
      throw ArgumentError.value(
          amount, 'amount', 'Refund amount must be greater than zero');
    }
    if (refund > refundable) {
      throw ArgumentError.value(amount, 'amount',
          'Refund amount exceeds the $refundable still refundable');
    }
    // Read inside the transaction: a concurrent void or refund can't
    // restock twice.
    final restocked = restock
        ? await applyRestock(
            db, order, await readRestockPlan(db, order, trackStock: trackStock),
            reasonCode: 'return', note: 'Refund for Order')
        : RestockResult.nothing;

    final returnId = await db.ordersDao.insertReturn(
      ReturnsCompanion.insert(
        orderId: orderId,
        amount: refund,
        restock: Value(restocked.any),
        reason: Value(reason),
      ),
    );

    if (refund >= refundable) {
      await db.ordersDao.refundOrder(orderId);
      await reverseLoyalty(db, order);
    }

    await audit.orderRefunded(
      orderId,
      amount: refund,
      restocked: restocked.any,
      reason: reason,
    );

    return RefundResult(returnId: returnId, restocked: restocked);
  });
}

/// The outcome of [processReturn]: the Returns row and the stock it
/// actually put back.
class RefundResult {
  const RefundResult({required this.returnId, required this.restocked});
  final int returnId;
  final RestockResult restocked;
}

/// What can still be refunded on [order]: its total less earlier refunds.
Future<double> refundableAmount(AppDatabase db, Order order) async {
  final refunded = await db.ordersDao.refundedTotal(order.id);
  final left = roundMoney(order.total - refunded);
  return left > 0 ? left : 0;
}
