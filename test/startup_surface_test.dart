import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/app.dart';
import 'package:pos_app/app_root.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/upgrade_progress.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/startup.dart';

import 'app_root_retry_test.dart' show pumpUntil;
import 'drift/generated/schema.dart';

/// Records every statement the app's database runs, and whether the
/// startup check had been let through when it ran.
class _Recorder extends QueryInterceptor {
  final statements = <(String, bool)>[];
  bool checkReleased = false;

  void _rec(String sql) => statements.add((sql, checkReleased));

  @override
  Future<bool> ensureOpen(QueryExecutor executor, QueryExecutorUser user) {
    _rec('<open>');
    return super.ensureOpen(executor, user);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
      QueryExecutor executor, String statement, List<Object?> args) {
    _rec(statement);
    return super.runSelect(executor, statement, args);
  }

  @override
  Future<void> runCustom(
      QueryExecutor executor, String statement, List<Object?> args) {
    _rec(statement);
    return super.runCustom(executor, statement, args);
  }
}

class _CloseRecorder extends QueryInterceptor {
  bool closed = false;
  @override
  Future<void> close(QueryExecutor inner) {
    closed = true;
    return super.close(inner);
  }
}

/// The launch: first frame up at once on a plain surface, the database
/// check after it, and nothing that touches the database before it.
void main() {
  tearDown(() => databaseUpgradeRunning.value = false);

  group('the launch surface', () {
    testWidgets('first frame is the plain surface with no text',
        (tester) async {
      final pending = Completer<StartupResult>();
      await tester.pumpWidget(AppRoot(startup: pending.future));

      expect(find.byType(StartupSurface), findsOneWidget);
      expect(find.byType(Text), findsNothing);
      expect(find.byType(MaterialApp), findsNothing);
      expect(find.byType(POSApp), findsNothing);
      final box = tester.widget<ColoredBox>(find.descendant(
          of: find.byType(StartupSurface), matching: find.byType(ColoredBox)));
      expect(box.color, const Color(0xFFFFFFFF),
          reason: 'Android light launch window and iOS storyboard are white');

      pending.complete(const StartupResult(fatal: 'x'));
      await tester.pump();
    });

    test('colour follows the native launch screen', () {
      const white = Color(0xFFFFFFFF), black = Color(0xFF000000);
      expect(
          launchSurfaceColor(Brightness.light, TargetPlatform.android), white);
      expect(launchSurfaceColor(Brightness.dark, TargetPlatform.android), black,
          reason: 'Theme.Black colorBackground');
      expect(launchSurfaceColor(Brightness.dark, TargetPlatform.iOS), white,
          reason: 'LaunchScreen.storyboard is always white');
    });

    testWidgets('a 490 ms launch shows no text and is not held back',
        (tester) async {
      final pending = Completer<StartupResult>();
      await tester.pumpWidget(AppRoot(startup: pending.future));
      await tester.pump(const Duration(milliseconds: 490));
      pending.complete(const StartupResult(fatal: 'x'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(StartupSurface), findsNothing);
      expect(find.text(kOpeningAppText), findsNothing);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('a fast check never shows any text', (tester) async {
      final pending = Completer<StartupResult>();
      await tester.pumpWidget(AppRoot(startup: pending.future));
      await tester.pump(const Duration(milliseconds: 6));
      expect(find.byType(Text), findsNothing);
      pending.complete(const StartupResult(fatal: 'x'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(kOpeningAppText), findsNothing);
    });

    testWidgets('a slow check shows one line, only after the delay',
        (tester) async {
      final pending = Completer<StartupResult>();
      await tester.pumpWidget(AppRoot(startup: pending.future));
      expect(kStartupLineDelay, const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 490));
      expect(find.byType(Text), findsNothing);
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Opening Open POS…'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);

      // A migration starts (or was already running): the line says so.
      databaseUpgradeRunning.value = true;
      await tester.pump();
      expect(find.text('Updating your data…'), findsOneWidget);
      expect(find.text('Opening Open POS…'), findsNothing);

      databaseUpgradeRunning.value = false;
      // Resolved long after the line went up: no extra hold.
      await tester.pump(kStartupLineMinVisible);
      pending.complete(const StartupResult(fatal: 'x'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(StartupSurface), findsNothing);
    });

    testWidgets(
        'a check that ends just after the line appears keeps it up for '
        '${kStartupLineMinVisible.inMilliseconds} ms (no flash)',
        (tester) async {
      final pending = Completer<StartupResult>();
      await tester.pumpWidget(AppRoot(startup: pending.future));
      await tester.pump(kStartupLineDelay + const Duration(milliseconds: 1));
      expect(find.text(kOpeningAppText), findsOneWidget);
      expect(kStartupLineMinVisible, const Duration(milliseconds: 250));
      // Startup finishes 40 ms later (a 540 ms launch).
      await tester.pump(const Duration(milliseconds: 40));
      pending.complete(const StartupResult(fatal: 'x'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 190));
      expect(find.text(kOpeningAppText), findsOneWidget,
          reason: 'still within the minimum');
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump();
      expect(find.byType(StartupSurface), findsNothing);
      expect(find.text('x'), findsOneWidget);
    });

    testWidgets(
        'the exit guard is installed before startUp resolves; a quit then '
        'waits for startUp before closing the database', (tester) async {
      final closes = _CloseRecorder();
      final db = AppDatabase(NativeDatabase.memory().interceptWith(closes));
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ]);
      final pending = Completer<StartupResult>();
      await tester
          .pumpWidget(AppRoot(container: container, startup: pending.future));
      final state = tester.state<AppRootState>(find.byType(AppRoot));
      // startUp has opened the database and is still running (a migration).
      container.read(databaseProvider);
      var exited = false;
      final quit =
          state.exitGuardForTest.handleExitRequest().then((_) => exited = true);
      await tester.pump(const Duration(milliseconds: 100));
      expect(exited, isFalse, reason: 'waits for startUp');
      pending.complete(const StartupResult(fatal: 'x'));
      await pumpUntil(tester, () => exited);
      await quit;
      expect(exited, isTrue);
      expect(closes.closed, isTrue, reason: 'closed once startUp was done');
      await tester.pump(kStartupLineMinVisible);
    });

    testWidgets('a migration already running shows "Updating your data…"',
        (tester) async {
      databaseUpgradeRunning.value = true;
      final pending = Completer<StartupResult>();
      await tester.pumpWidget(AppRoot(startup: pending.future));
      expect(find.byType(Text), findsNothing, reason: 'not before the delay');
      await tester.pump(kStartupLineDelay + const Duration(milliseconds: 1));
      expect(find.text('Updating your data…'), findsOneWidget);
      databaseUpgradeRunning.value = false;
      pending.complete(const StartupResult(fatal: 'x'));
      await tester.pump(kStartupLineMinVisible);
    });
  });

  group('the upgrade flag', () {
    test('is on during a real v15 → current migration, off after', () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final db = AppDatabase(await verifier.startAt(15));
      addTearDown(db.close);
      final seen = <bool>[];
      void listener() => seen.add(databaseUpgradeRunning.value);
      databaseUpgradeRunning.addListener(listener);
      addTearDown(() => databaseUpgradeRunning.removeListener(listener));
      await db.customSelect('SELECT 1').get();
      expect(seen, [true, false]);
      expect(databaseUpgradeRunning.value, isFalse);
    });

    test('stays off for a fresh install and for current data', () async {
      final seen = <bool>[];
      void listener() => seen.add(databaseUpgradeRunning.value);
      databaseUpgradeRunning.addListener(listener);
      addTearDown(() => databaseUpgradeRunning.removeListener(listener));
      final db = AppDatabase(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();
      await db.close();
      expect(seen, isEmpty);
    });
  });

  group('with a fake documents folder', () {
    late Directory docs;
    const channel = MethodChannel('plugins.flutter.io/path_provider');

    setUp(() {
      docs = Directory.systemTemp.createTempSync('pos_launch_');
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
        'no database query (or open) before the check resolves; the app '
        'builds after it', (tester) async {
      final rec = _Recorder();
      var dbCreated = false;
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWith((ref) {
          dbCreated = true;
          final db = AppDatabase(NativeDatabase.memory().interceptWith(rec));
          ref.onDispose(db.close);
          return db;
        }),
      ]);
      final gate = Completer<void>();
      final order = <String>[];
      // Started on the real clock (its Hive and file IO must complete).
      late Future<StartupResult> startup;
      await tester.runAsync(() async {
        startup = startUp(
          recover: () async {
            order.add('recover');
            return RestoreRecovery.none;
          },
          initHive: () async => order.add('initHive'),
          openStores: () async {
            order.add('openStores');
            await openStartupStores();
          },
          checkDatabase: () async {
            await gate.future;
            order.add('check');
            await container
                .read(databaseProvider)
                .customSelect('SELECT 1')
                .get();
          },
        );
      });

      await tester.pumpWidget(AppRoot(container: container, startup: startup));
      await pumpUntil(tester, () => Hive.isBoxOpen('settings'));
      await tester.pump(const Duration(seconds: 1));
      // Hive is up, the stores are open, the line is showing — and the
      // database has not been created, opened or queried.
      expect(order, ['recover', 'initHive', 'openStores']);
      expect(find.text(kOpeningAppText), findsOneWidget);
      expect(find.byType(POSApp), findsNothing);
      expect(dbCreated, isFalse);
      expect(container.exists(databaseProvider), isFalse);
      expect(rec.statements, isEmpty);

      rec.checkReleased = true;
      gate.complete();
      await pumpUntil(tester, () => find.byType(POSApp).evaluate().isNotEmpty);
      expect(order.last, 'check');
      expect(rec.statements, isNotEmpty);
      expect(rec.statements.where((s) => !s.$2), isEmpty,
          reason: 'every statement ran after the check was let through');
      expect(rec.statements.any((s) => s.$1 == 'SELECT 1'), isTrue);
      expect(find.byType(StartupSurface), findsNothing);
      expect(tester.state<AppRootState>(find.byType(AppRoot)).containerForTest,
          same(container),
          reason: 'the app reuses the container the check opened');

      await tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox());
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
    });

    testWidgets('a startup notice still toasts once the app is up',
        (tester) async {
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWith((ref) {
          final db = AppDatabase(NativeDatabase.memory());
          ref.onDispose(db.close);
          return db;
        }),
      ]);
      late Future<StartupResult> startup;
      await tester.runAsync(() async {
        startup = startUp(
          recover: () async => RestoreRecovery.rolledBack,
          initHive: () async {},
          checkDatabase: () =>
              container.read(databaseProvider).customSelect('SELECT 1').get(),
        );
      });
      await tester.pumpWidget(AppRoot(container: container, startup: startup));
      await pumpUntil(tester,
          () => find.byType(RestartNoticeOverlay).evaluate().isNotEmpty);
      expect(find.byType(POSApp), findsOneWidget);
      // Let the toast run out (its timer must not outlive the test).
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();
      expect(find.byType(RestartNoticeOverlay), findsNothing);

      await tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox());
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
    });
  });
}
