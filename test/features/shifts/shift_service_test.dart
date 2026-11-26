import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/shifts/data/shift_service.dart';
import 'package:pos_app/features/shifts/domain/shift_summary.dart';

import '../../_support/test_db.dart';

void main() {
  late AppDatabase db;
  late ShiftService svc;

  setUp(() {
    db = openInMemoryDatabase();
    svc = ShiftService(db);
  });
  tearDown(() => db.close());

  final fmt = CurrencyFormatter(symbol: r'$ ', locale: 'en_US');
  String summaryOf(close, [String notes = '']) => buildShiftSummary(close,
      shopName: 'Shop', taxName: 'VAT', fmt: fmt, notes: notes);

  Future<int> sale(double total, DateTime when,
          {String method = 'cash', double tip = 0}) =>
      db.ordersDao.insertOrder(OrdersCompanion.insert(
        subtotal: total,
        total: total,
        tipAmount: Value(tip),
        paymentMethod: method,
        createdAt: Value(when),
      ));

  Future<void> closeAt(int id, DateTime at, {double counted = 0}) =>
      db.shiftsDao.closeShift(id,
          countedCash: counted, at: at, summary: (c) => summaryOf(c));

  final d = DateTime(2026, 6, 10);
  DateTime at(int h, [int m = 0]) => DateTime(d.year, d.month, d.day, h, m);

  group('open, preview, close through the DAO', () {
    test('the whole flow, with the frozen summary stored once', () async {
      final id = await svc.openTill(openingCash: 100, now: at(9));
      await sale(40, at(10));
      await sale(10, at(11), method: 'card');

      final preview = await db.shiftsDao
          .previewClose(id, at: at(18), paidOut: 5, countedCash: 133);
      expect(preview.expectedCash, 135); // 100 + 40 - 5
      expect(preview.overShortCents, -200);

      final calls = <int>[];
      final closed = await db.shiftsDao.closeShift(id,
          countedCash: 133,
          paidOut: 5,
          notes: 'Short by two',
          at: at(18), summary: (c) {
        calls.add(c.shiftId);
        return summaryOf(c, 'Short by two');
      });
      expect(calls, [id]); // built once
      expect(closed.overShortCents, -200);
      final row = (await db.shiftsDao.lastClosedShift())!;
      expect(row.summaryText, contains('Short by two'));
      expect(row.summaryText, contains('Short'));
      expect(row.countedCash, 133);
      expect(await db.shiftsDao.currentShift(), isNull);
    });

    test('opening cash defaults to the last close\'s counted cash', () async {
      final id = await svc.openTill(openingCash: 50, now: at(9));
      await closeAt(id, at(17), counted: 77.5);
      expect((await db.shiftsDao.lastClosedShift())!.countedCash, 77.5);
    });
  });

  group('history', () {
    test('newest first, with summaries', () async {
      var t = 8;
      for (var i = 0; i < 3; i++) {
        final id = await svc.openTill(openingCash: 0, now: at(t));
        await closeAt(id, at(t + 1), counted: i * 1.0);
        t += 2;
      }
      final rows = await db.shiftsDao.closedShifts();
      expect(rows.map((r) => r.countedCash), [2.0, 1.0, 0.0]);
      expect(rows.every((r) => (r.summaryText ?? '').isNotEmpty), isTrue);
    });
  });

  group('the gap rule is shown', () {
    test('no gap before the first-ever shift', () async {
      await sale(9, at(8));
      expect(await svc.gapBeforeOpen(now: at(9)), isNull);
    });

    test('activity while closed is counted and worded plainly', () async {
      final id = await svc.openTill(openingCash: 0, now: at(9));
      await closeAt(id, at(17));
      await sale(10, at(18));
      await sale(10, at(19));
      final gap = (await svc.gapBeforeOpen(now: at(20)))!;
      expect(gap.sales, 2);
      expect(gap.isLong, isFalse);
      expect(gap.canKeepSeparate, isFalse);
      expect(gapMessage(gap),
          '2 sales were made while the till was closed. They are included in this day.');
    });

    test('singular wording; nothing to say with no activity', () async {
      final id = await svc.openTill(openingCash: 0, now: at(9));
      await closeAt(id, at(17));
      expect(gapMessage(await svc.gapBeforeOpen(now: at(18))), isNull);
      await sale(10, at(18));
      expect(gapMessage(await svc.gapBeforeOpen(now: at(19))),
          '1 sale was made while the till was closed. It is included in this day.');
    });

    test('long: over 12 hours, or across a calendar day', () async {
      final id = await svc.openTill(openingCash: 0, now: at(9));
      await closeAt(id, at(10));
      await sale(10, at(11));
      expect((await svc.gapBeforeOpen(now: at(22)))!.isLong, isFalse);
      expect((await svc.gapBeforeOpen(now: at(22, 1)))!.isLong, isTrue);
      // Under 12 hours but past midnight.
      final id2 = await svc.openTill(openingCash: 0, now: at(22));
      await closeAt(id2, at(23));
      await sale(10, at(23, 30));
      final gap = (await svc.gapBeforeOpen(now: DateTime(2026, 6, 11, 1)))!;
      expect(gap.isLong, isTrue);
      expect(gap.canKeepSeparate, isTrue);
    });

    test('Keep them separate closes the gap as its own day', () async {
      final id = await svc.openTill(openingCash: 20, now: at(9));
      await closeAt(id, at(17), counted: 20);
      await sale(30, at(18));
      await sale(5, at(19), method: 'card');
      final next = DateTime(2026, 6, 11, 9);

      await svc.keepGapSeparate(now: next, summary: (c, n) => summaryOf(c, n));

      final rows = await db.shiftsDao.closedShifts();
      expect(rows.length, 2);
      final gapDay = rows.first;
      expect(gapDay.openedAt, next);
      expect(gapDay.closedAt, next);
      expect(gapDay.cashSales, 30);
      expect(gapDay.expectedCash, 50);
      expect(gapDay.countedCash, 50); // not counted: balanced
      expect(gapDay.notes, kGapCloseNote);
      expect(gapDay.summaryText, contains('Balanced'));

      // The gap is gone and the next day starts clean.
      expect((await svc.gapBeforeOpen(now: next))!.hasActivity, isFalse);
      final id3 = await svc.openTill(openingCash: 50, now: next);
      await sale(1, DateTime(2026, 6, 11, 10));
      final p =
          await db.shiftsDao.previewClose(id3, at: DateTime(2026, 6, 11, 18));
      expect(p.figures.sales.count, 1);
      expect(p.figures.cashSales, 1);
    });

    test('Keep them separate needs an earlier close', () async {
      expect(
          () => svc.keepGapSeparate(summary: (c, n) => ''), throwsA(anything));
    });
  });

  group('clock behind', () {
    test('opened_at is moved up to the previous close', () async {
      final id = await svc.openTill(openingCash: 0, now: at(9));
      await closeAt(id, at(17));
      final id2 = await svc.openTill(openingCash: 0, now: at(15)); // behind
      final open = (await db.shiftsDao.currentShift())!;
      expect(open.id, id2);
      expect(open.openedAt, at(17));
      // Windows stay contiguous.
      expect(await db.shiftsDao.windowStart(open), at(17));
    });

    test('a clock that is fine is left alone', () async {
      final id = await svc.openTill(openingCash: 0, now: at(9));
      await closeAt(id, at(17));
      await svc.openTill(openingCash: 0, now: at(18));
      expect((await db.shiftsDao.currentShift())!.openedAt, at(18));
    });

    test('the gap window never runs backwards', () async {
      final id = await svc.openTill(openingCash: 0, now: at(9));
      await closeAt(id, at(17));
      final gap = (await svc.gapBeforeOpen(now: at(15)))!;
      expect(gap.to, at(17));
      expect(gap.hasActivity, isFalse);
    });
  });

  group('tax name', () {
    test('default rate, else first active, else Tax', () async {
      expect(await svc.taxName(), 'Tax');
      final id = await db.taxDao
          .upsertRate(TaxRatesCompanion.insert(name: 'GST', rate: 0.1));
      expect(await svc.taxName(), 'GST');
      final vat = await db.taxDao
          .upsertRate(TaxRatesCompanion.insert(name: 'VAT', rate: 0.2));
      expect(await svc.taxName(defaultTaxId: vat), 'VAT');
      expect(await svc.taxName(defaultTaxId: id), 'GST');
    });
  });

  test('gap wording follows the counts: subject and verb agree', () {
    GapInfo g(int s, int r, int v) =>
        GapInfo(from: at(9), to: at(10), sales: s, refunds: r, voids: v);
    expect(gapMessage(g(1, 0, 0)),
        '1 sale was made while the till was closed. It is included in this day.');
    expect(gapMessage(g(0, 1, 0)),
        '1 refund or void was made while the till was closed. It is included in this day.');
    expect(gapMessage(g(0, 1, 1)),
        '2 refunds or voids were made while the till was closed. They are included in this day.');
    expect(gapMessage(g(3, 0, 1)),
        '3 sales and 1 refund or void were made while the till was closed. They are included in this day.');
    expect(gapMessage(g(0, 0, 0)), isNull);
  });
}
