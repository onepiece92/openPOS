import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/orders/domain/order_history.dart';
import 'package:pos_app/features/reports/domain/report_data.dart';
import 'package:pos_app/features/returns/domain/process_return.dart';
import 'package:pos_app/features/returns/domain/void_order.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';
import '../../_support/features.dart';

/// Order history: every order is reachable by paging on created_at, search
/// runs in SQL on bill number / prefix / customer name, and today's summary
/// is an aggregate that agrees with the dashboard.
void main() {
  late AppDatabase db;
  late AuditService audit;

  setUp(() {
    db = openInMemoryDatabase();
    audit = AuditService(db);
  });
  tearDown(() => db.close());

  /// Inserts a bare order row. [daysAgo] spaces orders out in time.
  Future<int> order({
    required int invoiceNo,
    String prefix = '',
    int? customerId,
    double total = 10,
    int daysAgo = 0,
    DateTime? at,
    String status = 'completed',
  }) =>
      db.ordersDao.insertOrder(OrdersCompanion.insert(
        subtotal: total,
        total: total,
        paymentMethod: 'cash',
        status: Value(status),
        invoiceNo: Value(invoiceNo),
        invoicePrefix: Value(prefix),
        customerId: Value(customerId),
        createdAt: Value(
            at ?? DateTime(2026, 6, 1, 12).subtract(Duration(days: daysAgo))),
      ));

  Future<int> customer(String name) =>
      db.customersDao.upsert(CustomersCompanion.insert(name: name));

  Future<List<int>> search(String q) async =>
      [for (final o in await db.ordersDao.historyPage(search: q)) o.id];

  group('paging', () {
    test('pages on created_at reach every order, newest first, no repeats',
        () async {
      // 130 orders, inserted oldest-last so id order ≠ date order.
      final ids = <int>[];
      for (var i = 0; i < 130; i++) {
        ids.add(await order(invoiceNo: i + 1, daysAgo: i));
      }

      final seen = <int>[];
      Order? cursor;
      var pages = 0;
      while (true) {
        final page = await db.ordersDao.historyPage(before: cursor, limit: 50);
        if (page.isEmpty) break;
        pages++;
        seen.addAll(page.map((o) => o.id));
        cursor = page.last;
      }
      expect(pages, 3);
      expect(seen, ids, reason: 'newest (daysAgo 0) first, oldest last');
    });

    test('orders sharing a timestamp are neither skipped nor repeated',
        () async {
      final at = DateTime(2026, 6, 1, 9);
      final ids = [
        for (var i = 0; i < 7; i++) await order(invoiceNo: i + 1, at: at),
      ];
      final seen = <int>[];
      Order? cursor;
      while (true) {
        final page = await db.ordersDao.historyPage(before: cursor, limit: 3);
        if (page.isEmpty) break;
        seen.addAll(page.map((o) => o.id));
        cursor = page.last;
      }
      expect(seen, ids.reversed.toList());
    });
  });

  group('search', () {
    test('finds a bill by its invoice number, not by row id', () async {
      // Row ids 1..3 carry invoice numbers 501..503.
      await order(invoiceNo: 501);
      final second = await order(invoiceNo: 502);
      await order(invoiceNo: 503);

      expect(await search('502'), [second]);
      expect(await search('#502'), [second]);
      expect(await search('2'), isEmpty,
          reason: 'row id 2 is not what the bill says');
      expect(await search('50'), isEmpty, reason: 'exact number, not a part');
    });

    test('finds a bill by prefix and number, and all bills of a prefix',
        () async {
      final old17 = await order(invoiceNo: 17, prefix: '2081/82', daysAgo: 400);
      final new17 = await order(invoiceNo: 17, prefix: '2082/83', daysAgo: 2);
      final new18 = await order(invoiceNo: 18, prefix: '2082/83', daysAgo: 1);
      final plain = await order(invoiceNo: 17);

      expect(await search('2082/83-17'), [new17]);
      expect(await search('2081/82-17'), [old17]);
      expect(await search('17'), [plain, new17, old17],
          reason: 'the bare number matches under every prefix, newest first');
      expect(await search('2082/83'), [new18, new17]);
    });

    test('a legacy row without an invoice number is found by its id', () async {
      await order(invoiceNo: 900);
      final legacy = await db.ordersDao.insertOrder(
          OrdersCompanion.insert(subtotal: 5, total: 5, paymentMethod: 'cash'));
      expect(await search('$legacy'), [legacy]);
    });

    test('finds orders by part of the customer name, any case', () async {
      final asha = await customer('Asha Gurung');
      final bikram = await customer('Bikram Rai');
      final a1 = await order(invoiceNo: 1, customerId: asha, daysAgo: 3);
      await order(invoiceNo: 2, customerId: bikram, daysAgo: 2);
      final a2 = await order(invoiceNo: 3, customerId: asha, daysAgo: 1);
      await order(invoiceNo: 4);

      expect(await search('gurung'), [a2, a1]);
      expect(await search('ASHA'), [a2, a1]);
      expect(await search('nobody'), isEmpty);
    });

    test('% and _ in a search are literal, not wildcards', () async {
      final c = await customer('Asha');
      await order(invoiceNo: 1, customerId: c);
      expect(await search('%'), isEmpty);
      expect(await search('A_ha'), isEmpty);
    });

    test('reaches orders far beyond the first page', () async {
      final c = await customer('Old Timer');
      final ancient = await order(invoiceNo: 1, customerId: c, daysAgo: 2000);
      for (var i = 0; i < 600; i++) {
        await order(invoiceNo: i + 2, daysAgo: i);
      }
      expect(await search('old timer'), [ancient]);
      expect(await search('1'), [ancient]);
    });

    test('a search with a decimal point matches the order total', () async {
      final a = await order(invoiceNo: 1, total: 1250.5);
      await order(invoiceNo: 2, total: 1250);
      expect(await search('1250.50'), [a]);
    });

    test('search results page like the full list', () async {
      final c = await customer('Asha');
      final ids = [
        for (var i = 0; i < 5; i++)
          await order(invoiceNo: i + 1, customerId: c, daysAgo: i),
      ];
      final first = await db.ordersDao.historyPage(search: 'asha', limit: 2);
      final second = await db.ordersDao
          .historyPage(search: 'asha', before: first.last, limit: 2);
      expect([...first, ...second].map((o) => o.id), ids.take(4));
    });
  });

  group('OrderHistoryNotifier', () {
    late ProviderContainer container;

    /// Opens the screen: listens to the provider and waits for a settled
    /// state.
    Future<OrderHistoryNotifier> open({int pageSize = 3}) async {
      container = ProviderContainer(overrides: [
        allFeaturesOn,
        databaseProvider.overrideWithValue(db),
        orderHistoryProvider.overrideWith(
            (ref) => OrderHistoryNotifier(db, pageSize: pageSize)),
      ]);
      addTearDown(container.dispose);
      container.listen(orderHistoryProvider, (_, __) {});
      await pumpEventQueue();
      return container.read(orderHistoryProvider.notifier);
    }

    OrderHistoryState state() => container.read(orderHistoryProvider);

    test('loads one page, then older pages on demand until the end', () async {
      final ids = [
        for (var i = 0; i < 7; i++) await order(invoiceNo: i + 1, daysAgo: i),
      ];
      final notifier = await open();
      expect(state().isLoading, isFalse);
      expect(state().orders.map((o) => o.id), ids.take(3));
      expect(state().hasMore, isTrue);

      await notifier.loadMore();
      expect(state().orders.map((o) => o.id), ids.take(6));
      expect(state().hasMore, isTrue);

      await notifier.loadMore();
      expect(state().orders.map((o) => o.id), ids);
      expect(state().hasMore, isFalse);

      await notifier.loadMore(); // nothing left: a no-op
      expect(state().orders, hasLength(7));
    });

    test('search replaces the list and clearing it restores it', () async {
      final c = await customer('Asha');
      final hers = await order(invoiceNo: 1, customerId: c, daysAgo: 50);
      for (var i = 0; i < 5; i++) {
        await order(invoiceNo: i + 2, daysAgo: i);
      }
      final notifier = await open();
      expect(state().orders.map((o) => o.id), isNot(contains(hers)));

      await notifier.setSearch(' asha ');
      expect(state().search, 'asha');
      expect(state().orders.map((o) => o.id), [hers]);
      expect(state().hasMore, isFalse);

      await notifier.setSearch('');
      expect(state().orders, hasLength(3));
      expect(state().hasMore, isTrue);
    });

    test(
        'a new sale and a void show up without reopening, and '
        'the rows already scrolled to stay loaded', () async {
      final p = await seedProduct(db, sku: 'A', stock: 0, price: 10);
      for (var i = 0; i < 5; i++) {
        await order(invoiceNo: 100 + i, daysAgo: i + 1);
      }
      final notifier = await open();
      await notifier.loadMore();
      expect(state().orders, hasLength(5));

      final sale = await sell(db, audit, [line(p, qty: 2, price: 10)]);
      await pumpEventQueue();
      expect(state().orders.first.id, sale);
      expect(state().orders, hasLength(5),
          reason: 'still the five rows the cashier had loaded');
      expect(state().hasMore, isTrue);

      await voidOrder(db, audit, orderId: sale, reason: 'test');
      await pumpEventQueue();
      expect(state().orders.first.status, 'voided');
    });

    test(
        "today's summary is an aggregate over all of today, net of refunds, "
        'equal to the dashboard revenue', () async {
      final p = await seedProduct(db, sku: 'A', stock: 0, price: 10);
      // More sales today than one page holds.
      final sales = [
        for (var i = 0; i < 6; i++)
          await sell(db, audit, [line(p, qty: 10, price: 10)]), // 100 each
      ];
      await processReturn(db, audit,
          orderId: sales[0], amount: 30, restock: false); // partly refunded
      await processReturn(db, audit,
          orderId: sales[1], amount: 100, restock: false); // fully refunded
      await voidOrder(db, audit, orderId: sales[2], reason: 'test');
      await order(invoiceNo: 9000, total: 999, daysAgo: 30); // not today

      await open();
      expect(state().orders, hasLength(3), reason: 'only one page is loaded');
      expect(state().todayOrders, 6, reason: 'every order rung up today');
      // 70 (partly refunded) + 0 (refunded) + 0 (voided) + 3 × 100.
      expect(state().todayRevenue, 370);

      const today = ReportPeriod.today;
      expect(state().todayRevenue,
          await db.ordersDao.totalRevenueForPeriod(today.from, today.to));
      final report = await container.read(reportProvider(
              ReportQuery(from: today.from, to: today.to, label: 'Today'))
          .future);
      expect(state().todayRevenue, report.revenue);
    });

    test('stops listening to the database once the screen closes', () async {
      container = ProviderContainer(
          overrides: [allFeaturesOn, databaseProvider.overrideWithValue(db)]);
      addTearDown(container.dispose);
      final screen = container.listen(orderHistoryProvider, (_, __) {});
      await pumpEventQueue();
      screen.close();
      await pumpEventQueue();
      expect(container.exists(orderHistoryProvider), isFalse);
      // A write after disposal must not throw or resurrect the notifier.
      await order(invoiceNo: 1);
      await pumpEventQueue();
      expect(container.exists(orderHistoryProvider), isFalse);
    });
  });
}
