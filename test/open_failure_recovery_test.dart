import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/app.dart';
import 'package:pos_app/app_root.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/connection/native.dart';
import 'package:pos_app/core/database/database_open_errors.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/backup/data/open_failure_recovery.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';

import '_support/sales.dart';
import 'app_root_retry_test.dart' show pumpUntil;

/// The "Open POS couldn't open its data." screen offers ways out besides
/// Try again: restore an automatic backup (picked, newest first, the normal
/// journaled restore) or a confirmed "Start fresh". Never automatic.
void main() {
  late Directory docs;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  File dbFile() => File(p.join(docs.path, kDatabaseFileName));
  Directory autoDir() => Directory(p.join(docs.path, 'backups', 'auto'));

  setUp(() {
    docs = Directory.systemTemp.createTempSync('pos_open_fail_');
    Hive.init(docs.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => docs.path);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await Hive.close();
    docs.deleteSync(recursive: true);
  });

  Future<void> openBoxes({bool onboarded = true}) async {
    for (final b in kSnapshotHiveBoxes) {
      await Hive.openBox<dynamic>(b);
    }
    if (onboarded) {
      await Hive.box<dynamic>('settings').put(kOnboardingCompleteKey, true);
    }
  }

  Future<void> done(WidgetTester tester) => tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox());
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });

  group('helpers', () {
    test('setAsideDatabaseFile moves the file and its journals, keeps them',
        () async {
      dbFile().writeAsStringSync('broken');
      File('${dbFile().path}-wal').writeAsStringSync('wal');
      final moved =
          await setAsideDatabaseFile(dbFile(), DateTime(2026, 11, 26, 9, 5));
      expect(dbFile().existsSync(), isFalse);
      expect(File('${dbFile().path}-wal').existsSync(), isFalse,
          reason: 'a stale WAL must never meet the new database');
      expect(
          p.basename(moved!.path), '$kDatabaseFileName.broken-20261126-090500');
      expect(moved.readAsStringSync(), 'broken');
      expect(File('${moved.path}-wal').existsSync(), isTrue);
    });

    test('listAutoBackups: newest first, labelled with dates', () async {
      autoDir().createSync(recursive: true);
      final older = DateTime(2026, 11, 1, 9);
      final newer = DateTime(2026, 11, 3, 18, 30);
      File(p.join(autoDir().path, 'pos_backup_a.zip'))
        ..writeAsBytesSync([1])
        ..setLastModifiedSync(older);
      File(p.join(autoDir().path, 'pos_backup_b.zip'))
        ..writeAsBytesSync([1])
        ..setLastModifiedSync(newer);
      final list = await listAutoBackups();
      expect([for (final b in list) b.$2], [newer, older]);
      // (intl puts a narrow no-break space before AM/PM.)
      final label = autoBackupLabel(newer, newest: true);
      expect(label, startsWith('Nov 3, 2026 6:30'));
      expect(label, endsWith('PM (newest)'));
      final plain = autoBackupLabel(older, newest: false);
      expect(plain, startsWith('Nov 1, 2026 9:00'));
      expect(plain, isNot(contains('newest')));
    });
  });

  group('the screen', () {
    testWidgets('a newer-app file offers neither (nothing to fix here)',
        (tester) async {
      await tester
          .pumpWidget(AppRoot(startupDbError: DatabaseTooNewError(99, 16)));
      expect(find.text(kRestoreLatestBackupButton), findsNothing);
      expect(find.text(kStartFreshButton), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    // The classification: only a missing/empty or damaged FILE gets the
    // two exits; anything that may happen to a healthy file does not.
    final damaged = <(String, Object)>[
      ('missing', DatabaseMissingError('x')),
      ('0-byte (same error)', DatabaseMissingError('empty')),
      ('NOTADB (26)', SqliteException(26, 'file is not a database')),
      ('CORRUPT (11)', SqliteException(11, 'database disk image is malformed')),
      ('CORRUPT_VTAB (267)', SqliteException(267, 'corrupt vtab')),
      ('CORRUPT_INDEX (779)', SqliteException(779, 'corrupt index')),
      (
        'NOTADB across the isolate (text only)',
        Exception('SqliteException(26): file is not a database')
      ),
    ];
    final notDamaged = <(String, Object)>[
      (
        'BUSY (5, "database is locked")',
        SqliteException(5, 'database is locked')
      ),
      ('LOCKED (6)', SqliteException(6, 'database table is locked')),
      ('I/O error (10)', SqliteException(10, 'disk I/O error')),
      ('IOERR_SHORT_READ (522)', SqliteException(522, 'short read')),
      ('FULL (13)', SqliteException(13, 'database or disk is full')),
      ('CANTOPEN (14)', SqliteException(14, 'unable to open database file')),
      (
        'locked across the isolate (text only)',
        Exception('SqliteException(5): database is locked')
      ),
      ('a plain error', StateError('migration bug')),
    ];

    test('isDatabaseFileDamaged', () {
      for (final (label, e) in damaged) {
        expect(isDatabaseFileDamaged(e), isTrue, reason: label);
      }
      for (final (label, e) in notDamaged) {
        expect(isDatabaseFileDamaged(e), isFalse, reason: label);
      }
    });

    for (final (label, error) in notDamaged) {
      testWidgets('$label: Try again and support only', (tester) async {
        await tester.pumpWidget(AppRoot(startupDbError: error));
        expect(find.text("Open POS couldn't open its data."), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(find.textContaining('WhatsApp'), findsOneWidget);
        expect(find.text(kRestoreLatestBackupButton), findsNothing);
        expect(find.text(kStartFreshButton), findsNothing);
        await tester.pumpWidget(const SizedBox());
      });
    }

    for (final (label, error) in damaged) {
      testWidgets('a $label database offers restore and start fresh',
          (tester) async {
        await tester.pumpWidget(AppRoot(startupDbError: error));
        expect(find.text("Open POS couldn't open its data."), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(find.text(kRestoreLatestBackupButton), findsOneWidget);
        expect(find.text(kStartFreshButton), findsOneWidget);
        expect(find.textContaining('WhatsApp'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('no automatic backups: says so, changes nothing',
        (tester) async {
      await tester
          .pumpWidget(AppRoot(startupDbError: DatabaseMissingError('x')));
      await tester.tap(find.text(kRestoreLatestBackupButton));
      await pumpUntil(
          tester, () => find.text(kNoAutoBackups).evaluate().isNotEmpty);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text("Open POS couldn't open its data."), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets(
      'Start fresh refuses, touching nothing, while the stores are not open',
      (tester) async {
    // A healthy-looking file, and no Hive box open.
    await tester.runAsync(() async {
      final db = AppDatabase(NativeDatabase(dbFile()));
      await seedProduct(db, sku: 'KEEP');
      await db.close();
    });
    final before = dbFile().readAsBytesSync();
    await tester.pumpWidget(
        AppRoot(startupDbError: SqliteException(26, 'file is not a database')));
    await tester.tap(find.text(kStartFreshButton));
    await tester.pumpAndSettle();
    await tester.runAsync(
        () => tester.tap(find.widgetWithText(FilledButton, kStartFreshButton)));
    await tester.pumpAndSettle();
    expect(find.text(kStartFreshNeedsStores), findsOneWidget);
    expect(find.text("Open POS couldn't open its data."), findsOneWidget);
    expect(dbFile().readAsBytesSync(), before, reason: 'file untouched');
    expect(docs.listSync().where((e) => e.path.contains('.broken-')), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Start fresh: Cancel changes nothing; confirmed, the broken file is '
      'set aside and the app opens on an empty database', (tester) async {
    await tester.runAsync(() async {
      await openBoxes();
      dbFile().writeAsStringSync('this is not a database' * 100);
    });
    await tester.pumpWidget(
        AppRoot(startupDbError: SqliteException(26, 'file is not a database')));

    await tester.tap(find.text(kStartFreshButton));
    await tester.pumpAndSettle();
    expect(find.text(kStartFreshTitle), findsOneWidget);
    expect(find.text(kStartFreshMessage), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text("Open POS couldn't open its data."), findsOneWidget);
    expect(dbFile().readAsStringSync(), startsWith('this is not'));

    await tester.tap(find.text(kStartFreshButton));
    await tester.pumpAndSettle();
    await tester.runAsync(
        () => tester.tap(find.widgetWithText(FilledButton, kStartFreshButton)));
    await pumpUntil(tester, () => find.byType(POSApp).evaluate().isNotEmpty);
    expect(find.text(kStartFreshDoneNotice), findsOneWidget);
    expect(dbFile().lengthSync(), greaterThan(0));
    final aside = docs
        .listSync()
        .where((e) => p.basename(e.path).contains('.broken-'))
        .toList();
    expect(aside, hasLength(1), reason: 'kept for support, not deleted');
    await tester.pump(const Duration(seconds: 9));
    await done(tester);
  });

  testWidgets(
      'Restore: pick a backup (newest first) and the normal restore brings '
      'the shop back', (tester) async {
    late File newest;
    await tester.runAsync(() async {
      await openBoxes();
      // A shop with a product, backed up twice like the daily backup.
      final db = AppDatabase(NativeDatabase(dbFile()));
      final c = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)]);
      await seedProduct(db, sku: 'OLD');
      final first = await c
          .read(snapshotCoordinatorProvider)
          .create(autoDir(), includePhotos: false);
      // (Both would share a name within the same second.)
      first
          .renameSync(p.join(
              autoDir().path,
              '${SnapshotService.filePrefix}20261101_000000'
              '${SnapshotService.fileSuffix}'))
          .setLastModifiedSync(DateTime(2026, 11, 1));
      await seedProduct(db, sku: 'NEW');
      newest = await c
          .read(snapshotCoordinatorProvider)
          .create(autoDir(), includePhotos: false);
      c.dispose();
      await db.close();
      // Then the database file is lost.
      for (final s in ['', '-wal', '-shm']) {
        final f = File('${dbFile().path}$s');
        if (f.existsSync()) f.deleteSync();
      }
    });

    await tester.pumpWidget(AppRoot(
        startupDbError: DatabaseMissingError(dbFile().path),
        recoverForRetry: () async => RestoreRecovery.none));
    await tester
        .runAsync(() => tester.tap(find.text(kRestoreLatestBackupButton)));
    await pumpUntil(
        tester, () => find.text(kPickBackupTitle).evaluate().isNotEmpty);
    await tester.pumpAndSettle();
    final options = find.descendant(
        of: find.byType(SimpleDialogOption), matching: find.byType(Text));
    final labels = [
      for (final e in options.evaluate()) (e.widget as Text).data!
    ];
    expect(labels, hasLength(3)); // two backups + Cancel
    expect(labels.first, endsWith(kNewestBackupTag));
    expect(labels.last, 'Cancel');

    await tester.runAsync(() => tester.tap(find.text(labels.first)));
    await pumpUntil(tester, () => find.byType(POSApp).evaluate().isNotEmpty);
    expect(find.text('Backup restored'), findsOneWidget);
    final state = tester.state<AppRootState>(find.byType(AppRoot));
    final db = state.containerForTest.read(databaseProvider);
    final skus = await tester
        .runAsync(() => db.select(db.products).map((r) => r.sku).get());
    expect(skus, containsAll(['OLD', 'NEW']));
    expect(newest.existsSync(), isTrue, reason: 'the backup itself is kept');
    await tester.pump(const Duration(seconds: 9));
    await done(tester);
  });
}
