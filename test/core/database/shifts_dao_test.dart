import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/daos/shifts_dao.dart';

import '../../_support/test_db.dart';

/// Till sessions and the drawer-close aggregates (schema v16).
void main() {
  late AppDatabase db;
  late ShiftsDao dao;

  setUp(() {
    db = openInMemoryDatabase();
    dao = db.shiftsDao;
  });
  tearDown(() => db.close());

  Future<void> close(int id, {double counted = 0, DateTime? at}) =>
      dao.closeShift(
        id,
        cashSales: 0,
        cashTips: 0,
        cashRefunds: 0,
        paidOut: 0,
        expectedCash: counted,
        countedCash: counted,
        summaryText: 'Shift #$id',
        closedAt: at,
      );

  group('lifecycle', () {
    test('only one shift may be open at a time', () async {
      final id = await dao.openShift(openingCash: 100);
      final open = await dao.currentShift();
      expect(open!.id, id);
      expect(open.openingCash, 100);
      expect(open.closedAt, isNull);
      expect(open.countedCash, isNull);

      await expectLater(dao.openShift(openingCash: 5),
          throwsA(isA<ShiftStateException>()));
      expect(await db.select(db.shifts).get(), hasLength(1));
    });

    test('close freezes the figures; closing twice is refused', () async {
      final id = await dao.openShift(openingCash: 50);
      await dao.closeShift(
        id,
        cashSales: 200,
        cashTips: 10,
        cashRefunds: 20,
        paidOut: 5,
        expectedCash: 235,
        countedCash: 230,
        summaryText: 'Z report',
        notes: 'short 5',
        closedAt: DateTime(2026, 3, 1, 22),
      );
      expect(await dao.currentShift(), isNull);
      final s = (await dao.lastClosedShift())!;
      expect(s.id, id);
      expect(s.closedAt, DateTime(2026, 3, 1, 22));
      expect((s.cashSales, s.cashTips, s.cashRefunds, s.paidOut),
          (200.0, 10.0, 20.0, 5.0));
      expect((s.expectedCash, s.countedCash), (235.0, 230.0));
      expect(s.summaryText, 'Z report');
      expect(s.notes, 'short 5');

      await expectLater(close(id), throwsA(isA<ShiftStateException>()));
      await expectLater(close(999), throwsA(isA<ShiftStateException>()));
      expect((await dao.lastClosedShift())!.summaryText, 'Z report');
    });

    test('a new shift can open once the last one is closed', () async {
      final a = await dao.openShift(openingCash: 0);
      await close(a, counted: 80);
      final last = await dao.lastClosedShift();
      final b = await dao.openShift(openingCash: last!.countedCash!);
      expect((await dao.currentShift())!.id, b);
      expect((await dao.currentShift())!.openingCash, 80);
    });

    test('lastClosedShift is null before any close', () async {
      expect(await dao.lastClosedShift(), isNull);
      await dao.openShift(openingCash: 0);
      expect(await dao.lastClosedShift(), isNull);
    });

    test('closedShifts lists newest close first and honours limit',
        () async {
      for (final day in [3, 1, 2]) {
        final id = await dao.openShift(openingCash: 0);
        await close(id, counted: day.toDouble(), at: DateTime(2026, 5, day));
      }
      await dao.openShift(openingCash: 0); // open: never listed
      final all = await dao.closedShifts();
      expect(all.map((s) => s.countedCash), [3.0, 2.0, 1.0]);
      expect((await dao.closedShifts(limit: 2)).map((s) => s.countedCash),
          [3.0, 2.0]);
      expect((await dao.lastClosedShift())!.countedCash, 3.0);
    });

    test('watchCurrentShift follows open and close', () async {
      final seen = <int?>[];
      final sub = dao.watchCurrentShift().listen((s) => seen.add(s?.id));
      await pumpEventQueue();
      final id = await dao.openShift(openingCash: 0);
      await pumpEventQueue();
      await close(id);
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [null, id, null]);
    });
  });

  // ── Aggregates ───────────────────────────────────────────────────────────

  group('window aggregates', () {
    final from = DateTime(2026, 6, 10, 8);
    final to = DateTime(2026, 6, 10, 20);
    final inside = DateTime(2026, 6, 10, 12);

    Future<int> order({
      required double total,
      String method = 'cash',
      String status = 'completed',
      double tip = 0,
      double tax = 0,
      DateTime? at,
    }) =>
        db.ordersDao.insertOrder(OrdersCompanion.insert(
          subtotal: total - tax,
          taxTotal: Value(tax),
          total: total,
          tipAmount: Value(tip),
          paymentMethod: method,
          status: Value(status),
          createdAt: Value(at ?? inside),
        ));

    Future<void> refund(int orderId, double amount,
            {double tip = 0, DateTime? at}) =>
        db.ordersDao.insertReturn(ReturnsCompanion.insert(
          orderId: orderId,
          amount: amount,
          tipAmount: Value(tip),
          createdAt: Value(at ?? inside),
        ));

    test('an empty window is all zeros', () async {
      final f = await dao.figuresForWindow(from, to);
      expect((f.cashSales, f.cashTips, f.cashRefunds, f.netTips),
          (0.0, 0.0, 0.0, 0.0));
      expect(f.sales.orderCount, 0);
      expect(f.sales.taxCollected, 0);
      expect(f.sales.byMethod, isEmpty);
    });

    test('a seeded day: cash, card, tips, refunds, a void, edges', () async {
      // Cash sale 100 + tip 10, tax 13.
      final a = await order(total: 100, tip: 10, tax: 13);
      // Cash sale 50 + tip 5, partly refunded 20 without the tip.
      final b = await order(total: 50, tip: 5);
      await refund(b, 20);
      // Cash sale 40 + tip 4, partly refunded 10 with 4 of tip back.
      final c = await order(total: 40, tip: 4);
      await refund(c, 10, tip: 4);
      // Card sale 200 + tip 20, tax 26.
      await order(total: 200, method: 'card', tip: 20, tax: 26);
      // Cash sale fully refunded in the window: counts as sale and refund.
      final d = await order(total: 30, status: 'refunded');
      await refund(d, 30);
      // Voided cash sale with a tip: not a sale, not a tip.
      await order(total: 70, tip: 7, status: 'voided');
      // Held ticket: never paid.
      await order(total: 999, status: 'held');
      // Outside the window: before `from`, and exactly at `to` (half-open).
      await order(total: 500, tip: 50, at: DateTime(2026, 6, 10, 7, 59));
      await order(total: 600, tip: 60, at: to);
      // Last week's cash sale refunded today, with its tip: today's refund.
      final old = await order(
          total: 80, tip: 8, at: DateTime(2026, 6, 3), status: 'refunded');
      await refund(old, 80, tip: 8);
      // ...and a refund of today's sale dated after the window: not today.
      await refund(a, 5, at: DateTime(2026, 6, 11));

      final f = await dao.figuresForWindow(from, to);

      expect(f.cashSales, 100 + 50 + 40 + 30);
      expect(f.cashTips, 10 + 5 + 4);
      expect(f.cashRefunds, 20 + (10 + 4) + 30 + (80 + 8));
      expect(f.sales.byMethod.keys.toSet(), {'cash', 'card'});
      expect(f.sales.byMethod['card']!.total, 200);
      expect(f.sales.byMethod['card']!.tips, 20);
      expect(f.sales.orderCount, 5);
      expect(f.sales.cash.count, 4);
      expect(f.sales.totalSales, 420);
      expect(f.sales.taxCollected, 39);
      expect(f.sales.tipsCollected, 39);
      expect((f.sales.voidedCount, f.sales.voidedTotal), (1, 70.0));
      expect(f.refunds.cash.count, 4);
      expect(f.refunds.cash.amount, 140);
      expect(f.refunds.cash.tips, 12);
      expect(f.refunds.tipsRefunded, 12);
      expect(f.netTips, 39 - 12);
      expect(f.expectedCash(openingCash: 100, paidOut: 15),
          100 + 220 + 19 - 152 - 15);
    });

    test('card refunds do not touch the cash drawer', () async {
      final o = await order(total: 60, method: 'card', tip: 6);
      await refund(o, 60, tip: 6);
      final f = await dao.figuresForWindow(from, to);
      expect(f.cashRefunds, 0);
      expect(f.refunds.byMethod['card']!.total, 66);
      expect(f.netTips, 0);
    });
  });

  group('tips never enter revenue or tax', () {
    final from = DateTime(2026, 1, 1);
    final to = DateTime(2026, 12, 31);

    Future<int> seed({required bool withTips}) async {
      final t = withTips ? 1.0 : 0.0;
      final a = await db.ordersDao.insertOrder(OrdersCompanion.insert(
        subtotal: 100,
        taxTotal: const Value(13),
        total: 113,
        tipAmount: Value(15 * t),
        paymentMethod: 'cash',
        createdAt: Value(DateTime(2026, 4, 1)),
      ));
      await db.ordersDao.insertOrder(OrdersCompanion.insert(
        subtotal: 50,
        total: 50,
        tipAmount: Value(5 * t),
        paymentMethod: 'card',
        createdAt: Value(DateTime(2026, 4, 2)),
      ));
      await db.ordersDao.insertReturn(ReturnsCompanion.insert(
        orderId: a,
        amount: 13,
        tipAmount: Value(3 * t),
        createdAt: Value(DateTime(2026, 4, 3)),
      ));
      return a;
    }

    Future<List<String>> figures(int a) async {
      final o = db.ordersDao;
      final pay = await o.paymentBreakdownForPeriod(from, to);
      pay.sort((x, y) => (x['method'] as String).compareTo(y['method']));
      return [
        await o.totalRevenueForPeriod(from, to),
        await o.vatCollectedForPeriod(from, to),
        (await o.completedOrdersInPeriod(from, to)).map((r) => r.total),
        pay.map((m) => m['total']),
        await o.refundedTotal(a),
      ].map((v) => v.toString()).toList();
    }

    test('revenue, VAT, chart rows, payment mix and refunds are identical',
        () async {
      final plain = await figures(await seed(withTips: false));
      await db.delete(db.returns).go();
      await db.delete(db.orders).go();
      final tipped = await figures(await seed(withTips: true));
      expect(tipped, plain);
      expect(plain.first, '150.0'); // 113 + 50 − 13 refunded
      final stored = await db.select(db.orders).get();
      expect(stored.map((o) => o.total), [113.0, 50.0],
          reason: 'orders.total stays tip-free');
    });
  });
}
