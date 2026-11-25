import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/backup/data/backup_repository.dart';
import 'package:pos_app/features/backup/data/share_files.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/presentation/backup_screen.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';
import 'package:pos_app/features/receipts/presentation/receipt_pdf_service.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// On iPad the share sheet is a popover, and share_plus 10.1.4 fails the
/// share ("sharePositionOrigin: argument must be set…") unless it is given a
/// non-empty rectangle inside the app's view. CSV export and the zip backup
/// passed none, so on iPad they ended in "Export failed".
///
/// These tests check that every share entry point hands over the rectangle
/// of the widget that was tapped. They do not run share_plus's iOS code:
/// that an iPad then shows the sheet can only be confirmed on an iPad.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// path_provider has no platform side under `flutter test`.
  void mockTempDirectory(Directory dir) {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async => dir.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  }

  const ipad = Size(1024, 1366);
  // Short enough that the lower tiles have to be scrolled into view.
  const small = Size(600, 700);

  void expectUsable(Rect? r, Size screen) {
    expect(r, isNotNull);
    expect(r!.isEmpty, isFalse, reason: '$r is empty');
    expect(r.left >= 0 && r.top >= 0, isTrue, reason: '$r off screen');
    expect(r.right <= screen.width && r.bottom <= screen.height, isTrue,
        reason: '$r outside $screen');
  }

  group('BackupRepository exports', () {
    late AppDatabase db;
    late Directory tmp;
    final shared = <({List<XFile> files, Rect origin})>[];
    late BackupRepository repo;

    setUp(() async {
      db = openInMemoryDatabase();
      tmp = await Directory.systemTemp.createTemp('pos_share_');
      shared.clear();
      repo = BackupRepository(
        db,
        share: (files, {subject, text, required sharePositionOrigin}) async =>
            shared.add((files: files, origin: sharePositionOrigin)),
        tempDirectory: () async => tmp,
      );
    });
    tearDown(() async {
      await db.close();
      await tmp.delete(recursive: true);
    });

    const origin = Rect.fromLTWH(16, 300, 992, 92);
    final exports = <String, Future<void> Function()>{
      'products_backup.csv': () => repo.exportProducts(shareOrigin: origin),
      'customers_backup.csv': () => repo.exportCustomers(shareOrigin: origin),
      'expenses_backup.csv': () => repo.exportExpenses(shareOrigin: origin),
      'order_history_backup.csv': () =>
          repo.exportOrders(shareOrigin: origin),
      'sales_report.csv': () => repo.exportSalesReport(shareOrigin: origin),
    };

    for (final entry in exports.entries) {
      test('${entry.key} is shared with the origin it was given', () async {
        await entry.value();
        expect(shared, hasLength(1));
        expect(shared.single.origin, origin);
        expect(shared.single.files.single.path, endsWith(entry.key));
        expect(File(shared.single.files.single.path).existsSync(), isTrue);
      });
    }

    test('the provider wires in the share function', () async {
      Rect? got;
      final c = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        shareFilesProvider.overrideWithValue(
            (files, {subject, text, required sharePositionOrigin}) async =>
                got = sharePositionOrigin),
      ]);
      addTearDown(c.dispose);
      mockTempDirectory(tmp);
      await c
          .read(backupRepositoryProvider)
          .exportProducts(shareOrigin: origin);
      expect(got, origin);
    });
  });

  test('the zip backup is created and shared with the origin it was given',
      () async {
    final db = openInMemoryDatabase();
    final tmp = await Directory.systemTemp.createTemp('pos_share_zip_');
    addTearDown(() async {
      await db.close();
      await tmp.delete(recursive: true);
    });
    mockTempDirectory(tmp);
    final shared = <({List<XFile> files, String? subject, Rect origin})>[];
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      shareFilesProvider.overrideWithValue(
          (files, {subject, text, required sharePositionOrigin}) async =>
              shared.add((
                files: files,
                subject: subject,
                origin: sharePositionOrigin
              ))),
    ]);
    addTearDown(c.dispose);

    const origin = Rect.fromLTWH(960, 30, 48, 48);
    final zip = await c
        .read(snapshotCoordinatorProvider)
        .createAndShare(shareOrigin: origin);

    expect(zip.existsSync(), isTrue);
    expect(shared.single.origin, origin);
    expect(shared.single.files.single.path, zip.path);
    expect(shared.single.subject, endsWith('.zip'));
  });

  group('BackupScreen', () {
    late Directory tmp;
    late Box<dynamic> settingsBox;
    late AppDatabase db;
    late _RecordingRepo repo;
    final snapshotOrigins = <Rect>[];

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('pos_share_ui_');
      Hive.init(tmp.path);
      settingsBox =
          await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
      db = openInMemoryDatabase();
      repo = _RecordingRepo(db);
      snapshotOrigins.clear();
    });
    tearDown(() async {
      await db.close();
      await Hive.close();
      await tmp.delete(recursive: true);
    });

    Future<void> pumpScreen(WidgetTester tester, Size screen) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = screen * 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          settingsBoxProvider.overrideWithValue(settingsBox),
          backupRepositoryProvider.overrideWithValue(repo),
          snapshotCoordinatorProvider.overrideWith(
              (ref) => _RecordingCoordinator(ref, snapshotOrigins)),
        ],
        child: const MaterialApp(home: BackupScreen()),
      ));
    }

    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      // Let the "exported" snackbar run its course.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }

    for (final screen in [ipad, small]) {
      for (final title in const [
        'Export Products',
        'Export Customers',
        'Export Expenses',
        'Export Order History',
        'Export Sales Report',
      ]) {
        testWidgets('$title passes its tile as the origin ($screen)',
            (tester) async {
          await pumpScreen(tester, screen);
          await tester.scrollUntilVisible(find.text(title), 200);
          await tester.pumpAndSettle();
          final tile = tester.getRect(
              find.ancestor(of: find.text(title), matching: find.byType(Card)));

          await tester.tap(find.text(title));
          await settle(tester);

          expect(repo.origins.keys, [title]);
          final origin = repo.origins[title];
          expectUsable(origin, screen);
          expect(origin!.overlaps(tile), isTrue,
              reason: '$origin is not on the tile $tile');
          expect(tile.contains(origin.center), isTrue);
        });
      }

      testWidgets('auto-backup tile says photos are not included ($screen)',
          (tester) async {
        await pumpScreen(tester, screen);
        final note = find.text(kAutoBackupNoPhotosNote);
        await tester.scrollUntilVisible(note, 200);
        expect(note, findsOneWidget);
        expect(
            find.ancestor(
                of: note,
                matching: find.ancestor(
                    of: find.text('Device backups'),
                    matching: find.byType(Card))),
            findsOneWidget);
      });

      testWidgets('"Back up everything" tile passes its rectangle ($screen)',
          (tester) async {
        await pumpScreen(tester, screen);
        final tile = tester.getRect(find.ancestor(
            of: find.text('Back up everything'), matching: find.byType(Card)));

        await tester.tap(find.text('Back up everything'));
        await settle(tester);

        expectUsable(snapshotOrigins.single, screen);
        expect(tile.contains(snapshotOrigins.single.center), isTrue);
      });

      testWidgets('the app-bar backup button passes its rectangle ($screen)',
          (tester) async {
        await pumpScreen(tester, screen);
        final button = find.byTooltip('Back up everything');

        await tester.tap(button);
        await settle(tester);

        expectUsable(snapshotOrigins.single, screen);
        expect(snapshotOrigins.single,
            tester.getRect(find.byType(IconButton)));
      });
    }
  });

  testWidgets('the receipt PDF is shared with the tapped button as bounds',
      (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = ipad * 2;
    addTearDown(tester.view.reset);

    final db = openInMemoryDatabase();
    addTearDown(db.close);
    late ReceiptBodyData data;
    await tester.runAsync(() async {
      final p = await seedProduct(db, sku: 'TEA', stock: 0);
      final id = await sell(db, AuditService(db), [line(p)]);
      data = ReceiptBodyData(
        order: (await db.ordersDao.getById(id))!,
        items: await db.ordersDao.getItems(id),
        taxes: await db.ordersDao.getTaxBreakdown(id),
        businessName: 'Chiya Pasal',
      );
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ]),
      ),
    ));
    final button = find.byType(IconButton);

    Rect? got;
    String? name;
    await tester.runAsync(() => downloadReceiptPdf(
          tester.element(button),
          data,
          CurrencyFormatter(symbol: 'Rs ', locale: 'en_US'),
          sharePdf: ({required bytes, filename = '', bounds}) async {
            expect(bytes, isNotEmpty);
            got = bounds;
            name = filename;
            return true;
          },
        ));

    expect(name, endsWith('.pdf'));
    expectUsable(got, ipad);
    expect(got, tester.getRect(button));
  });
}

class _RecordingRepo extends BackupRepository {
  _RecordingRepo(super.db);
  final origins = <String, Rect>{};

  @override
  Future<void> exportProducts({required Rect shareOrigin}) async =>
      origins['Export Products'] = shareOrigin;
  @override
  Future<void> exportCustomers({required Rect shareOrigin}) async =>
      origins['Export Customers'] = shareOrigin;
  @override
  Future<void> exportExpenses({required Rect shareOrigin}) async =>
      origins['Export Expenses'] = shareOrigin;
  @override
  Future<void> exportOrders({required Rect shareOrigin}) async =>
      origins['Export Order History'] = shareOrigin;
  @override
  Future<void> exportSalesReport({required Rect shareOrigin}) async =>
      origins['Export Sales Report'] = shareOrigin;
}

class _RecordingCoordinator extends SnapshotCoordinator {
  _RecordingCoordinator(super.ref, this.origins);
  final List<Rect> origins;

  @override
  Future<File> createAndShare({required Rect shareOrigin}) async {
    origins.add(shareOrigin);
    return File('unused.zip');
  }
}
