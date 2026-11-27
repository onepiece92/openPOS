import 'dart:async';
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
import 'package:pos_app/features/settings/data/factory_reset.dart'
    show kFactoryResetPendingKey;

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

    Set<String> brokenNames() => {
          for (final e in docs.listSync())
            if (p.basename(e.path).contains('.broken-')) p.basename(e.path)
        };

    test('a second Start fresh with the main file missing keeps the copy',
        () async {
      dbFile().writeAsStringSync('the real shop');
      await setAsideDatabaseFile(dbFile(), DateTime(2026, 11, 1, 9));
      // The new database was never written; the app died; Start fresh again.
      final moved =
          await setAsideDatabaseFile(dbFile(), DateTime(2026, 11, 2, 9));
      expect(moved, isNull);
      expect(brokenNames(), {'$kDatabaseFileName.broken-20261101-090000'});
    });

    test('a second Start fresh on a 0-byte main file keeps the older copy',
        () async {
      dbFile().writeAsStringSync('the real shop');
      await setAsideDatabaseFile(dbFile(), DateTime(2026, 11, 1, 9));
      dbFile().writeAsBytesSync([]);
      await setAsideDatabaseFile(dbFile(), DateTime(2026, 11, 2, 9));
      expect(brokenNames(), {
        '$kDatabaseFileName.broken-20261101-090000',
        '$kDatabaseFileName.broken-20261102-090000',
      });
      expect(
          File('${dbFile().path}.broken-20261101-090000').readAsStringSync(),
          'the real shop');
    });

    test('an older copy larger than the new one is never deleted', () async {
      dbFile().writeAsStringSync('the real shop, years of sales');
      File('${dbFile().path}-wal').writeAsStringSync('w');
      await setAsideDatabaseFile(dbFile(), DateTime(2026, 11, 1, 9));
      dbFile().writeAsStringSync('tiny');
      await setAsideDatabaseFile(dbFile(), DateTime(2026, 11, 2, 9));
      expect(brokenNames(), {
        '$kDatabaseFileName.broken-20261101-090000',
        '$kDatabaseFileName.broken-20261101-090000-wal',
        '$kDatabaseFileName.broken-20261102-090000',
      });
    });

    test('only the newest set-aside set is kept', () async {
      dbFile().writeAsStringSync('first');
      File('${dbFile().path}-wal').writeAsStringSync('w1');
      await setAsideDatabaseFile(dbFile(), DateTime(2026, 11, 1, 9));
      dbFile().writeAsStringSync('second');
      File('${dbFile().path}-shm').writeAsStringSync('s2');
      final moved =
          await setAsideDatabaseFile(dbFile(), DateTime(2026, 11, 2, 9));
      final names = {
        for (final e in docs.listSync())
          if (p.basename(e.path).contains('.broken-')) p.basename(e.path)
      };
      expect(names, {
        '$kDatabaseFileName.broken-20261102-090000',
        '$kDatabaseFileName.broken-20261102-090000-shm',
      });
      expect(moved!.readAsStringSync(), 'second');
    });

    test('the Start fresh confirm says the damaged file is kept', () {
      expect(kStartFreshMessage,
          endsWith('The damaged file is kept on this device for support.'));
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

    // Confirmed. (Run on the real clock, not awaited — its Hive writes
    // would otherwise stay pending in the fake-async zone. The confirm
    // button's wiring is covered by the "refuses" test above.)
    final state = tester.state<AppRootState>(find.byType(AppRoot));
    await tester.runAsync(() async {
      unawaited(state.startFresh());
    });
    await pumpUntil(tester, () => find.byType(POSApp).evaluate().isNotEmpty);
    expect(find.text(kStartFreshDoneNotice), findsOneWidget);
    expect(dbFile().lengthSync(), greaterThan(0));
    expect(autoBackupPrunePausedSince(), isNotNull,
        reason: 'the backups from before Start fresh are kept');
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

  testWidgets(
      'a picked backup that fails: same screen and exits, plain words, the '
      'picker again; an older good one then restores', (tester) async {
    await tester.runAsync(() async {
      await openBoxes();
      final db = AppDatabase(NativeDatabase(dbFile()));
      final c = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)]);
      await seedProduct(db, sku: 'GOOD');
      (await c
              .read(snapshotCoordinatorProvider)
              .create(autoDir(), includePhotos: false))
          .setLastModifiedSync(DateTime(2026, 11, 1));
      c.dispose();
      await db.close();
      // The newest automatic backup is damaged.
      File(p.join(autoDir().path,
          '${SnapshotService.filePrefix}20261120_090000${SnapshotService.fileSuffix}'))
        ..writeAsStringSync('not a zip')
        ..setLastModifiedSync(DateTime(2026, 11, 20));
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
    await tester.pump(const Duration(milliseconds: 500));
    await tester
        .runAsync(() => tester.tap(find.textContaining(kNewestBackupTag)));

    // Back on the open-failure screen, the picker open again with the note.
    await pumpUntil(tester,
        () => find.text(kBackupRestoreFailedTryAnother).evaluate().length == 2);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(kPickBackupTitle), findsOneWidget);
    expect(find.text("Open POS couldn't open its data."), findsOneWidget);
    expect(find.text('Restore failed'), findsNothing);
    expect(find.textContaining(docs.path), findsNothing, reason: 'no paths');
    expect(find.textContaining('Exception'), findsNothing);
    expect(File(p.join(docs.path, 'restore_merge.json')).existsSync(), isFalse,
        reason: 'no leftover merge marker');

    // The older one is listed and works. (Picked through the same entry
    // point on the real clock: the re-opened picker lives in the fake-async
    // zone, where the restore's file and isolate work would not finish.)
    final older = find.descendant(
        of: find.byType(SimpleDialogOption),
        matching: find.textContaining('Nov 1, 2026'));
    expect(older, findsOneWidget);
    await tester.tap(find.text('Cancel'));
    for (var i = 0;
        i < 50 && find.byType(SimpleDialog).evaluate().isNotEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(SimpleDialog), findsNothing);
    final good = (await tester.runAsync(listAutoBackups))!.last.$1;
    final state0 = tester.state<AppRootState>(find.byType(AppRoot));
    // Started on the real clock, not awaited: it waits for a frame, which
    // pumpUntil pumps.
    await tester.runAsync(() async {
      unawaited(state0.restoreFromErrorScreen(good));
    });
    await pumpUntil(tester, () => find.byType(POSApp).evaluate().isNotEmpty);
    expect(find.text('Backup restored'), findsOneWidget);
    final state = tester.state<AppRootState>(find.byType(AppRoot));
    final db = state.containerForTest.read(databaseProvider);
    final skus = await tester
        .runAsync(() => db.select(db.products).map((r) => r.sku).get());
    expect(skus, ['GOOD']);
    await tester.pump(const Duration(seconds: 9));
    await done(tester);
  });

  testWidgets('cancelling the second picker keeps both exits and the note',
      (tester) async {
    await tester.runAsync(() async {
      await openBoxes();
      autoDir().createSync(recursive: true);
      File(p.join(autoDir().path,
              '${SnapshotService.filePrefix}20261120_090000${SnapshotService.fileSuffix}'))
          .writeAsStringSync('not a zip');
    });
    await tester.pumpWidget(AppRoot(
        startupDbError: DatabaseMissingError(dbFile().path),
        recoverForRetry: () async => RestoreRecovery.none));
    await tester
        .runAsync(() => tester.tap(find.text(kRestoreLatestBackupButton)));
    await pumpUntil(
        tester, () => find.text(kPickBackupTitle).evaluate().isNotEmpty);
    await tester.pump(const Duration(milliseconds: 500));
    await tester
        .runAsync(() => tester.tap(find.textContaining(kNewestBackupTag)));
    await pumpUntil(tester,
        () => find.text(kBackupRestoreFailedTryAnother).evaluate().length == 2);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Cancel'));
    for (var i = 0;
        i < 50 && find.byType(SimpleDialog).evaluate().isNotEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(SimpleDialog), findsNothing);
    expect(find.text(kBackupRestoreFailedTryAnother), findsOneWidget,
        reason: 'the note stays on the screen');
    expect(find.text(kRestoreLatestBackupButton), findsOneWidget);
    expect(find.text(kStartFreshButton), findsOneWidget);
    await done(tester);
  });

  testWidgets(
      'a restore drops the reset flag and the Start fresh pause a backup '
      'carries', (tester) async {
    late File zip;
    await tester.runAsync(() async {
      await openBoxes();
      final db = AppDatabase(NativeDatabase(dbFile()));
      await seedProduct(db, sku: 'KEPT');
      await db.close();
      final settings = Hive.box<dynamic>('settings');
      // An older-style backup, written without stripping.
      await settings.putAll({
        kFactoryResetPendingKey: true,
        kStartFreshAtKey: DateTime(2026, 11, 1).toIso8601String(),
      });
      await settings.flush();
      zip = await const SnapshotService().create(
        dbFile: dbFile(),
        hiveBoxFiles: snapshotHiveBoxFiles(),
        outDir: autoDir(),
        schemaVersion: AppDatabase.currentSchemaVersion,
        includePhotos: false,
      );
      for (final s in ['', '-wal', '-shm']) {
        final f = File('${dbFile().path}$s');
        if (f.existsSync()) f.deleteSync();
      }
    });
    await tester.pumpWidget(AppRoot(
        startupDbError: DatabaseMissingError(dbFile().path),
        recoverForRetry: () async => RestoreRecovery.none));
    final state = tester.state<AppRootState>(find.byType(AppRoot));
    await tester.runAsync(() async {
      unawaited(state.restoreFromErrorScreen(zip));
    });
    await pumpUntil(tester, () => find.byType(POSApp).evaluate().isNotEmpty);
    final settings = Hive.box<dynamic>('settings');
    expect(settings.containsKey(kFactoryResetPendingKey), isFalse,
        reason: 'restored data must not re-arm an erase');
    expect(settings.containsKey(kStartFreshAtKey), isFalse,
        reason: 'a restore ends the pruning pause');
    final db = state.containerForTest.read(databaseProvider);
    final skus = await tester
        .runAsync(() => db.select(db.products).map((r) => r.sku).get());
    expect(skus, ['KEPT']);
    await tester.pump(const Duration(seconds: 9));
    await done(tester);
  });

  testWidgets(
      'probe: a damaged main file with a hot WAL gets both exits, and Start '
      'fresh moves db, wal and shm aside together', (tester) async {
    late Object openError;
    final copied = <String>[];
    await tester.runAsync(() async {
      await openBoxes();
      // A live WAL database, copied while open: main + -wal + -shm.
      final live = Directory(p.join(docs.path, 'live'))..createSync();
      final liveFile = File(p.join(live.path, kDatabaseFileName));
      final db = AppDatabase(NativeDatabase(liveFile));
      await seedProduct(db, sku: 'A');
      for (final s in ['', '-wal', '-shm']) {
        final f = File('${liveFile.path}$s');
        if (f.existsSync()) {
          f.copySync('${dbFile().path}$s');
          copied.add(s);
        }
      }
      await db.close();
      // Damage the main file's header. (The WAL's own header is damaged
      // too: a valid WAL that holds page 1 would mask the main header and
      // the file would open — that case surfaces later, as a CORRUPT
      // query, not on this screen.)
      final bytes = dbFile().readAsBytesSync()
        ..setRange(0, 100, List.filled(100, 0x41));
      dbFile().writeAsBytesSync(bytes, flush: true);
      final wal = File('${dbFile().path}-wal');
      final walBytes = wal.readAsBytesSync()
        ..setRange(0, 32, List.filled(32, 0));
      wal.writeAsBytesSync(walBytes, flush: true);
      final broken = AppDatabase(NativeDatabase(dbFile()));
      Object? error;
      try {
        await broken.customSelect('SELECT 1').get();
      } catch (e) {
        error = e;
      }
      expect(error, isNotNull, reason: 'the damaged file must not open');
      openError = error!;
      try {
        await broken.close();
      } catch (_) {}
    });
    expect(copied, containsAll(['', '-wal']), reason: 'a hot WAL');
    expect(isDatabaseFileDamaged(openError), isTrue, reason: '$openError');

    await tester.pumpWidget(AppRoot(startupDbError: openError));
    expect(find.text(kRestoreLatestBackupButton), findsOneWidget);
    expect(find.text(kStartFreshButton), findsOneWidget);
    final state = tester.state<AppRootState>(find.byType(AppRoot));
    await tester.runAsync(() async {
      unawaited(state.startFresh());
    });
    await pumpUntil(tester, () => find.byType(POSApp).evaluate().isNotEmpty);
    final stamp = RegExp(r'broken-\d{8}-\d{6}');
    final aside = {
      for (final e in docs.listSync())
        if (p.basename(e.path).contains('.broken-'))
          p.basename(e.path).replaceFirst(stamp, 'broken')
    };
    expect(
        aside,
        {
          for (final s in copied) '$kDatabaseFileName.broken$s',
        },
        reason: 'the whole set moved together');
    await tester.pump(const Duration(seconds: 9));
    await done(tester);
  });
}
