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
/// legacy order gets its lines while [trackStock] is on. Only one refund per
/// order may restock.
/// The Returns row records whether anything was to be restocked.
///
/// Throws if the order doesn't exist, is voided, has nothing left to refund,
/// or the amount is invalid. Caller handles UI error display.
Future<int> processReturn(
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
    // One restocking refund per order, as before.
    if (restock && await db.ordersDao.hasRestockedReturn(orderId)) {
      throw StateError(
          'Order #$orderId was already restocked by an earlier refund');
    }
    // Read inside the transaction: a concurrent void can't restock twice.
    final plan = restock
        ? await readRestockPlan(db, order, trackStock: trackStock)
        : RestockPlan.none;
    final restocking = plan.any;

    final returnId = await db.ordersDao.insertReturn(
      ReturnsCompanion.insert(
        orderId: orderId,
        amount: refund,
        restock: Value(restocking),
        reason: Value(reason),
      ),
    );

    await applyRestock(db, order, plan,
        reasonCode: 'return', note: 'Refund for Order');

    if (refund >= refundable) {
      await db.ordersDao.refundOrder(orderId);
      await reverseLoyalty(db, order);
    }

    await audit.orderRefunded(
      orderId,
      amount: refund,
      restocked: restocking,
      reason: reason,
    );

    return returnId;
  });
}

/// What can still be refunded on [order]: its total less earlier refunds.
Future<double> refundableAmount(AppDatabase db, Order order) async {
  final refunded = await db.ordersDao.refundedTotal(order.id);
  final left = roundMoney(order.total - refunded);
  return left > 0 ? left : 0;
}
