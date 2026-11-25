import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/daos/shifts_dao.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/returns/domain/void_order.dart' as svc;

import '../../_support/sales.dart';
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

  // ── Seeding helpers ──────────────────────────────────────────────────────

  final day = DateTime(2026, 6, 10);
  DateTime at(int h, [int m = 0, int s = 0]) =>
      DateTime(day.year, day.month, day.day, h, m, s);

  Future<int> order({
    required double total,
    String method = 'cash',
    String status = 'completed',
    double tip = 0,
    double tax = 0,
    String prefix = '',
    DateTime? when,
  }) =>
      db.ordersDao.insertOrder(OrdersCompanion.insert(
        subtotal: total - tax,
        taxTotal: Value(tax),
        total: total,
        tipAmount: Value(tip),
        paymentMethod: method,
        status: Value(status),
        invoicePrefix: Value(prefix),
        createdAt: Value(when ?? at(12)),
      ));

  Future<void> refund(int orderId, double amount,
          {double tip = 0, DateTime? when}) =>
      db.ordersDao.insertReturn(ReturnsCompanion.insert(
        orderId: orderId,
        amount: amount,
        tipAmount: Value(tip),
        createdAt: Value(when ?? at(13)),
      ));

  /// A void as the app writes it: status + voided_at, and the audit entry
  /// (written, never read for money — see 'a void with no audit row').
  Future<void> voidAt(int orderId, DateTime when) async {
    await db.ordersDao.voidOrder(orderId, at: when);
    await db.into(db.auditLog).insert(AuditLogCompanion.insert(
          entityType: 'order',
          entityId: Value(orderId),
          action: 'void',
          createdAt: Value(when),
        ));
  }

  String summaryOf(ShiftClose c) =>
      'expected ${c.expectedCash} counted ${c.countedCash}';

  Future<ShiftClose> close(int id,
          {double counted = 0, double paidOut = 0, DateTime? when}) =>
      dao.closeShift(id,
          countedCash: counted, paidOut: paidOut, at: when, summary: summaryOf);

  // ── Lifecycle ────────────────────────────────────────────────────────────

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

    test('SQLite itself refuses a second open shift (idx_shifts_one_open)',
        () async {
      await dao.openShift(openingCash: 0);
      await expectLater(
          db.into(db.shifts).insert(ShiftsCompanion.insert()),
          throwsA(anything));
      // Closed shifts are not limited.
      await db.into(db.shifts).insert(
          ShiftsCompanion.insert(closedAt: Value(at(1))));
      await db.into(db.shifts).insert(
          ShiftsCompanion.insert(closedAt: Value(at(2))));
    });

    test('close computes and freezes the figures; closing twice is refused',
        () async {
      final id = await dao.openShift(openingCash: 50, openedAt: at(8));
      await order(total: 200, tip: 10);
      final o = await order(total: 40);
      await refund(o, 20);

      final c = await close(id, counted: 274.999, paidOut: 5, when: at(22));
      expect(c.countedCash, 275.0, reason: 'rounded on input');
      expect(c.expectedCash, 50 + 240 + 10 - 20 - 5);
      expect(c.overShort, 0);
      expect(c.overShortCents, 0);

      expect(await dao.currentShift(), isNull);
      final s = (await dao.lastClosedShift())!;
      expect(s.id, id);
      expect(s.closedAt, at(22));
      expect((s.cashSales, s.cashTips, s.cashRefunds, s.cashVoids, s.paidOut),
          (240.0, 10.0, 20.0, 0.0, 5.0));
      expect((s.expectedCash, s.countedCash), (275.0, 275.0));
      expect(s.summaryText, 'expected 275.0 counted 275.0');

      await expectLater(close(id), throwsA(isA<ShiftStateException>()));
      await expectLater(close(999), throwsA(isA<ShiftStateException>()));
      expect((await dao.lastClosedShift())!.summaryText,
          'expected 275.0 counted 275.0');
    });

    test('a sale written before the close is in the frozen figures', () async {
      final id = await dao.openShift(openingCash: 0, openedAt: at(8));
      await order(total: 10, when: at(20, 59, 59));
      // Figures are taken inside the close transaction, at the close time.
      final c = await close(id, when: at(21));
      expect(c.figures.cashSales, 10);
      expect((await dao.lastClosedShift())!.cashSales, 10);
    });

    test('a new shift opens once the last is closed, from its counted cash',
        () async {
      final a = await dao.openShift(openingCash: 0, openedAt: at(8));
      await close(a, counted: 80, when: at(9));
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
      for (final h in [9, 10, 11]) {
        final id = await dao.openShift(openingCash: 0, openedAt: at(h - 1));
        await close(id, counted: h.toDouble(), when: at(h));
      }
      await dao.openShift(openingCash: 0); // open: never listed
      expect((await dao.closedShifts()).map((s) => s.countedCash),
          [11.0, 10.0, 9.0]);
      expect((await dao.closedShifts(limit: 2)).map((s) => s.countedCash),
          [11.0, 10.0]);
      expect((await dao.lastClosedShift())!.countedCash, 11.0);
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

  // ── Windows ──────────────────────────────────────────────────────────────

  group('windows', () {
    test('contiguous: the next window starts at the previous close', () async {
      final a = await dao.openShift(openingCash: 0, openedAt: at(8));
      await order(total: 1, when: at(11, 59, 59)); // shift a
      await order(total: 2, when: at(12)); // same second as a's close: b
      await close(a, when: at(12));
      await order(total: 4, when: at(12, 10)); // between close and open: b
      final b = await dao.openShift(openingCash: 0, openedAt: at(12, 30));
      final shiftB = (await dao.currentShift())!;
      expect(await dao.windowStart(shiftB), at(12));
      await order(total: 8, when: at(13));
      final cb = await close(b, when: at(14));

      expect((await dao.lastClosedShift())!.id, b);
      final shiftA = (await dao.closedShifts()).last;
      expect(shiftA.cashSales, 1);
      expect(cb.figures.cashSales, 2 + 4 + 8);
      expect((cb.figures.from, cb.figures.to), (at(12), at(14)));
    });

    test('close time is cut to whole seconds', () async {
      final a = await dao.openShift(openingCash: 0, openedAt: at(8));
      await order(total: 1, when: at(12)); // the close's own second: next
      await close(a, when: at(12).add(const Duration(milliseconds: 700)));
      final s = (await dao.lastClosedShift())!;
      expect(s.closedAt, at(12));
      expect(s.cashSales, 0);
    });

    test('clock set back: close is clamped to the opening, never overlaps',
        () async {
      final a = await dao.openShift(openingCash: 0, openedAt: at(10));
      await close(a, when: at(9)); // clock went back an hour
      final s = (await dao.lastClosedShift())!;
      expect(s.closedAt, at(10));

      // The next shift opens "before" the last close: its window still
      // starts at that close, and its close is clamped to it.
      final b = await dao.openShift(openingCash: 0, openedAt: at(9, 30));
      final shiftB = (await dao.currentShift())!;
      expect(await dao.windowStart(shiftB), at(10));
      final cb = await close(b, when: at(9, 45));
      expect((cb.figures.from, cb.figures.to), (at(10), at(10)));
      expect((await dao.lastClosedShift())!.closedAt, at(10));
    });

    test('previewClose writes nothing', () async {
      final a = await dao.openShift(openingCash: 10, openedAt: at(8));
      await order(total: 5);
      final p = await dao.previewClose(a, at: at(20), countedCash: 15);
      expect(p.expectedCash, 15);
      expect(p.overShort, 0);
      expect((await dao.currentShift())!.closedAt, isNull);
    });
  });

  // ── Aggregates ───────────────────────────────────────────────────────────

  group('window aggregates', () {
    final from = at(8);
    final to = at(20);

    test('an empty window is all zeros', () async {
      final f = await dao.figuresForWindow(from, to);
      expect((f.cashSales, f.cashTips, f.cashRefunds, f.cashVoids),
          (0.0, 0.0, 0.0, 0.0));
      expect((f.grossTax, f.refundedTax, f.netTax, f.netTips),
          (0.0, 0.0, 0.0, 0.0));
      expect(f.sales.byMethod, isEmpty);
    });

    test('a seeded day: cash, card, tips, refunds, voids, imports, edges',
        () async {
      final a = await order(total: 100, tip: 10);
      // Partly refunded, without and with the tip.
      final b = await order(total: 50, tip: 5);
      await refund(b, 20);
      final c = await order(total: 40, tip: 4);
      await refund(c, 10, tip: 4);
      await order(total: 200, method: 'card', tip: 20);
      // Fully refunded in the window: a sale and a refund.
      final d = await order(total: 30, status: 'refunded');
      await refund(d, 30);
      // Voided in the window: a sale and money out (total + tip).
      final e = await order(total: 70, tip: 7);
      await voidAt(e, at(14));
      // Refunded 20 then voided: money out 20 + 80, nets to 0.
      final f0 = await order(total: 100);
      await refund(f0, 20);
      await voidAt(f0, at(15));
      // Never paid; and orders outside [from, to).
      await order(total: 999, status: 'held');
      await order(total: 500, tip: 50, when: at(7, 59, 59));
      await order(total: 600, tip: 60, when: to);
      // Last week's sales: refunded / voided today count today.
      final old = await order(total: 80, tip: 8, when: DateTime(2026, 6, 3));
      await refund(old, 80, tip: 8);
      final old2 = await order(total: 60, tip: 6, when: DateTime(2026, 6, 3));
      await voidAt(old2, at(16));
      // Today's sale refunded tomorrow: not today.
      await refund(a, 5, when: DateTime(2026, 6, 11));
      // Imported orders, their refunds and voids: never drawer activity.
      final imp = await order(total: 300, prefix: 'IMP');
      await refund(imp, 10);
      final imp2 = await order(total: 300, prefix: 'IMP');
      await voidAt(imp2, at(14));
      // A pre-v16 void: voided, no voided_at — ignored.
      final pre = await order(
          total: 90, status: 'voided', when: DateTime(2026, 6, 3));
      await db.into(db.auditLog).insert(AuditLogCompanion.insert(
          entityType: 'order',
          entityId: Value(pre),
          action: 'void',
          createdAt: Value(at(12))));

      final f = await dao.figuresForWindow(from, to);

      expect(f.cashSales, 100 + 50 + 40 + 30 + 70 + 100);
      expect(f.cashTips, 10 + 5 + 4 + 7);
      expect(f.sales.cash.count, 6);
      expect(f.sales['card'].amount, 200);
      expect(f.sales['card'].tips, 20);
      expect(f.sales.byMethod.keys.toSet(), {'cash', 'card'});

      expect(f.cashRefunds, 20 + (10 + 4) + 30 + 20 + (80 + 8));
      expect(f.refunds.cash.count, 5);
      expect(f.cashVoids, (70 + 7) + 80 + (60 + 6));
      expect(f.voids.cash.count, 3);

      expect(f.expectedCash(openingCash: 100, paidOut: 15),
          100 + 390 + 26 - 172 - 223 - 15);
      expect((f.grossSales, f.refundedSales, f.netSales),
          (590.0, 160.0 + 210.0, 220.0));
      expect((f.tipsCollected, f.tipsReturned, f.netTips),
          (46.0, 12.0 + 13.0, 21.0));
    });

    test('refunded 20 then voided in one shift nets to zero', () async {
      final id = await dao.openShift(openingCash: 50, openedAt: at(8));
      final o = await order(total: 100);
      await refund(o, 20);
      await voidAt(o, at(14));
      final c = await close(id, counted: 50, when: at(20));
      expect((c.figures.cashSales, c.figures.cashRefunds, c.figures.cashVoids),
          (100.0, 20.0, 80.0));
      expect(c.expectedCash, 50);
      expect(c.figures.netSales, 0);
    });

    test('a sale voided in a later shift is money out in that shift',
        () async {
      final s1 = await dao.openShift(openingCash: 0, openedAt: at(8));
      final o = await order(total: 100, tip: 10, when: at(9));
      final c1 = await close(s1, counted: 110, when: at(10));
      expect(c1.expectedCash, 110);

      final s2 = await dao.openShift(openingCash: 110, openedAt: at(11));
      await voidAt(o, at(12));
      final c2 = await close(s2, counted: 0, when: at(13));
      expect(c2.figures.cashSales, 0);
      expect(c2.figures.cashVoids, 110);
      expect(c2.expectedCash, 0);
    });

    test('the app\'s own void (audit entry + voided_at) is found', () async {
      final o = await order(total: 25, when: DateTime.now()
          .subtract(const Duration(minutes: 5)));
      await svc.voidOrder(db, AuditService(db), orderId: o, reason: 'test');
      final f = await dao.figuresForWindow(
          DateTime.now().subtract(const Duration(hours: 1)),
          DateTime.now().add(const Duration(hours: 1)));
      expect((f.cashSales, f.cashVoids), (25.0, 25.0));
    });

    test('a void with no audit row still counts: money comes from voided_at',
        () async {
      final o = await order(total: 40, tip: 4);
      await db.ordersDao.voidOrder(o, at: at(14));
      final f = await dao.figuresForWindow(from, to);
      expect((f.cashSales, f.cashVoids), (40.0, 44.0));
    });

    test('a normal sale stores voided_at NULL, so the partial index skips it',
        () async {
      final p = await seedProduct(db, sku: 'T', stock: 5);
      final o = await sell(db, AuditService(db), [line(p)]);
      expect((await db.ordersDao.getById(o))!.voidedAt, isNull);
      Future<int> indexed() async => (await db
              .customSelect('SELECT COUNT(*) AS c FROM orders '
                  'INDEXED BY idx_orders_voided_at WHERE voided_at IS NOT NULL')
              .getSingle())
          .read<int>('c');
      expect(await indexed(), 0);
      await svc.voidOrder(db, AuditService(db), orderId: o, reason: 'x');
      expect(await indexed(), 1);
    });

    test('tax: gross, the refunded share, net', () async {
      final o = await order(total: 113, tax: 13);
      await refund(o, 56.5);
      final v = await order(total: 226, tax: 26, method: 'card');
      await voidAt(v, at(14));
      final f = await dao.figuresForWindow(from, to);
      expect(f.grossTax, 39);
      expect(f.refundedTax, 6.5 + 26);
      expect(f.netTax, 6.5);
    });

    test('card refunds and voids do not touch the cash drawer', () async {
      final o = await order(total: 60, method: 'card', tip: 6);
      await refund(o, 60, tip: 6);
      final f = await dao.figuresForWindow(from, to);
      expect(f.cashRefunds, 0);
      expect(f.refunds['card'].total, 66);
      expect(f.netTips, 0);
    });

    test('payment methods are bucketed case- and space-insensitively',
        () async {
      await order(total: 1, method: 'Cash');
      await order(total: 2, method: ' cash ');
      await order(total: 4, method: '');
      await order(total: 8, method: 'CARD');
      final f = await dao.figuresForWindow(from, to);
      expect(f.sales.byMethod.keys.toSet(), {'cash', 'card'});
      expect(f.cashSales, 7);

      final pay = await db.ordersDao.paymentBreakdownForPeriod(from, to);
      expect({for (final m in pay) m['method']: m['count']},
          {'cash': 3, 'card': 1});
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
