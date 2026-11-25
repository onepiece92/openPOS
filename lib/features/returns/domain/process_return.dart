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
/// The tip stays with the staff on a partial refund unless [refundTip] is
/// set; the refund that completes the full amount always returns whatever
/// tip is still left. The tip returned is written to `returns.tip_amount`
/// and never counts against [amount] or the refundable goods.
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
  bool refundTip = false,
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
    // Tip still with the shop: the order's tip less what earlier refunds
    // returned. Handed back on request, and always by the closing refund.
    final tipLeft = roundMoney(
        order.tipAmount - await db.ordersDao.refundedTipTotal(orderId));
    final refund = roundMoney(amount);
    // A tip-only refund: no goods, just the tip still left.
    final tipOnly = refund == 0 && refundTip && tipLeft > 0;
    if (refundable <= 0 && !tipOnly) {
      throw StateError('Order #$orderId has nothing left to refund');
    }
    if (!tipOnly && !(refund > 0)) {
      throw ArgumentError.value(
          amount, 'amount', 'Refund amount must be greater than zero');
    }
    if (refund > refundable) {
      throw ArgumentError.value(amount, 'amount',
          'Refund amount exceeds the $refundable still refundable');
    }
    // Read inside the transaction: a concurrent void or refund can't
    // restock twice. A tip-only refund never restocks.
    final restocked = restock && !tipOnly
        ? await applyRestock(
            db, order, await readRestockPlan(db, order, trackStock: trackStock),
            reasonCode: 'return', note: 'Refund for Order')
        : RestockResult.nothing;

    final tipBack = tipLeft > 0 && (refundTip || refund >= refundable)
        ? tipLeft
        : 0.0;

    final returnId = await db.ordersDao.insertReturn(
      ReturnsCompanion.insert(
        orderId: orderId,
        amount: refund,
        tipAmount: Value(tipBack),
        restock: Value(restocked.any),
        reason: Value(reason),
      ),
    );

    if (!tipOnly && refund >= refundable) {
      await db.ordersDao.refundOrder(orderId);
      await reverseLoyalty(db, order);
    }

    await audit.orderRefunded(
      orderId,
      amount: refund,
      restocked: restocked.any,
      reason: reason,
    );

    return RefundResult(
        returnId: returnId, restocked: restocked, tipReturned: tipBack);
  });
}

/// The outcome of [processReturn]: the Returns row and the stock it
/// actually put back.
class RefundResult {
  const RefundResult({
    required this.returnId,
    required this.restocked,
    this.tipReturned = 0,
  });
  final int returnId;

  /// The tip handed back with this refund (0 when none).
  final double tipReturned;
  final RestockResult restocked;
}

/// What can still be refunded on [order]: its total less earlier refunds.
Future<double> refundableAmount(AppDatabase db, Order order) async {
  final refunded = await db.ordersDao.refundedTotal(order.id);
  final left = roundMoney(order.total - refunded);
  return left > 0 ? left : 0;
}
