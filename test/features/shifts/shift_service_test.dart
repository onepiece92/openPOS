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
      expect(gapDay.openingCash, 20); // the counted close before it
      expect(gapDay.expectedCash, 50);
      expect(gapDay.countedCash, isNull); // not counted
      expect(gapDay.netSales, 35);
      expect(gapDay.notes, kGapCloseNote);
      final text = gapDay.summaryText!;
      expect(
          text.split('\n'),
          contains(predicate<String>((l) =>
              l.startsWith('Counted cash') && l.endsWith('Not counted'))));
      for (final word in ['Balanced', 'Over', 'Short']) {
        expect(text, isNot(contains(word)), reason: word);
      }

      // The gap is gone; the next day opens from the gap's expected cash.
      expect((await svc.gapBeforeOpen(now: next))!.hasActivity, isFalse);
      final suggested = (await svc.suggestedOpeningCash())!;
      expect(suggested.amount, 50);
      expect(suggested.fromUncounted, isTrue);
      expect(suggested.note, 'Expected cash from the last day (not counted)');
      final id3 = await svc.openTill(openingCash: 50, now: next);
      await sale(1, DateTime(2026, 6, 11, 10));
      final p =
          await db.shiftsDao.previewClose(id3, at: DateTime(2026, 6, 11, 18));
      expect(p.figures.sales.count, 1);
      expect(p.figures.cashSales, 1);
    });

    test('opening cash: the last counted close, else nothing', () async {
      expect(await svc.suggestedOpeningCash(), isNull);
      final id = await svc.openTill(openingCash: 10, now: at(9));
      await sale(7, at(10));
      await closeAt(id, at(17), counted: 16.5);
      final s = (await svc.suggestedOpeningCash())!;
      expect(s.amount, 16.5);
      expect(s.fromUncounted, isFalse);
      expect(s.note, kOpeningFromCountedNote);
    });

    test('a counted close after an uncounted one is used again', () async {
      final id = await svc.openTill(openingCash: 10, now: at(9));
      await closeAt(id, at(12), counted: 10);
      await sale(5, at(13));
      await svc.keepGapSeparate(
          now: DateTime(2026, 6, 11, 9), summary: (c, n) => summaryOf(c, n));
      expect((await svc.suggestedOpeningCash())!.amount, 15);
      expect((await db.shiftsDao.lastCountedShift())!.id, id);

      final id3 =
          await svc.openTill(openingCash: 15, now: DateTime(2026, 6, 11, 9));
      await db.shiftsDao.closeShift(id3,
          countedCash: 14,
          at: DateTime(2026, 6, 11, 17),
          summary: (c) => summaryOf(c));
      final s = (await svc.suggestedOpeningCash())!;
      expect(s.amount, 14);
      expect(s.fromUncounted, isFalse);
      expect((await db.shiftsDao.lastCountedShift())!.id, id3);
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

    test('a sale stamped before the last close (clock back while a day is '
        'open) is in neither day, never counted', () async {
      final id = await svc.openTill(openingCash: 0, now: at(9));
      await sale(10, at(10));
      await closeAt(id, at(17), counted: 10);
      final id2 = await svc.openTill(openingCash: 10, now: at(18));
      // The clock is moved back to 16:00 and a sale is made.
      await sale(7, at(16));
      final first = (await db.shiftsDao.closedShifts()).single;
      expect(first.cashSales, 10); // frozen at its close
      final c = await db.shiftsDao.closeShift(id2,
          countedCash: 10, at: at(16, 30), summary: (c) => summaryOf(c));
      // Clamped to its opening: an empty window, nothing double-counted.
      expect(c.figures.to, at(18));
      expect(c.figures.sales.count, 0);
      expect(c.expectedCash, 10);
      expect(clockBehindNote(at(16, 30), at(17)), kClockBehindNote);
    });

    test('a sale stamped before the first day ever opened is in no day',
        () async {
      await sale(9, at(8));
      final id = await svc.openTill(openingCash: 0, now: at(9));
      await sale(4, at(10));
      final c = await db.shiftsDao.closeShift(id,
          countedCash: 4, at: at(17), summary: (c) => summaryOf(c));
      expect(c.figures.from, at(9));
      expect(c.figures.cashSales, 4);
    });

    test('the clock note shows only when now is before the window start', () {
      expect(clockBehindNote(at(16), at(17)), kClockBehindNote);
      expect(clockBehindNote(at(17), at(17)), isNull);
      expect(clockBehindNote(at(18), at(17)), isNull);
      expect(clockBehindNote(at(16), null), isNull);
    });

    test('the gap window never runs backwards', () async {
      final id = await svc.openTill(openingCash: 0, now: at(9));
      await closeAt(id, at(17));
      final gap = (await svc.gapBeforeOpen(now: at(15)))!;
      expect(gap.to, at(17));
      expect(gap.hasActivity, isFalse);
    });
  });

  group('long-open note', () {
    final start = DateTime(2026, 6, 10, 9);
    String? note(Duration d) => longOpenNote(start, start.add(d));

    test('nothing up to 24 hours', () {
      expect(note(const Duration(hours: 5)), isNull);
      expect(note(const Duration(hours: 24)), isNull);
    });

    test('hours under 2 days, days after', () {
      expect(note(const Duration(hours: 25)),
          'This day has been open for 25 hours.');
      expect(note(const Duration(hours: 47, minutes: 59)),
          'This day has been open for 47 hours.');
      expect(note(const Duration(days: 2)), 'This day has been open for 2 days.');
      expect(note(const Duration(days: 9, hours: 3)),
          'This day has been open for 9 days.');
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
