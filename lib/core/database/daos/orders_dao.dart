import 'package:drift/drift.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/tables/customers_table.dart';
import 'package:pos_app/core/database/tables/order_items_table.dart';
import 'package:pos_app/core/database/tables/order_taxes_table.dart';
import 'package:pos_app/core/database/tables/orders_table.dart';
import 'package:pos_app/core/database/tables/returns_table.dart';

part 'orders_dao.g.dart';

// OrderTaxOverrides table stays in @DriftDatabase for v2 (tax override feature);
// not exposed here because no method on this DAO touches it.
@DriftAccessor(
  tables: [Orders, OrderItems, OrderTaxes, Returns, Customers],
)
class OrdersDao extends DatabaseAccessor<AppDatabase> with _$OrdersDaoMixin {
  OrdersDao(super.db);

  // ── Watch ──────────────────────────────────────────────────────────────

  Stream<List<Order>> watchRecent({int limit = 50}) =>
      (select(orders)
            ..orderBy([(o) => OrderingTerm.desc(o.createdAt)])
            ..limit(limit))
          .watch();

  Stream<List<Order>> watchByCustomer(int customerId) => (select(orders)
        ..where((o) => o.customerId.equals(customerId))
        ..orderBy([(o) => OrderingTerm.desc(o.createdAt)]))
      .watch();

  // ── Read ───────────────────────────────────────────────────────────────

  Future<Order?> getById(int id) =>
      (select(orders)..where((o) => o.id.equals(id))).getSingleOrNull();

  Future<List<OrderItem>> getItems(int orderId) =>
      (select(orderItems)..where((i) => i.orderId.equals(orderId))).get();

  Future<List<OrderTaxe>> getTaxBreakdown(int orderId) =>
      (select(orderTaxes)..where((t) => t.orderId.equals(orderId))).get();

  // ── Write ──────────────────────────────────────────────────────────────

  Future<int> insertOrder(OrdersCompanion entry) =>
      into(orders).insert(entry);

  Future<void> insertItems(List<OrderItemsCompanion> items) =>
      batch((b) => b.insertAll(orderItems, items));

  Future<void> insertTaxLines(List<OrderTaxesCompanion> lines) =>
      batch((b) => b.insertAll(orderTaxes, lines));

  Future<void> voidOrder(int id) async {
    await (update(orders)..where((o) => o.id.equals(id)))
        .write(const OrdersCompanion(status: Value('voided')));
  }

  Future<void> refundOrder(int id) async {
    await (update(orders)..where((o) => o.id.equals(id)))
        .write(const OrdersCompanion(status: Value('refunded')));
  }

  Future<int> insertReturn(ReturnsCompanion entry) =>
      into(returns).insert(entry);

  // ── Aggregates (for reports) ───────────────────────────────────────────

  Future<double> totalRevenueForPeriod(DateTime from, DateTime to) async {
    final result = await customSelect(
      "SELECT COALESCE(SUM(total), 0.0) as revenue FROM orders "
      "WHERE status = 'completed' AND created_at >= ? AND created_at <= ?",
      variables: [Variable(from), Variable(to)],
    ).getSingle();
    return result.read<double>('revenue');
  }

  /// Lightweight projection of completed orders in a period, for chart bucketing.
  Future<List<({DateTime createdAt, double total})>> completedOrdersInPeriod(
      DateTime from, DateTime to) async {
    final rows = await customSelect(
      "SELECT created_at, total FROM orders "
      "WHERE status = 'completed' AND created_at >= ? AND created_at <= ? "
      'ORDER BY created_at ASC',
      variables: [Variable(from), Variable(to)],
      readsFrom: {orders},
    ).get();
    return rows
        .map((r) => (
              createdAt: r.read<DateTime>('created_at'),
              total: r.read<double>('total'),
            ))
        .toList();
  }

  /// Top-selling products by qty for a period. Returns [{name, qty, revenue}].
  Future<List<Map<String, dynamic>>> topSellingProductsForPeriod(
      DateTime from, DateTime to,
      {int limit = 5}) async {
    final rows = await customSelect(
      'SELECT oi.product_name, '
      '  CAST(SUM(oi.quantity) AS INTEGER) as qty, '
      '  SUM(oi.line_total) as revenue '
      'FROM order_items oi '
      'JOIN orders o ON o.id = oi.order_id '
      "WHERE o.status = 'completed' AND o.created_at >= ? AND o.created_at <= ? "
      'GROUP BY oi.product_name '
      'ORDER BY qty DESC '
      'LIMIT ?',
      variables: [Variable(from), Variable(to), Variable(limit)],
      readsFrom: {orderItems, orders},
    ).get();
    return rows
        .map((r) => {
              'name': r.read<String>('product_name'),
              'qty': r.read<int>('qty'),
              'revenue': r.read<double>('revenue'),
            })
        .toList();
  }

  /// Payment method breakdown for a period. Returns [{method, count, total}].
  Future<List<Map<String, dynamic>>> paymentBreakdownForPeriod(
      DateTime from, DateTime to) async {
    final rows = await customSelect(
      'SELECT payment_method, COUNT(*) as count, SUM(total) as total '
      'FROM orders '
      "WHERE status = 'completed' AND created_at >= ? AND created_at <= ? "
      'GROUP BY payment_method',
      variables: [Variable(from), Variable(to)],
      readsFrom: {orders},
    ).get();
    return rows
        .map((r) => {
              'method': r.read<String>('payment_method'),
              'count': r.read<int>('count'),
              'total': r.read<double>('total'),
            })
        .toList();
  }

  /// Streams a map of productId → total units sold across completed orders.
  /// Voided / refunded / held orders are excluded so popularity rankings
  /// reflect realised sales only.
  Stream<Map<int, int>> watchProductSalesCounts() {
    return customSelect(
      'SELECT oi.product_id, CAST(SUM(oi.quantity) AS INTEGER) as total_sold '
      'FROM order_items oi '
      'JOIN orders o ON o.id = oi.order_id '
      "WHERE o.status = 'completed' "
      'GROUP BY oi.product_id',
      readsFrom: {orderItems, orders},
    ).watch().map((rows) => {
          for (final row in rows)
            row.read<int>('product_id'): row.read<int>('total_sold'),
        });
  }

  /// Bulk retrieval for backups.
  Future<List<QueryRow>> getAllOrdersWithItems() async {
    return customSelect(
      'SELECT '
      'o.id as o_id, o.status, o.subtotal as o_subtotal, o.tax_total, o.discount_total as o_discount, o.total as o_total, '
      'o.payment_method, o.tendered_amount, o.change_amount, o.customer_id, o.notes, o.created_at, '
      'oi.id as item_id, oi.product_id, oi.product_name, oi.unit_price, oi.quantity, oi.discount as item_discount, '
      'oi.tax_amount as item_tax, oi.line_total, '
      'c.name as customer_name '
      'FROM orders o '
      'LEFT JOIN order_items oi ON o.id = oi.order_id '
      'LEFT JOIN customers c ON o.customer_id = c.id '
      'ORDER BY o.created_at DESC',
      readsFrom: {orders, orderItems, customers},
    ).get();
  }
}
