import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import 'package:pos_app/app_root.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/database_open_errors.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/startup.dart';

import 'app_root_retry_test.dart' show pumpUntil;

/// The launch-time database check: a file from a newer app or any other
/// open failure lands on the error screen with plain wording.
void main() {
  test('a database from a newer app fails its first query as too new',
      () async {
    final dir = Directory.systemTemp.createTempSync('pos_too_new_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    sql.sqlite3.open(file.path)
      ..execute('PRAGMA user_version = ${AppDatabase.currentSchemaVersion + 1}')
      ..dispose();

    final db = AppDatabase(NativeDatabase(file));
    Object? error;
    try {
      await db.customSelect('SELECT 1').get();
    } catch (e) {
      error = e;
    }
    await db.close();
    expect(error, isA<DatabaseTooNewError>());
    expect(error, isA<StateError>());
    expect(isDatabaseTooNew(error!), isTrue);
    expect(isDatabaseTooNew(Exception('disk I/O error')), isFalse);
  });

  group('startUp', () {
    test(
        'recovery, Hive, the stores, then the database check; a failure '
        'is reported', () async {
      final order = <String>[];
      final r = await startUp(
        recover: () async {
          order.add('recover');
          return RestoreRecovery.none;
        },
        initHive: () async => order.add('initHive'),
        openStores: () async => order.add('openStores'),
        checkDatabase: () async {
          order.add('check');
          throw DatabaseTooNewError(99, 16);
        },
      );
      expect(order, ['recover', 'initHive', 'openStores', 'check']);
      expect(r.dbError, isA<DatabaseTooNewError>());
      expect(r.fatal, isNull);
    });

    test('a passing check leaves the result clean', () async {
      var checks = 0;
      final r = await startUp(
        recover: () async => RestoreRecovery.none,
        initHive: () async {},
        openStores: () async {},
        checkDatabase: () async => checks++,
      );
      expect(checks, 1);
      expect((r.notice, r.fatal, r.dbError), (null, null, null));
    });

    test('a failed recovery skips the check', () async {
      var checks = 0;
      final r = await startUp(
        recover: () async => null,
        initHive: () async {},
        openStores: () async {},
        checkDatabase: () async => checks++,
      );
      expect(checks, 0);
      expect(r.fatal, kRecoveryFailedMessage);
    });
  });

  // The check now runs after the first frame: AppRoot is pumped with the
  // still-running startUp future and routes its result when it resolves.
  group('routed from the startup future, after the first frame', () {
    Future<void> launchWith(WidgetTester tester, Object error,
        {bool asThrow = false}) async {
      final pending = Completer<StartupResult>();
      await tester.pumpWidget(AppRoot(
        startup: pending.future,
        recoverForRetry: () async => RestoreRecovery.none,
      ));
      expect(find.byType(StartupSurface), findsOneWidget);
      expect(find.byType(Text), findsNothing);
      asThrow
          ? pending.completeError(error)
          : pending.complete(StartupResult(dbError: error));
      // One pump delivers the result, the next draws it.
      await tester.pump();
      await tester.pump();
      expect(find.byType(StartupSurface), findsNothing);
    }

    testWidgets('too new: Update Open POS, no Try again', (tester) async {
      await launchWith(tester, DatabaseTooNewError(99, 16));
      expect(find.text('Update Open POS'), findsOneWidget);
      expect(
          find.text('This data was saved by a newer version of Open POS. '
              'Update the app to open it.'),
          findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(find.textContaining('Contact support'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('other failure: Something went wrong, Try again, WhatsApp',
        (tester) async {
      await launchWith(tester, Exception('disk I/O error'));
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text("Open POS couldn't open its data."), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.textContaining('WhatsApp'), findsOneWidget);
      expect(find.textContaining('disk I/O'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a startup that throws is the same plain failure',
        (tester) async {
      await launchWith(tester, StateError('Hive init failed'), asThrow: true);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('failed recovery: the restore error screen with Try again',
        (tester) async {
      final pending = Completer<StartupResult>();
      await tester.pumpWidget(AppRoot(startup: pending.future));
      pending.complete(const StartupResult(fatal: kRecoveryFailedMessage));
      await tester.pump();
      await tester.pump();
      expect(find.text('Restore failed'), findsOneWidget);
      expect(find.text(kRecoveryFailedMessage), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('too new: plain message, no Try again, support still offered',
      (tester) async {
    await tester
        .pumpWidget(AppRoot(startupDbError: DatabaseTooNewError(99, 16)));
    expect(find.text(kDataTooNewTitle), findsOneWidget);
    expect(
        find.text('This data was saved by a newer version of Open POS. '
            'Update the app to open it.'),
        findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(find.text('Restore failed'), findsNothing);
    expect(find.textContaining('schema'), findsNothing);
    expect(find.textContaining('Contact support'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  group('with a fake documents folder', () {
    late Directory docs;
    const channel = MethodChannel('plugins.flutter.io/path_provider');

    setUp(() {
      docs = Directory.systemTemp.createTempSync('pos_dbguard_');
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

    testWidgets(
        'other failure: plain message, support, and Try again opens the app',
        (tester) async {
      await tester.pumpWidget(AppRoot(
        startupDbError:
            Exception('SqliteException(26): file is not a database'),
        recoverForRetry: () async => RestoreRecovery.none,
      ));
      expect(find.text("Open POS couldn't open its data."), findsOneWidget);
      expect(find.textContaining('SqliteException'), findsNothing);
      expect(find.textContaining('Contact support'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tester.runAsync(() => tester.tap(find.text('Try again')));
      await pumpUntil(tester, () => Hive.isBoxOpen('settings'));
      await pumpUntil(tester, () => find.text('Try again').evaluate().isEmpty);
      expect(find.text("Open POS couldn't open its data."), findsNothing);

      await tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox());
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
    });

    testWidgets('a retry that still fails keeps the plain wording',
        (tester) async {
      // Not a database: the reopen's first query fails.
      File('${docs.path}/pos_database.db')
          .writeAsStringSync('this is not a database' * 100);
      await tester.pumpWidget(AppRoot(
        startupDbError: Exception('file is not a database'),
        recoverForRetry: () async => RestoreRecovery.none,
      ));
      await tester.runAsync(() => tester.tap(find.text('Try again')));
      await pumpUntil(tester, () => Hive.isBoxOpen('settings'));
      await pumpUntil(
          tester, () => find.text('Try again').evaluate().isNotEmpty);
      expect(find.text("Open POS couldn't open its data."), findsOneWidget);
      expect(find.textContaining('Still unable'), findsNothing);
      await tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox());
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
    });
  });
}
