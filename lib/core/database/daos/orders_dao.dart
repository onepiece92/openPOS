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

  /// One page of order history, newest first, optionally narrowed by a
  /// search. Pages are keyed on (created_at, id) — pass the last order of
  /// the previous page as [before] — so any order, however old, is reachable
  /// and a sale landing meanwhile cannot shift or repeat rows.
  ///
  /// [search] matches, all through indexes:
  ///  * a bill number as printed — `17`, `#17`, or `2082/83-17` with its
  ///    prefix (rows from before invoice numbers existed match on their id);
  ///  * an invoice prefix on its own (`2082/83`): every bill under it;
  ///  * part of a customer's name, any case.
  /// A search with a decimal point (`1250.50`) is read as an amount and
  /// matches the order total instead; that one reads the whole table.
  Future<List<Order>> historyPage({
    String search = '',
    Order? before,
    int limit = 50,
  }) async {
    final where = <String>[];
    final vars = <Variable>[];
    final q = search.trim();
    if (q.isNotEmpty) {
      final bare = q.startsWith('#') ? q.substring(1).trim() : q;
      final amount = bare.contains('.') ? double.tryParse(bare) : null;
      if (amount != null) {
        where.add('(o.total >= ? AND o.total < ?)');
        vars
          ..add(Variable(amount - 0.005))
          ..add(Variable(amount + 0.005));
      } else {
        final terms = <String>[];
        final number = int.tryParse(bare);
        if (number != null) {
          // The unique index leads with the prefix, so hand it the (few)
          // prefixes in use instead of letting it walk every bill.
          terms
            ..add('(o.invoice_no = ? AND o.invoice_prefix IN '
                '(SELECT DISTINCT invoice_prefix FROM orders))')
            ..add('(o.id = ? AND o.invoice_no IS NULL)');
          vars
            ..add(Variable(number))
            ..add(Variable(number));
        }
        final dash = bare.lastIndexOf('-');
        final prefixed =
            dash > 0 ? int.tryParse(bare.substring(dash + 1).trim()) : null;
        if (prefixed != null) {
          terms.add('(o.invoice_prefix = ? AND o.invoice_no = ?)');
          vars
            ..add(Variable(bare.substring(0, dash).trim()))
            ..add(Variable(prefixed));
        }
        // '' is every un-prefixed bill, so only a real prefix counts.
        terms.add("(o.invoice_prefix = ? AND o.invoice_prefix != '')");
        vars.add(Variable(q));
        terms.add('o.customer_id IN '
            "(SELECT id FROM customers WHERE name LIKE ? ESCAPE '\\')");
        vars.add(Variable('%${_escapeLike(q)}%'));
        where.add('(${terms.join(' OR ')})');
      }
    }
    if (before != null) {
      where.add('(o.created_at, o.id) < (?, ?)');
      vars
        ..add(Variable(before.createdAt))
        ..add(Variable(before.id));
    }
    final rows = await customSelect(
      'SELECT o.* FROM orders o '
      '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')} '}'
      'ORDER BY o.created_at DESC, o.id DESC LIMIT ?',
      variables: [...vars, Variable(limit)],
      readsFrom: {orders, customers},
    ).get();
    return [for (final r in rows) orders.map(r.data)];
  }

  static String _escapeLike(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  /// How many orders (of any status) were rung up in the period — the
  /// history screen's "Today's orders".
  Future<int> orderCountForPeriod(DateTime from, DateTime to) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM orders '
      'WHERE created_at >= ? AND created_at <= ?',
      variables: [Variable(from), Variable(to)],
      readsFrom: {orders},
    ).getSingle();
    return row.read<int>('c');
  }

  /// How many orders have status 'completed', counting no further than
  /// [upTo] — the review reminder only needs to know whether a threshold
  /// has been reached. Partly refunded orders (still 'completed') and
  /// imported ones count; held, voided and fully refunded ones do not.
  ///
  /// No index covers `status`; the LIMIT is what keeps this cheap: SQLite
  /// walks the table in rowid order and stops at the [upTo]-th match, so
  /// once a shop has that many sales it reads about [upTo] rows however
  /// long the history is.
  Future<int> completedOrderCount({required int upTo}) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM '
      "(SELECT 1 FROM orders WHERE status = 'completed' LIMIT ?)",
      variables: [Variable(upTo)],
      readsFrom: {orders},
    ).getSingle();
    return row.read<int>('c');
  }

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
      // Both per-order sums are limited to the period's orders, so a
      // one-day report does not total every tax line and order line ever
      // written before joining to a handful of orders.
      'LEFT JOIN (SELECT t.order_id, SUM(t.tax_amount) AS inclusive '
      '  FROM order_taxes t JOIN orders po ON po.id = t.order_id '
      '  WHERE t.is_inclusive = 1 '
      '    AND po.created_at >= ?1 AND po.created_at <= ?2 '
      '  GROUP BY t.order_id) it ON it.order_id = n.id '
      'LEFT JOIN (SELECT i.order_id, SUM(i.tax_amount) AS item_tax '
      '  FROM order_items i JOIN orders po ON po.id = i.order_id '
      '  WHERE po.created_at >= ?1 AND po.created_at <= ?2 '
      '  GROUP BY i.order_id) ls ON ls.order_id = n.id '
      'WHERE n.created_at >= ?1 AND n.created_at <= ?2 '
      'GROUP BY oi.product_id '
      'ORDER BY qty DESC, sales DESC, oi.product_id '
      'LIMIT ?3',
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

  /// The distinct tax names charged on revenue-carrying orders in the
  /// period (at most [limit] — callers only need "none, one or several").
  Future<List<String>> taxNamesForPeriod(DateTime from, DateTime to,
      {int limit = 2}) async {
    final rows = await customSelect(
      'SELECT DISTINCT TRIM(t.tax_rate_name) AS name '
      'FROM orders o JOIN order_taxes t ON t.order_id = o.id '
      'WHERE o.created_at >= ? AND o.created_at <= ? '
      "  AND o.status IN ('completed', 'refunded') "
      "  AND TRIM(t.tax_rate_name) != '' "
      'LIMIT ?',
      variables: [Variable(from), Variable(to), Variable(limit)],
      readsFrom: {orders, orderTaxes},
    ).get();
    return [for (final r in rows) r.read<String>('name')];
  }

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

  /// productId → units sold since [since], in the product's main unit
  /// (2 dozen = 24), over completed orders only — voided, refunded and held
  /// orders are left out so the "most sold" ranking reflects realised sales.
  ///
  /// A one-off read bounded by date: it walks only the recent slice of
  /// orders, and nothing re-runs it when a sale lands or a receipt prints.
  Future<Map<int, int>> productSalesCounts({required DateTime since}) async {
    final rows = await customSelect(
      'SELECT oi.product_id, '
      '  CAST(ROUND(SUM(oi.quantity * oi.units_per_qty)) AS INTEGER) '
      '    AS total_sold '
      'FROM orders o '
      'JOIN order_items oi ON oi.order_id = o.id '
      "WHERE o.created_at >= ? AND o.status = 'completed' "
      'GROUP BY oi.product_id',
      variables: [Variable(since)],
      readsFrom: {orderItems, orders},
    ).get();
    return {
      for (final row in rows)
        row.read<int>('product_id'): row.read<int>('total_sold'),
    };
  }

  /// One page of the CSV exports: up to [limit] orders, newest first, one
  /// row per order line (a single row with NULL item columns for an order
  /// that has none), each with its customer's name and its product's
  /// current SKU. Pass the last row's (`created_at`, `o_id`) as [before]
  /// for the next page; an empty result means the history is exhausted.
  Future<List<QueryRow>> ordersWithItemsPage({
    ({DateTime createdAt, int id})? before,
    int limit = 500,
  }) {
    return customSelect(
      'SELECT '
      'o.id as o_id, o.status, o.subtotal as o_subtotal, o.tax_total, o.discount_total as o_discount, o.total as o_total, '
      'o.payment_method, o.tendered_amount, o.change_amount, o.customer_id, o.notes, o.created_at, '
      'oi.id as item_id, oi.product_id, oi.product_name, oi.unit_price, oi.quantity, oi.discount as item_discount, '
      'oi.tax_amount as item_tax, oi.line_total, '
      'c.name as customer_name, p.sku as product_sku '
      'FROM (SELECT * FROM orders '
      '${before == null ? '' : 'WHERE (created_at, id) < (?, ?) '}'
      '  ORDER BY created_at DESC, id DESC LIMIT ?) o '
      'LEFT JOIN order_items oi ON o.id = oi.order_id '
      'LEFT JOIN customers c ON o.customer_id = c.id '
      'LEFT JOIN products p ON p.id = oi.product_id '
      'ORDER BY o.created_at DESC, o.id DESC, oi.id',
      variables: [
        if (before != null) ...[
          Variable(before.createdAt),
          Variable(before.id),
        ],
        Variable(limit),
      ],
      readsFrom: {orders, orderItems, customers, products},
    ).get();
  }
}
