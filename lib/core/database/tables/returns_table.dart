import 'package:drift/drift.dart';

import 'package:pos_app/core/database/tables/orders_table.dart';

/// Partial or full refunds linked to the original order.
/// restock = true means inventory is incremented back on the returned items.
// Refunds of one order: refundable amount, net-of-refunds reports.
@TableIndex(name: 'idx_returns_order_id', columns: {#orderId})
// Refunds handed out in a period: the end-of-day drawer close.
@TableIndex(name: 'idx_returns_created_at', columns: {#createdAt})
class Returns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id)();
  /// Amount refunded against the order's `total`. Excludes [tipAmount].
  RealColumn get amount => real()();
  /// Tip handed back by this refund, on top of [amount] (0 when none).
  RealColumn get tipAmount => real().withDefault(const Constant(0.0))();
  BoolColumn get restock =>
      boolean().withDefault(const Constant(false))();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
