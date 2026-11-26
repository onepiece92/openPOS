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
/// `restock = true` re-adds every line item from the original order back
/// into inventory, once per order. Composite products restock their
/// components (mirroring `placeOrder`'s deduction logic). Per-line partial
/// restock is a future extension — Returns schema only tracks per-order
/// amount today.
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
  bool trackStock = true,
}) {
  // INTERIM rule: restock only while Stock tracking is on NOW. A sale made
  // while it was off deducted nothing, so putting it back would invent
  // stock. TODO(schema v16): stock_adjustments gets an order_id; then
  // restock exactly what THIS sale's own 'sale' rows deducted, whatever
  // the switch says now (sold on / refunded off, and the reverse).
  restock = restock && trackStock;
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
    if (restock && await db.ordersDao.hasRestockedReturn(orderId)) {
      throw StateError(
          'Order #$orderId was already restocked by an earlier refund');
    }

    final returnId = await db.ordersDao.insertReturn(
      ReturnsCompanion.insert(
        orderId: orderId,
        amount: refund,
        restock: Value(restock),
        reason: Value(reason),
      ),
    );

    if (restock) {
      await restockOrderItems(db, order,
          reasonCode: 'return', note: 'Refund for Order');
    }

    if (refund >= refundable) {
      await db.ordersDao.refundOrder(orderId);
      await reverseLoyalty(db, order);
    }

    await audit.orderRefunded(
      orderId,
      amount: refund,
      restocked: restock,
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
