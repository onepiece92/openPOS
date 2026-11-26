import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/app_root.dart';
import 'package:pos_app/core/database/connection/native.dart';
import 'package:pos_app/core/database/database_open_errors.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/startup.dart';

import 'app_root_retry_test.dart' show pumpUntil;

/// A missing or empty database file under a finished onboarding goes to
/// the error screen instead of a silently recreated empty database.
void main() {
  group('assertDatabaseFilePresent', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('pos_dbfile_'));
    tearDown(() => dir.deleteSync(recursive: true));
    File file() => File(p.join(dir.path, 'pos_database.db'));

    test('onboarded and missing: refused', () {
      expect(
          assertDatabaseFilePresent(onboardingComplete: true, file: file()),
          throwsA(isA<DatabaseMissingError>()));
    });

    test('onboarded and 0 bytes: refused', () {
      file().createSync();
      expect(
          assertDatabaseFilePresent(onboardingComplete: true, file: file()),
          throwsA(isA<DatabaseMissingError>()));
    });

    test('onboarded with a database: fine', () async {
      file().writeAsBytesSync(List.filled(4096, 1));
      await assertDatabaseFilePresent(onboardingComplete: true, file: file());
    });

    test('a fresh install (onboarding not done): fine, Drift creates it',
        () async {
      await assertDatabaseFilePresent(onboardingComplete: false, file: file());
    });

    test('shown as the plain open failure, with Try again', () {
      final f = describeDatabaseOpenFailure(DatabaseMissingError('x'));
      expect(f.title, 'Something went wrong');
      expect(f.message, "Open POS couldn't open its data.");
      expect(f.canRetry, isTrue);
    });
  });

  group('with a fake documents folder', () {
    late Directory docs;
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    File dbFile() => File(p.join(docs.path, kDatabaseFileName));

    setUp(() async {
      docs = Directory.systemTemp.createTempSync('pos_dbmissing_');
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

    Future<StartupResult> launch() => startUp(
          recover: () async => RestoreRecovery.none,
          initHive: () async {},
          openStores: () async {
            await Hive.openBox<dynamic>('settings');
          },
          checkDatabase: checkDatabaseFileBeforeOpen,
        );

    test('startUp: onboarded with no database file → the error, no file made',
        () async {
      final s = await Hive.openBox<dynamic>('settings');
      await s.put(kOnboardingCompleteKey, true);
      final r = await launch();
      expect(r.dbError, isA<DatabaseMissingError>());
      expect(dbFile().existsSync(), isFalse);
    });

    test('startUp: a fresh install passes', () async {
      final r = await launch();
      expect(r.dbError, isNull);
    });

    testWidgets(
        'the error screen, and Try again refuses to create an empty database',
        (tester) async {
      await tester.runAsync(() async {
        final s = await Hive.openBox<dynamic>('settings');
        await s.put(kOnboardingCompleteKey, true);
        dbFile().createSync(); // 0 bytes
      });
      await tester.pumpWidget(AppRoot(
        startupDbError: DatabaseMissingError(dbFile().path),
        recoverForRetry: () async => RestoreRecovery.none,
      ));
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text("Open POS couldn't open its data."), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.textContaining('WhatsApp'), findsOneWidget);
      expect(find.textContaining('missing'), findsNothing);

      await tester.runAsync(() => tester.tap(find.text('Try again')));
      await pumpUntil(tester, () => Hive.isBoxOpen('settings'));
      await pumpUntil(
          tester, () => find.text('Try again').evaluate().isNotEmpty);
      expect(find.text("Open POS couldn't open its data."), findsOneWidget);
      expect(dbFile().lengthSync(), 0, reason: 'nothing was created');

      await tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox());
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
    });
  });
}
