import 'package:drift/drift.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/tables/customers_table.dart';
import 'package:pos_app/core/database/tables/order_items_table.dart';
import 'package:pos_app/core/database/tables/order_taxes_table.dart';
import 'package:pos_app/core/database/tables/orders_table.dart';
import 'package:pos_app/core/database/tables/products_table.dart';
import 'package:pos_app/core/database/tables/returns_table.dart';

part 'orders_dao.g.dart';

// OrderTaxOverrides table stays in @DriftDatabase for v2 (tax override feature);
// not exposed here because no method on this DAO touches it.
@DriftAccessor(
  tables: [Orders, OrderItems, OrderTaxes, Returns, Customers, Products],
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

  Future<void> voidOrder(int id) => _setStatus(id, 'voided');

  Future<void> refundOrder(int id) => _setStatus(id, 'refunded');

  Future<void> _setStatus(int id, String status) =>
      (update(orders)..where((o) => o.id.equals(id))).write(
        OrdersCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<int> insertReturn(ReturnsCompanion entry) =>
      into(returns).insert(entry);

  /// Next gap-free invoice number within [prefix] (e.g. fiscal year
  /// '2082/83'; '' = no prefix). Call inside the placing transaction.
  Future<int> nextInvoiceNo({String prefix = ''}) async {
    final row = await customSelect(
      'SELECT COALESCE(MAX(invoice_no), 0) + 1 AS n FROM orders '
      'WHERE invoice_prefix = ?',
      variables: [Variable(prefix)],
      readsFrom: {orders},
    ).getSingle();
    return row.read<int>('n');
  }

  /// Records one physical receipt print. Returns the count *before* this
  /// print — 0 means the copy just produced was the original.
  Future<int> incrementPrintCount(int id) => transaction(() async {
        final row = await getById(id);
        final before = row?.printCount ?? 0;
        await (update(orders)..where((o) => o.id.equals(id)))
            .write(OrdersCompanion(printCount: Value(before + 1)));
        return before;
      });

  // ── Refunds ────────────────────────────────────────────────────────────

  /// Everything refunded against [orderId] so far.
  Future<double> refundedTotal(int orderId) async {
    final row = await customSelect(
      'SELECT COALESCE(SUM(amount), 0.0) AS refunded FROM returns '
      'WHERE order_id = ?',
      variables: [Variable(orderId)],
      readsFrom: {returns},
    ).getSingle();
    return row.read<double>('refunded');
  }

  /// True once any refund against [orderId] has put its items back in stock.
  Future<bool> hasRestockedReturn(int orderId) async {
    final row = await (select(returns)
          ..where((r) => r.orderId.equals(orderId) & r.restock.equals(true))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// orderId → total refunded, for every order that has a refund.
  Stream<Map<int, double>> watchRefundedTotals() => customSelect(
        'SELECT order_id, SUM(amount) AS refunded FROM returns '
        'GROUP BY order_id',
        readsFrom: {returns},
      ).watch().map((rows) => {
            for (final row in rows)
              row.read<int>('order_id'): row.read<double>('refunded'),
          });

  // ── Aggregates (for reports) ───────────────────────────────────────────

  /// Orders that still carry revenue, each with `net` = total − refunds and
  /// `kept` = the share of the sale that was not refunded (net ÷ total).
  ///
  /// A refund is netted against the original sale (so it lands on the sale's
  /// date and payment method). Partly refunded orders stay `completed`; a
  /// `refunded` order is fully refunded and carries nothing. The second
  /// branch only matters for rows written before partial refunds existed,
  /// when every refund flipped the status: those count for what was kept.
  ///
  /// Refunds are recorded per order, not per line, so a partial refund is
  /// treated as handing back that share of the whole sale: every figure
  /// derived from the order — revenue, VAT, cost of goods, each product's
  /// sales — is multiplied by `kept`. Voided orders are not in here at all.
  static const _netOrders =
      '(SELECT n.*, '
      '  CASE WHEN n.total > 0 THEN n.net / n.total ELSE 1.0 END AS kept '
      'FROM (SELECT o.id, o.created_at, o.payment_method, o.total, '
      '    o.subtotal, o.discount_total, o.loyalty_discount, o.tax_total, '
      '    ROUND(MAX(0.0, o.total - COALESCE(r.refunded, 0.0)), 2) AS net '
      '  FROM orders o '
      '  LEFT JOIN (SELECT order_id, SUM(amount) AS refunded '
      '    FROM returns GROUP BY order_id) r ON r.order_id = o.id '
      "  WHERE o.status = 'completed' "
      "    OR (o.status = 'refunded' AND r.refunded IS NOT NULL "
      '      AND r.refunded < o.total - 0.005)) n)';

  /// Revenue for a period, net of refunds.
  Future<double> totalRevenueForPeriod(DateTime from, DateTime to) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(net), 0.0) as revenue FROM $_netOrders '
      'WHERE created_at >= ? AND created_at <= ?',
      variables: [Variable(from), Variable(to)],
      readsFrom: {orders, returns},
    ).getSingle();
    return result.read<double>('revenue');
  }

  /// Lightweight projection of revenue-carrying orders in a period, for
  /// chart bucketing. `total` is net of refunds.
  Future<List<({DateTime createdAt, double total})>> completedOrdersInPeriod(
      DateTime from, DateTime to) async {
    final rows = await customSelect(
      'SELECT created_at, net FROM $_netOrders '
      'WHERE created_at >= ? AND created_at <= ? '
      'ORDER BY created_at ASC',
      variables: [Variable(from), Variable(to)],
      readsFrom: {orders, returns},
    ).get();
    return rows
        .map((r) => (
              createdAt: r.read<DateTime>('created_at'),
              total: r.read<double>('net'),
            ))
        .toList();
  }

  /// VAT inside the period's revenue: each order's tax (inclusive and
  /// exclusive alike), scaled by the share of the sale that was kept.
  Future<double> vatCollectedForPeriod(DateTime from, DateTime to) async {
    final row = await customSelect(
      'SELECT COALESCE(SUM(ROUND(tax_total * kept, 2)), 0.0) AS vat '
      'FROM $_netOrders WHERE created_at >= ? AND created_at <= ?',
      variables: [Variable(from), Variable(to)],
      readsFrom: {orders, returns},
    ).getSingle();
    return _round2(row.read<double>('vat'));
  }

  /// What the goods sold in the period cost the shop, from the per-line
  /// `unit_cost` snapshot (quantity × units_per_qty × unit_cost, scaled by
  /// the share of the sale kept). Lines with no cost recorded count as zero;
  /// `uncostedLines` says how many of the `lines` sold that is, so the
  /// caller can show that the figure is incomplete.
  Future<({double cost, int lines, int uncostedLines})> costOfGoodsForPeriod(
      DateTime from, DateTime to) async {
    final row = await customSelect(
      'SELECT '
      '  COALESCE(SUM(n.kept * oi.quantity * oi.units_per_qty * '
      '    COALESCE(oi.unit_cost, 0.0)), 0.0) AS cost, '
      '  COUNT(oi.id) AS lines, '
      '  COALESCE(SUM(oi.unit_cost IS NULL), 0) AS uncosted '
      'FROM order_items oi '
      'JOIN $_netOrders n ON n.id = oi.order_id '
      'WHERE n.created_at >= ? AND n.created_at <= ?',
      variables: [Variable(from), Variable(to)],
      readsFrom: {orderItems, orders, returns},
    ).getSingle();
    return (
      cost: _round2(row.read<double>('cost')),
      lines: row.read<int>('lines'),
      uncostedLines: row.read<int>('uncosted'),
    );
  }

  /// Top-selling products for a period, one row per product (not per name:
  /// a rename or a secondary-unit sale — "Eggs (dozen)" — is still Eggs),
  /// shown under the product's current name.
  ///
  /// `qty` is in the product's main unit (2 dozen = 24). On a partly
  /// refunded order the units still count in full — refunds do not say
  /// which lines came back — while the money is scaled like everything else.
  ///
  /// `sales` is the product's share of sales excluding VAT: its line totals
  /// after their share of the order discount and of any points redeemed,
  /// less the VAT that was inside the prices (inclusive tax), times the
  /// share of the sale kept after refunds. Summed over every product it
  /// equals the dashboard's sales ex-VAT (revenue − VAT collected).
  Future<List<({int productId, String name, int qty, double sales})>>
      topSellingProductsForPeriod(DateTime from, DateTime to,
          {int limit = 5}) async {
    final rows = await customSelect(
      'SELECT oi.product_id, '
      '  COALESCE(p.name, MAX(oi.product_name)) AS name, '
      '  SUM(oi.quantity * oi.units_per_qty) AS qty, '
      '  SUM(n.kept * ('
      '    CASE WHEN n.subtotal > 0 THEN oi.line_total / n.subtotal * '
      '      (n.subtotal - n.discount_total - n.loyalty_discount) '
      '    ELSE 0.0 END '
      // The line's share of the VAT that sat inside the prices. Lines sold
      // before v14 stored no tax share, so those fall back to the line's
      // share of the order.
      '    - COALESCE(it.inclusive, 0.0) * '
      '      CASE WHEN ls.item_tax > 0 THEN oi.tax_amount / ls.item_tax '
      '        WHEN n.subtotal > 0 THEN oi.line_total / n.subtotal '
      '        ELSE 0.0 END)) AS sales '
      'FROM order_items oi '
      'JOIN $_netOrders n ON n.id = oi.order_id '
      'LEFT JOIN products p ON p.id = oi.product_id '
      'LEFT JOIN (SELECT order_id, SUM(tax_amount) AS inclusive '
      '  FROM order_taxes WHERE is_inclusive = 1 GROUP BY order_id) it '
      '  ON it.order_id = n.id '
      'LEFT JOIN (SELECT order_id, SUM(tax_amount) AS item_tax '
      '  FROM order_items GROUP BY order_id) ls ON ls.order_id = n.id '
      'WHERE n.created_at >= ? AND n.created_at <= ? '
      'GROUP BY oi.product_id '
      'ORDER BY qty DESC, sales DESC, oi.product_id '
      'LIMIT ?',
      variables: [Variable(from), Variable(to), Variable(limit)],
      readsFrom: {orderItems, orders, returns, orderTaxes, products},
    ).get();
    return [
      for (final r in rows)
        (
          productId: r.read<int>('product_id'),
          name: r.read<String>('name'),
          qty: r.read<double>('qty').round(),
          sales: _round2(r.read<double>('sales')),
        ),
    ];
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100;

  /// Payment method breakdown for a period, net of refunds.
  /// Returns [{method, count, total}].
  Future<List<Map<String, dynamic>>> paymentBreakdownForPeriod(
      DateTime from, DateTime to) async {
    final rows = await customSelect(
      'SELECT payment_method, COUNT(*) as count, SUM(net) as total '
      'FROM $_netOrders '
      'WHERE created_at >= ? AND created_at <= ? '
      'GROUP BY payment_method',
      variables: [Variable(from), Variable(to)],
      readsFrom: {orders, returns},
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
