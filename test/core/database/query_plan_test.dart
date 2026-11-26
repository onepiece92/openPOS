import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';

import '../../_support/query_recorder.dart';

/// Pins the query plan of every DAO query that runs against a table that
/// grows with the shop's history. Each must be answered through an index:
/// if a future change to a query (or to an index) makes SQLite fall back to
/// reading a whole table, the matching test here fails.
///
/// The plans come from `EXPLAIN QUERY PLAN` on the exact SQL (and
/// arguments) Drift sends, captured with an interceptor.
void main() {
  late AppDatabase db;
  late QueryRecorder recorder;

  setUp(() {
    recorder = QueryRecorder();
    db = AppDatabase(NativeDatabase.memory().interceptWith(recorder));
  });
  tearDown(() => db.close());

  final from = DateTime(2026, 1, 1);
  final to = DateTime(2026, 12, 31);

  /// Runs [query] and returns the plan of the last SELECT it issued — one
  /// `detail` string per plan step.
  Future<List<String>> planOf(Future<Object?> Function() query) async {
    await db.customSelect('SELECT 1').get(); // open + migrate first
    recorder.selects.clear();
    await query();
    final last = recorder.selects.last;
    final rows = await db.customSelect(
      'EXPLAIN QUERY PLAN ${last.sql}',
      variables: [for (final a in last.args) Variable(a)],
    ).get();
    return [for (final r in rows) r.read<String>('detail')];
  }

  /// A step that reads a growing table (by name or by the alias the DAO
  /// queries give it) from end to end without any index.
  final fullScan = RegExp(
      r'^SCAN (orders|order_items|order_taxes|returns|audit_log|'
      r'stock_adjustments|expenses|oi|t|i|po)$');

  void expectIndexed(List<String> plan, List<String> indexes,
      {bool allowScanOfAliasO = false}) {
    final text = plan.join(' | ');
    for (final index in indexes) {
      expect(text, contains(index), reason: 'expected $index in: $text');
    }
    for (final step in plan) {
      expect(fullScan.hasMatch(step), isFalse,
          reason: 'full table scan "$step" in: $text');
      if (!allowScanOfAliasO) {
        expect(step, isNot('SCAN o'),
            reason: 'full scan of orders in: $text');
      }
    }
  }

  group('order history', () {
    test('first page walks orders by date', () async {
      expectIndexed(await planOf(() => db.ordersDao.historyPage()),
          ['idx_orders_created_at']);
    });

    test('an older page seeks to its cursor', () async {
      final plan = await planOf(() => db.ordersDao.historyPage(
            before: Order(
              id: 9,
              invoicePrefix: '',
              status: 'completed',
              subtotal: 1,
              taxTotal: 0,
              discountTotal: 0,
              discountIsPercent: false,
              total: 1,
              tipAmount: 0,
              paymentMethod: 'cash',
              pointsRedeemed: 0,
              loyaltyDiscount: 0,
              pointsEarned: 0,
              printCount: 0,
              createdAt: DateTime(2026, 6, 1),
              updatedAt: DateTime(2026, 6, 1),
            ),
          ));
      expect(plan.join(' | '),
          contains('SEARCH o USING INDEX idx_orders_created_at'));
    });

    test('search by bill number, prefix and customer name', () async {
      for (final search in ['17', '#17', '2082/83-17', '2082/83', 'asha']) {
        final plan =
            await planOf(() => db.ordersDao.historyPage(search: search));
        expectIndexed(plan, ['idx_orders_invoice_no', 'idx_orders_customer_id']);
        expect(plan.join(' | '), isNot(contains('idx_orders_created_at')),
            reason: '"$search" must look matches up, not walk the history');
      }
    });

    test("today's order count", () async {
      expectIndexed(
          await planOf(() => db.ordersDao.orderCountForPeriod(from, to)),
          ['idx_orders_created_at']);
    });

    test("a customer's orders", () async {
      expectIndexed(await planOf(() => db.ordersDao.watchByCustomer(1).first),
          ['idx_orders_customer_id']);
    });
  });

  group('one order', () {
    test('lines, tax lines and refunds are looked up by order', () async {
      expectIndexed(await planOf(() => db.ordersDao.getItems(1)),
          ['idx_order_items_order_id']);
      expectIndexed(await planOf(() => db.ordersDao.getTaxBreakdown(1)),
          ['idx_order_taxes_order_id']);
      expectIndexed(await planOf(() => db.ordersDao.refundedTotal(1)),
          ['idx_returns_order_id']);
      expectIndexed(await planOf(() => db.ordersDao.hasRestockedReturn(1)),
          ['idx_returns_order_id']);
    });

    test('the next invoice number', () async {
      expectIndexed(await planOf(() => db.ordersDao.nextInvoiceNo()),
          ['idx_orders_invoice_no']);
    });
  });

  group('reports', () {
    test('revenue, chart rows, VAT and payment mix range over the period',
        () async {
      final dao = db.ordersDao;
      for (final query in <Future<Object?> Function()>[
        () => dao.totalRevenueForPeriod(from, to),
        () => dao.completedOrdersInPeriod(from, to),
        () => dao.vatCollectedForPeriod(from, to),
        () => dao.paymentBreakdownForPeriod(from, to),
      ]) {
        final plan = await planOf(query);
        expectIndexed(plan, ['idx_orders_created_at', 'idx_returns_order_id']);
        expect(plan.join(' | '),
            contains('SEARCH o USING INDEX idx_orders_created_at'));
      }
    });

    test('cost of goods reaches lines through the period\'s orders', () async {
      expectIndexed(
          await planOf(() => db.ordersDao.costOfGoodsForPeriod(from, to)),
          ['idx_orders_created_at', 'idx_order_items_order_id']);
    });

    test('top products total only the period\'s lines and tax lines',
        () async {
      final plan = await planOf(
          () => db.ordersDao.topSellingProductsForPeriod(from, to));
      expectIndexed(plan, [
        'idx_orders_created_at',
        'idx_order_items_order_id',
        'idx_order_taxes_order_id',
      ]);
      expect(plan.where((s) => s.contains('SCAN order_')), isEmpty,
          reason: 'no pass over all order lines / tax lines: $plan');
    });

    test('expenses total', () async {
      expectIndexed(
          await planOf(() => db.expensesDao.totalForPeriod(from, to)),
          ['idx_expenses_date']);
    });
  });

  group('drawer close', () {
    test('sales in a window range over orders by date', () async {
      final plan =
          await planOf(() => db.shiftsDao.salesInWindow(from, to));
      expectIndexed(plan, ['idx_orders_created_at']);
    });

    test('refunds in a window range over returns by date', () async {
      final plan =
          await planOf(() => db.shiftsDao.refundsInWindow(from, to));
      expectIndexed(plan, ['idx_returns_created_at']);
      expect(plan.join(' | '), contains('SEARCH o USING INTEGER PRIMARY KEY'));
    });

    test('voids are a range seek on the partial voided_at index', () async {
      final plan = await planOf(() => db.shiftsDao.voidsInWindow(from, to));
      expectIndexed(plan, ['idx_orders_voided_at', 'idx_returns_order_id']);
      expect(
          plan.join(' | '),
          contains('SEARCH o USING INDEX idx_orders_voided_at '
              '(voided_at>? AND voided_at<?)'));
      expect(plan.join(' | '), isNot(contains('audit_log')));
      expect(plan.where((s) => s.startsWith('SCAN')), isEmpty,
          reason: 'no step reads a whole table: $plan');
    });

    test('the open shift and the closed list use idx_shifts_closed_at',
        () async {
      expectIndexed(await planOf(() => db.shiftsDao.currentShift()),
          ['idx_shifts_closed_at']);
      final closed = await planOf(() => db.shiftsDao.closedShifts());
      expectIndexed(closed, ['idx_shifts_closed_at']);
      expect(closed.join(' | '), isNot(contains('TEMP B-TREE')),
          reason: 'the index delivers newest-first order: $closed');
    });
  });

  test('"most sold" counts read only the recent orders', () async {
    final plan = await planOf(
        () => db.ordersDao.productSalesCounts(since: DateTime(2026, 9, 1)));
    expectIndexed(plan, ['idx_order_items_order_id']);
    expect(plan.join(' | '),
        contains('SEARCH o USING INDEX idx_orders_created_at (created_at>?)'));
  });

  test('CSV export pages by date and joins lines by order', () async {
    for (final before in [null, (createdAt: DateTime(2026, 6, 1), id: 9)]) {
      final plan = await planOf(
          () => db.ordersDao.ordersWithItemsPage(before: before));
      // "SCAN o" here is the page of orders (a LIMITed subquery), not the
      // table.
      expectIndexed(
          plan, ['idx_orders_created_at', 'idx_order_items_order_id'],
          allowScanOfAliasO: true);
    }
  });

  test('audit log, expense list and stock history', () async {
    expectIndexed(await planOf(() => db.auditDao.watchRecent().first),
        ['idx_audit_log_created_at']);
    expectIndexed(await planOf(() => db.auditDao.queryByDateRange(from, to)),
        ['idx_audit_log_created_at']);
    expectIndexed(await planOf(() => db.expensesDao.watchAll().first),
        ['idx_expenses_date']);
    final stock =
        await planOf(() => db.inventoryDao.getAdjustmentsForProduct(1));
    expectIndexed(stock, ['idx_stock_adjustments_product_created']);
    expect(stock.join(' | '), isNot(contains('TEMP B-TREE')),
        reason: 'the index also delivers newest-first order');
    final byOrder =
        await planOf(() => db.inventoryDao.getAdjustmentsForOrder(1));
    expectIndexed(byOrder, ['idx_stock_adjustments_order_id']);
    expect(
        byOrder.join(' | '),
        contains('SEARCH stock_adjustments USING INDEX '
            'idx_stock_adjustments_order_id (order_id=?)'));
  });

  test('connection pragmas: foreign keys on, temp space in memory, '
      'synchronous not lowered', () async {
    Future<Object?> pragma(String name) async =>
        (await db.customSelect('PRAGMA $name').getSingle()).data.values.single;
    expect(await pragma('foreign_keys'), 1);
    expect(await pragma('temp_store'), 2, reason: '2 = MEMORY');
    // 2 = FULL, SQLite's default. Never NORMAL/OFF: a committed sale must
    // survive power loss.
    expect(await pragma('synchronous'), 2);
  });
}
