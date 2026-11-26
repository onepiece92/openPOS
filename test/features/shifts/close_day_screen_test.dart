import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart' show XFile;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/utils/money.dart';
import 'package:pos_app/features/backup/data/share_files.dart';
import 'package:pos_app/features/printing/domain/receipt_printer.dart';
import 'package:pos_app/features/shifts/data/shift_service.dart';
import 'package:pos_app/features/shifts/presentation/close_day_screen.dart';
import 'package:pos_app/features/shifts/presentation/close_history_screen.dart';
import 'package:pos_app/features/shifts/presentation/shift_summary_panel.dart';
import 'package:pos_app/features/shifts/shift_settings.dart';
import 'package:pos_app/features/usage/usage_providers.dart';

import '../../_support/test_db.dart';

class _FakePrinter implements ReceiptPrinter {
  final slips = <({PrinterTarget target, List<String> lines, int paperMm})>[];
  Object? failWith;

  @override
  Stream<List<DiscoveredPrinter>> get devices => const Stream.empty();
  @override
  Future<void> startScan() async {}
  @override
  Future<void> stopScan() async {}
  @override
  Future<void> printReceipt(PrinterTarget target, ReceiptPrintJob job) async {}
  @override
  Future<void> printTestPage(PrinterTarget target,
      {required String storeName, required int paperMm}) async {}
  @override
  Future<void> printTextSlip(PrinterTarget target, List<String> lines,
      {required int paperMm}) async {
    if (failWith != null) throw failWith!;
    slips.add((target: target, lines: lines, paperMm: paperMm));
  }
}

void main() {
  late AppDatabase db;
  late Box<dynamic> box;
  late _FakePrinter printer;
  late List<List<XFile>> shared;
  late List<String> sharedBodies;
  late Directory tmp;
  late List<Uri> launched;

  setUp(() async {
    Hive.init('.');
    box = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
    await box.put(kCurrencySymbol, r'$');
    await box.put(kBusinessName, 'Corner Cafe');
    db = openInMemoryDatabase();
    printer = _FakePrinter();
    shared = [];
    sharedBodies = [];
    launched = [];
    tmp = Directory.systemTemp.createTempSync('pos_eod_');
  });
  tearDown(() async {
    await db.close();
    await Hive.close();
    tmp.deleteSync(recursive: true);
  });

  Future<int> order(double total, DateTime when,
          {String method = 'cash',
          String status = 'completed',
          DateTime? voidedAt}) =>
      db.ordersDao.insertOrder(OrdersCompanion.insert(
        subtotal: total,
        total: total,
        paymentMethod: method,
        status: Value(status),
        voidedAt: Value(voidedAt),
        createdAt: Value(when),
      ));

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2400);
    addTearDown(tester.view.reset);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => screen),
      GoRoute(
        path: kCloseDayHistoryRoute,
        builder: (_, __) => const CloseHistoryScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, s) =>
                CloseDetailScreen(shiftId: int.parse(s.pathParameters['id']!)),
          ),
        ],
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        settingsBoxProvider.overrideWithValue(box),
        receiptPrinterProvider.overrideWithValue(printer),
        shareFilesProvider.overrideWithValue((files,
            {String? subject,
            String? text,
            required Rect sharePositionOrigin}) async {
          sharedBodies.add(File(files.single.path).readAsStringSync());
          shared.add(files);
        }),
        linkLauncherProvider.overrideWithValue((uri) async {
          launched.add(uri);
          return true;
        }),
        usageTempDirProvider.overrideWithValue(() async => tmp),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> setPrinter() async {
    await box.put(kPrinterDeviceAddress, 'AA:BB');
    await box.put(kPrinterDeviceName, 'Counter printer');
    await box.put(kPrinterPaperWidth, '58');
  }

  Future<void> type(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(ValueKey(key)), text);
    await tester.pump();
  }

  group('no shift open', () {
    testWidgets('opening cash defaults to the last close; Open starts a day',
        (tester) async {
      final now = DateTime.now();
      final id = await db.shiftsDao.openShift(
          openingCash: 0, openedAt: now.subtract(const Duration(hours: 3)));
      await db.shiftsDao.closeShift(id,
          countedCash: 77.5,
          at: now.subtract(const Duration(hours: 2)),
          summary: (_) => 'old');
      await pump(tester, const CloseDayScreen());

      expect(find.text('Open the till'), findsOneWidget);
      final field = tester
          .widget<TextField>(find.byKey(const ValueKey('field-Opening cash')));
      expect(field.controller!.text, '77.50');
      expect(find.byKey(const ValueKey('gap-card')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('open-till')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Open since'), findsOneWidget);
      expect((await db.shiftsDao.currentShift())!.openingCash, 77.5);
    });

    testWidgets('the first day ever says so; later days say the till rule',
        (tester) async {
      await pump(tester, const CloseDayScreen());
      expect(find.text(kFirstDayNote), findsOneWidget);
      expect(find.text(kTillClosedNote), findsNothing);
      await tester.tap(find.byKey(const ValueKey('open-till')));
      await tester.pumpAndSettle();
      final id = (await db.shiftsDao.currentShift())!.id;
      await db.shiftsDao.closeShift(id, countedCash: 0, summary: (_) => 'x');
      await pump(tester, const CloseDayScreen());
      expect(find.text(kTillClosedNote), findsOneWidget);
      expect(find.text(kFirstDayNote), findsNothing);
    });

    testWidgets('a clock behind the last close is called out',
        (tester) async {
      final now = DateTime.now();
      final id = await db.shiftsDao.openShift(
          openingCash: 0, openedAt: now.subtract(const Duration(hours: 1)));
      // Closed "in the future": the clock has since gone back.
      await db.shiftsDao.closeShift(id,
          countedCash: 0,
          at: now.add(const Duration(hours: 2)),
          summary: (_) => 'x');
      await pump(tester, const CloseDayScreen());
      expect(find.text(kClockBehindNote), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('open-till')));
      await tester.pumpAndSettle();
      // The new day opens at the last close; the clock is still behind it.
      expect(find.textContaining('Open since'), findsOneWidget);
      expect(find.text(kClockBehindNote), findsOneWidget);
    });

    testWidgets('a short gap with sales says so, with no separate offer',
        (tester) async {
      final now = DateTime.now();
      final id = await db.shiftsDao.openShift(
          openingCash: 0, openedAt: now.subtract(const Duration(minutes: 90)));
      await db.shiftsDao.closeShift(id,
          countedCash: 0,
          at: now.subtract(const Duration(minutes: 60)),
          summary: (_) => 'old');
      await order(5, now.subtract(const Duration(minutes: 30)));
      await order(5, now.subtract(const Duration(minutes: 20)));
      await pump(tester, const CloseDayScreen());
      expect(
          tester.widget<Text>(find.byKey(const ValueKey('gap-message'))).data,
          '2 sales were made while the till was closed. They are included in this day.');
      expect(find.byKey(const ValueKey('keep-separate')), findsNothing);
    });

    testWidgets('a long gap offers Keep them separate, and it works',
        (tester) async {
      final now = DateTime.now();
      final id = await db.shiftsDao.openShift(
          openingCash: 10, openedAt: now.subtract(const Duration(days: 3)));
      await db.shiftsDao.closeShift(id,
          countedCash: 10,
          at: now.subtract(const Duration(days: 2)),
          summary: (_) => 'old');
      await order(20, now.subtract(const Duration(days: 1)));
      await pump(tester, const CloseDayScreen());
      expect(find.byKey(const ValueKey('keep-separate')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('keep-separate')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('gap-card')), findsNothing);
      // The gap day was not counted: the opening cash is its expected cash
      // (10 + 20), and the screen says so.
      expect(
          tester
              .widget<TextField>(
                  find.byKey(const ValueKey('field-Opening cash')))
              .controller!
              .text,
          '30.00');
      expect(find.text('Expected cash from the last day (not counted)'),
          findsOneWidget);
      final closes = await db.shiftsDao.closedShifts();
      expect(closes.length, 2);
      expect(closes.first.countedCash, isNull);
      expect(await db.shiftsDao.currentShift(), isNull);
    });
  });

  group('shift open', () {
    Future<int> openDay({double opening = 100}) => db.shiftsDao.openShift(
        openingCash: opening,
        openedAt: DateTime.now().subtract(const Duration(hours: 3)));

    testWidgets('a day open over 24 hours says how long; a fresh one does not',
        (tester) async {
      await db.shiftsDao.openShift(
          openingCash: 0,
          openedAt: DateTime.now().subtract(const Duration(days: 3, hours: 1)));
      await pump(tester, const CloseDayScreen());
      expect(find.text('This day has been open for 3 days.'), findsOneWidget);
      expect(find.text(kClockBehindNote), findsNothing);
    });

    testWidgets('no long-open line for a day open a few hours', (tester) async {
      await openDay();
      await pump(tester, const CloseDayScreen());
      expect(find.byKey(const ValueKey('long-open-note')), findsNothing);
    });

    testWidgets(
        'tips taken, then Tips switched off: the close still counts them',
        (tester) async {
      await box.put(kFeaturesKey, {'tips': true});
      await openDay();
      final when = DateTime.now().subtract(const Duration(hours: 1));
      await db.ordersDao.insertOrder(OrdersCompanion.insert(
        subtotal: 40,
        total: 40,
        tipAmount: const Value(6),
        paymentMethod: 'cash',
        createdAt: Value(when),
      ));
      await box.put(kFeaturesKey, {'tips': false});
      await pump(tester, const CloseDayScreen());

      // 100 opening + 40 sale + 6 cash tip.
      expect(tester.widget<Text>(find.byKey(const ValueKey('expected'))).data,
          r'$ 146.00');
      expect(find.text('Cash tips'), findsOneWidget);

      await type(tester, 'field-Counted cash', '146');
      await tester.tap(find.byKey(const ValueKey('close-day')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-close')));
      await tester.pumpAndSettle();

      final closed = (await db.shiftsDao.lastClosedShift())!;
      expect(closed.expectedCash, 146);
      expect(closed.cashTips, 6);
      final lines = closed.summaryText!.split('\n');
      expect(lines.where((l) => l.startsWith('+ Cash tips')), hasLength(1));
      expect(lines.where((l) => l.startsWith('Tips (net)')), hasLength(1));
      expect(find.textContaining('Tips (net)'), findsOneWidget);
    });

    testWidgets('live figures; over, short and balanced are read in cents',
        (tester) async {
      await openDay();
      await order(40, DateTime.now().subtract(const Duration(hours: 1)));
      await pump(tester, const CloseDayScreen());

      expect(find.textContaining('Open since'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const ValueKey('expected'))).data,
          r'$ 140.00');
      expect(find.text('Cash tips'), findsNothing); // zero: hidden
      expect(
          tester
              .widget<FilledButton>(find.byKey(const ValueKey('close-day')))
              .onPressed,
          isNull); // needs a count

      await type(tester, 'field-Counted cash', '140.01');
      expect(find.text('Over'), findsOneWidget);
      await type(tester, 'field-Counted cash', '139.99');
      expect(find.text('Short'), findsOneWidget);
      await type(tester, 'field-Counted cash', '140');
      expect(find.text('Balanced'), findsOneWidget);
      await type(tester, 'field-Paid out', '10');
      expect(find.text('Over'), findsOneWidget); // expected is now 130
      expect(tester.widget<Text>(find.byKey(const ValueKey('over-short'))).data,
          r'$ 10.00');
    });

    testWidgets('a sale made after the screen loaded is in the confirm dialog',
        (tester) async {
      await openDay();
      await pump(tester, const CloseDayScreen());
      expect(tester.widget<Text>(find.byKey(const ValueKey('expected'))).data,
          r'$ 100.00');
      await order(25, DateTime.now().subtract(const Duration(minutes: 1)));
      await type(tester, 'field-Counted cash', '120');
      await tester.tap(find.byKey(const ValueKey('close-day')));
      await tester.pumpAndSettle();
      expect(find.textContaining(r'Expected cash $ 125.00'), findsOneWidget);
      expect(find.textContaining(r'Short $ 5.00'), findsOneWidget);
      // The screen behind the dialog kept the fresh figures too.
      expect(tester.widget<Text>(find.byKey(const ValueKey('expected'))).data,
          r'$ 125.00');
    });

    testWidgets('a comma works as the decimal separator', (tester) async {
      await openDay();
      await pump(tester, const CloseDayScreen());
      await type(tester, 'field-Counted cash', '99,5');
      expect(find.text('Short'), findsOneWidget);
      expect(parseMoneyField('12,5'), 12.5);
      expect(parseMoneyField('abc'), isNull);
    });

    testWidgets('an ambiguous amount is refused with the example, never '
        'misread', (tester) async {
      await openDay();
      await pump(tester, const CloseDayScreen());
      for (final bad in ['1,234', '1.234,50', '1,234.50', '12.345']) {
        await type(tester, 'field-Counted cash', bad);
        expect(find.text(kMoneyInputHint), findsOneWidget, reason: bad);
        expect(
            tester
                .widget<FilledButton>(find.byKey(const ValueKey('close-day')))
                .onPressed,
            isNull,
            reason: bad);
      }
      await type(tester, 'field-Counted cash', '1234.50');
      expect(find.text(kMoneyInputHint), findsNothing);
      expect(find.text('Over'), findsOneWidget);
    });

    testWidgets('a void of an earlier day\'s sale explains the negative net',
        (tester) async {
      await openDay();
      final now = DateTime.now();
      await order(30, now.subtract(const Duration(days: 2)),
          status: 'voided', voidedAt: now.subtract(const Duration(hours: 1)));
      await pump(tester, const CloseDayScreen());
      expect(find.byKey(const ValueKey('below-zero-note')), findsOneWidget);
      expect(find.text(kBelowZeroNote), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const ValueKey('net-sales'))).data,
          r'-$ 30.00');
    });

    testWidgets(
        'close with confirm shows the frozen summary; Print, Share, '
        'Copy, Email work', (tester) async {
      await setPrinter();
      await openDay();
      await order(40, DateTime.now().subtract(const Duration(hours: 1)));
      await pump(tester, const CloseDayScreen());
      await type(tester, 'field-Counted cash', '138');
      await type(tester, 'notes', 'Two short');
      await tester.tap(find.byKey(const ValueKey('close-day')));
      await tester.pumpAndSettle();
      expect(find.text('Close day?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm-close')));
      await tester.pumpAndSettle();

      expect(find.text('Day closed'), findsOneWidget);
      final text = tester
          .widget<SelectableText>(find.byKey(const ValueKey('summary-text')))
          .data!;
      expect(text, contains('Corner Cafe'));
      expect(text, contains(r'$ 140.00')); // expected
      expect(text, contains('Short'));
      expect(text.split('\n').firstWhere((l) => l.startsWith('Short')),
          endsWith(r'$ 2.00'));
      expect(text, contains('Two short'));
      final stored = (await db.shiftsDao.lastClosedShift())!;
      expect(stored.summaryText, text);
      expect(text.split('\n').every((l) => l.length <= 32), isTrue); // 58mm

      // Print: the same lines, on the saved printer and paper.
      await tester.tap(find.byKey(const ValueKey('summary-print')));
      await tester.pumpAndSettle();
      expect(printer.slips.single.lines, text.split('\n'));
      expect(printer.slips.single.target.address, 'AA:BB');
      expect(printer.slips.single.paperMm, 58);

      // Share: the text, as a .txt file.
      await tester.tap(find.byKey(const ValueKey('summary-share')));
      await tester.pumpAndSettle();
      expect(sharedBodies.single, text);

      // Email: a mailto link carrying the text.
      await tester.tap(find.byKey(const ValueKey('summary-email')));
      await tester.pumpAndSettle();
      expect(launched.single.scheme, 'mailto');
      expect(launched.single.queryParameters['body'], contains('Two short'));

      // Copy.
      String? copied;
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      await tester.tap(find.byKey(const ValueKey('summary-copy')));
      await tester.pumpAndSettle();
      expect(copied, text);

      await tester.tap(find.byKey(const ValueKey('done')));
      await tester.pumpAndSettle();
      expect(find.text('Open the till'), findsOneWidget);
    });

    testWidgets('a printer failure is shown, never silent; no printer says so',
        (tester) async {
      await openDay();
      final id = (await db.shiftsDao.currentShift())!.id;
      await db.shiftsDao.closeShift(id, countedCash: 1, summary: (_) => 'x\ny');
      await pump(tester, const CloseHistoryScreen());
      await tester.tap(find.byKey(ValueKey('history-$id')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('summary-print')));
      await tester.pumpAndSettle();
      expect(find.text(kNoPrinterMessage), findsOneWidget);
      expect(printer.slips, isEmpty);

      await setPrinter();
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
          .read(settingsProvider.notifier)
          .reload();
      printer.failWith = StateError('Counter printer: could not connect');
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.byKey(const ValueKey('summary-print')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Print failed'), findsOneWidget);
      expect(find.textContaining('could not connect'), findsOneWidget);
    });
  });

  group('history', () {
    testWidgets('a bad or open id says the close was not found',
        (tester) async {
      await pump(tester, const CloseDetailScreen(shiftId: null));
      expect(find.text('This close was not found.'), findsOneWidget);
    });

    testWidgets('an open shift is not shown as a close', (tester) async {
      final id = await db.shiftsDao.openShift(openingCash: 0);
      await pump(tester, CloseDetailScreen(shiftId: id));
      expect(find.text('This close was not found.'), findsOneWidget);
    });

    testWidgets(
        'newest first with range, net sales and over/short; tap opens '
        'the frozen summary', (tester) async {
      final base = DateTime(2026, 6, 10);
      DateTime t(int d, int h) => base.add(Duration(days: d, hours: h));
      final a = await db.shiftsDao.openShift(openingCash: 0, openedAt: t(0, 9));
      await order(25, t(0, 10));
      await db.shiftsDao.closeShift(a,
          countedCash: 25, at: t(0, 17), summary: (_) => 'FIRST DAY');
      final b =
          await db.shiftsDao.openShift(openingCash: 25, openedAt: t(1, 9));
      await order(10, t(1, 10));
      await db.shiftsDao.closeShift(b,
          countedCash: 34, at: t(1, 17), summary: (_) => 'SECOND DAY');

      await pump(tester, const CloseHistoryScreen());
      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(tiles.length, 2);
      expect((tiles.first.subtitle as Text).data,
          r'Net sales $ 10.00  ·  Short $ 1.00');
      expect((tiles.last.subtitle as Text).data,
          r'Net sales $ 25.00  ·  Balanced');
      // Each row shows its real window: the second day starts where the
      // first one closed, not at its own opening.
      expect((tiles.first.title as Text).data,
          '10 Jun 2026 17:00 to 11 Jun 2026 17:00');
      expect((tiles.last.title as Text).data, '10 Jun 2026, 09:00 to 17:00');

      await tester.tap(find.byKey(ValueKey('history-$a')));
      await tester.pumpAndSettle();
      expect(find.text('FIRST DAY'), findsOneWidget);
      expect(find.byKey(const ValueKey('summary-print')), findsOneWidget);
      expect(find.byKey(const ValueKey('summary-share')), findsOneWidget);
    });

    testWidgets('an uncounted close says Not counted, never a 0.00 over/short',
        (tester) async {
      final base = DateTime(2026, 6, 10);
      final a = await db.shiftsDao
          .openShift(openingCash: 5, openedAt: base.add(const Duration(hours: 9)));
      await order(12, base.add(const Duration(hours: 10)));
      await db.shiftsDao.closeShift(a,
          countedCash: null,
          at: base.add(const Duration(hours: 17)),
          summary: (_) => 'GAP DAY');
      await pump(tester, const CloseHistoryScreen());
      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect((tile.subtitle as Text).data,
          r'Net sales $ 12.00  ·  Not counted');
      expect(find.textContaining('Balanced'), findsNothing);
      expect(find.textContaining('0.00 '), findsNothing);
    });

    testWidgets('net sales are the frozen figure, not a recompute',
        (tester) async {
      final base = DateTime(2026, 6, 10);
      final a = await db.shiftsDao
          .openShift(openingCash: 0, openedAt: base.add(const Duration(hours: 9)));
      final o = await order(25, base.add(const Duration(hours: 10)));
      await db.shiftsDao.closeShift(a,
          countedCash: 25,
          at: base.add(const Duration(hours: 17)),
          summary: (_) => 'DAY');
      // Edit the order behind the close's back: history must not move.
      await (db.update(db.orders)..where((r) => r.id.equals(o)))
          .write(const OrdersCompanion(total: Value(99)));
      await pump(tester, const CloseHistoryScreen());
      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect((tile.subtitle as Text).data, r'Net sales $ 25.00  ·  Balanced');
    });

    testWidgets('a close with no stored net sales shows "-"', (tester) async {
      final base = DateTime(2026, 6, 10);
      final a = await db.shiftsDao
          .openShift(openingCash: 0, openedAt: base.add(const Duration(hours: 9)));
      await db.shiftsDao.closeShift(a,
          countedCash: 0,
          at: base.add(const Duration(hours: 17)),
          summary: (_) => 'DAY');
      await (db.update(db.shifts)..where((r) => r.id.equals(a)))
          .write(const ShiftsCompanion(netSales: Value(null)));
      await pump(tester, const CloseHistoryScreen());
      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect((tile.subtitle as Text).data, r'Net sales -  ·  Balanced');
    });

    testWidgets('empty history says so', (tester) async {
      await pump(tester, const CloseHistoryScreen());
      expect(find.text('No days have been closed yet.'), findsOneWidget);
    });
  });
}
