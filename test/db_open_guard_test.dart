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
    test('runs the database check after the stores and reports a failure',
        () async {
      final order = <String>[];
      final r = await startUp(
        recover: () async => RestoreRecovery.none,
        initHive: () async {},
        openStores: () async => order.add('openStores'),
        checkDatabase: () async {
          order.add('check');
          throw DatabaseTooNewError(99, 16);
        },
      );
      expect(order, ['openStores', 'check']);
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
