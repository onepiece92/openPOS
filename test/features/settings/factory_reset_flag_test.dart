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
import 'package:pos_app/core/app_version.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart' show kWhatsNewSeenKey;
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pos_app/features/settings/data/factory_reset.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/backup/data/open_failure_recovery.dart';
import 'package:pos_app/startup.dart';

import '../../_support/sales.dart';
import '../../app_root_retry_test.dart' show pumpUntil;

/// A settings box whose writes can be made to fail (a full disk).
class _FlakyBox implements Box<dynamic> {
  _FlakyBox(this.inner);
  final Box<dynamic> inner;
  int failFlushes = 0; // the next N flushes throw
  int failDeletes = 0; // the next N deletes throw
  bool failPuts = false;
  void Function(dynamic key)? onDelete;

  static Never _full() =>
      throw const FileSystemException('No space left on device');

  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (failPuts) _full();
    await inner.put(key, value);
  }

  @override
  Future<void> flush() async {
    if (failFlushes > 0) {
      failFlushes--;
      _full();
    }
    await inner.flush();
  }

  @override
  Future<void> delete(dynamic key) async {
    onDelete?.call(key);
    if (failDeletes > 0) {
      failDeletes--;
      _full();
    }
    await inner.delete(key);
  }

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      inner.get(key, defaultValue: defaultValue);

  @override
  bool containsKey(dynamic key) => inner.containsKey(key);

  @override
  Iterable<dynamic> get keys => inner.keys;

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    if (failDeletes > 0) {
      failDeletes--;
      _full();
    }
    await inner.deleteAll(keys);
  }

  @override
  Future<void> putAll(Map<dynamic, dynamic> entries) async {
    if (failPuts) _full();
    await inner.putAll(entries);
  }

  @override
  String? get path => inner.path;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late Directory docs;
  late Box<dynamic> real;
  late _FlakyBox settings;

  setUp(() async {
    docs = Directory.systemTemp.createTempSync('pos_reset_flag_');
    Hive.init(docs.path);
    real = await Hive.openBox<dynamic>('settings');
    settings = _FlakyBox(real);
  });
  tearDown(() async {
    await Hive.close();
    docs.deleteSync(recursive: true);
  });

  Future<FactoryResetOutcome> reset({
    Future<void> Function()? erase,
  }) =>
      runFactoryReset(
        settings: settings,
        eraseDatabase: erase ?? () async {},
        releaseDatabase: () async {},
        heldOrders: real, // not reached in these paths
        usage: () async => real,
        receipts: () async => Directory(p.join(docs.path, 'receipts')),
      );

  Future<void> eraseRefused() async => throw StateError('disk full');

  group('clearFactoryResetPendingConfirmed', () {
    test('confirms the key is gone', () async {
      await real.put(kFactoryResetPendingKey, true);
      expect(await clearFactoryResetPendingConfirmed(settings), isTrue);
      expect(real.containsKey(kFactoryResetPendingKey), isFalse);
    });

    test('retries a failed delete and a failed flush', () async {
      await real.put(kFactoryResetPendingKey, true);
      settings
        ..failDeletes = 1
        ..failFlushes = 1;
      expect(
          await clearFactoryResetPendingConfirmed(settings,
              pause: Duration.zero),
          isTrue);
      expect(real.containsKey(kFactoryResetPendingKey), isFalse);
    });

    test('false when it never confirms', () async {
      await real.put(kFactoryResetPendingKey, true);
      settings.failDeletes = 99;
      expect(
          await clearFactoryResetPendingConfirmed(settings,
              pause: Duration.zero),
          isFalse);
      expect(real.containsKey(kFactoryResetPendingKey), isTrue);
    });

    test('a flush that keeps failing is never counted as cleared', () async {
      await real.put(kFactoryResetPendingKey, true);
      settings.failFlushes = 99;
      expect(
          await clearFactoryResetPendingConfirmed(settings,
              pause: Duration.zero),
          isFalse);
    });
  });

  group('runFactoryReset never says "not changed" with the flag set', () {
    test('(a) the flag flush fails, the clear works: refused, flag gone',
        () async {
      settings.failFlushes = 1;
      var erased = false;
      final r = await reset(erase: () async => erased = true);
      expect(r, FactoryResetOutcome.refused);
      expect(erased, isFalse);
      expect(real.containsKey(kFactoryResetPendingKey), isFalse);
    });

    test('(a) the flag flush fails and so does the clear: undecided', () async {
      settings
        ..failFlushes = 1
        ..failDeletes = 99;
      final r = await reset();
      expect(r, FactoryResetOutcome.undecided);
      expect(real.containsKey(kFactoryResetPendingKey), isTrue,
          reason: 'the put landed; the user is asked, not told "unchanged"');
    });

    test('(a) the put itself fails: refused once the clear confirms', () async {
      settings.failPuts = true;
      expect(await reset(), FactoryResetOutcome.refused);
      expect(real.containsKey(kFactoryResetPendingKey), isFalse);
    });

    test('(b) the erase is refused, the clear works: refused, flag gone',
        () async {
      expect(await reset(erase: eraseRefused), FactoryResetOutcome.refused);
      expect(real.containsKey(kFactoryResetPendingKey), isFalse);
    });

    test('(b) the erase is refused and the clear fails: undecided', () async {
      settings.failDeletes = 99;
      expect(await reset(erase: eraseRefused), FactoryResetOutcome.undecided);
      expect(real.containsKey(kFactoryResetPendingKey), isTrue);
    });
  });

  group('"Finish erasing" on a pending reset', () {
    test('does not write the flag again (a full disk cannot stop it)',
        () async {
      await real.put(kFactoryResetPendingKey, true);
      settings.failPuts = true; // any put would throw
      var erased = false;
      final r = await runFactoryReset(
        settings: settings,
        eraseDatabase: () async => erased = true,
        releaseDatabase: () async {},
        heldOrders: await Hive.openBox<dynamic>('held_orders'),
        usage: () async => Hive.openBox<dynamic>('usage'),
        receipts: () async => Directory(p.join(docs.path, 'receipts')),
      );
      expect(erased, isTrue);
      expect(r, FactoryResetOutcome.done);
      expect(real.containsKey(kFactoryResetPendingKey), isFalse);
    });

    test('an erase that fails and a flag that will not clear: undecided',
        () async {
      await real.put(kFactoryResetPendingKey, true);
      settings.failDeletes = 99;
      expect(await reset(erase: eraseRefused), FactoryResetOutcome.undecided);
      expect(real.containsKey(kFactoryResetPendingKey), isTrue);
    });
  });

  group('backups never carry the flag', () {
    test('settingsCopyWithoutResetFlag: null without the flag', () async {
      await real.put('store_name', 'Shop');
      expect(await settingsCopyWithoutResetFlag(docs, DateTime(2026)), isNull);
    });

    test('a copy of the box without the flag, everything else kept', () async {
      await real.putAll({
        'store_name': 'Shop',
        'onboarding_complete': true,
        kFactoryResetPendingKey: true,
      });
      final tmp = Directory(p.join(docs.path, 'tmp'))..createSync();
      final copy = await settingsCopyWithoutResetFlag(tmp, DateTime(2026));
      expect(copy, isNotNull);
      expect(real.containsKey(kFactoryResetPendingKey), isTrue,
          reason: 'the live box is untouched');
      // Read the copy back as a box, as a restore would.
      final check = Directory(p.join(docs.path, 'check'))..createSync();
      copy!.copySync(p.join(check.path, 'restored.hive'));
      final restored =
          await Hive.openBox<dynamic>('restored', path: check.path);
      expect(restored.containsKey(kFactoryResetPendingKey), isFalse);
      expect(restored.get('store_name'), 'Shop');
      expect(restored.get('onboarding_complete'), true);
    });
  });

  group('the blocking question', () {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    late AppDatabase db;

    setUp(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => docs.path);
      await Hive.openBox<dynamic>('held_orders');
      // Open on the real clock now, so no widget opens it lazily inside the
      // fake-async zone (an open left pending there outlives the test).
      await Hive.openBox<dynamic>(kUsageBoxName);
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    Future<ProviderContainer> shopWithPendingFlag(WidgetTester tester) async {
      late ProviderContainer c;
      await tester.runAsync(() async {
        db = AppDatabase(NativeDatabase.memory());
        await seedProduct(db, sku: 'A');
        await real.putAll({
          'onboarding_complete': true,
          // A shop already on this version: the What's new check writes
          // nothing, so no Hive write is left pending in the fake zone.
          kWhatsNewSeenKey: kAppVersion,
          kFactoryResetPendingKey: true,
        });
        c = ProviderContainer(
            overrides: [databaseProvider.overrideWithValue(db)]);
      });
      return c;
    }

    Future<void> launch(WidgetTester tester, ProviderContainer c) async {
      late Future<StartupResult> startup;
      await tester.runAsync(() async {
        startup = startUp(
          recover: () async => RestoreRecovery.none,
          initHive: () async {},
          openStores: () async {},
          checkDatabase: () async {},
          finishFactoryReset: () =>
              finishPendingFactoryResetOnLaunch(() => c.read(databaseProvider)),
        );
      });
      await tester.pumpWidget(AppRoot(container: c, startup: startup));
      await pumpUntil(
          tester, () => find.text(kResetChoiceTitle).evaluate().isNotEmpty);
      expect(find.text(kResetChoiceMessage), findsOneWidget);
      expect(find.text('Finish erasing'), findsOneWidget);
      expect(find.text('Keep my data'), findsOneWidget);
      expect(find.byType(POSApp), findsNothing, reason: 'blocking');
    }

    Future<void> done(WidgetTester tester) => tester.runAsync(() async {
          await tester.pumpWidget(const SizedBox());
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });

    testWidgets(
        'a pending flag on a shop with data: asked, nothing erased; Keep '
        'my data clears the flag and opens the shop', (tester) async {
      final c = await shopWithPendingFlag(tester);
      await launch(tester, c);
      expect(await tester.runAsync(() => hasUserData(db)), isTrue);

      await tester.runAsync(() => tester.tap(find.text('Keep my data')));
      await pumpUntil(tester, () => find.byType(POSApp).evaluate().isNotEmpty);
      expect(real.containsKey(kFactoryResetPendingKey), isFalse);
      expect(find.text(kResetKeptNotice), findsOneWidget);
      expect(await tester.runAsync(() => hasUserData(db)), isTrue);
      await tester
          .pump(const Duration(seconds: 5)); // the toast, not the backup
      await done(tester);
    });

    testWidgets('Finish erasing erases and comes back on onboarding',
        (tester) async {
      final c = await shopWithPendingFlag(tester);
      await launch(tester, c);
      final state = tester.state<AppRootState>(find.byType(AppRoot));
      await tester.runAsync(() => tester.tap(find.text('Finish erasing')));
      await pumpUntil(
          tester, () => find.byType(OnboardingScreen).evaluate().isNotEmpty);
      final fresh = state.containerForTest.read(databaseProvider);
      expect(await tester.runAsync(() => hasUserData(fresh)), isFalse);
      expect(real.containsKey(kFactoryResetPendingKey), isFalse);
      await done(tester);
    });
  });

  group('the app', () {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    setUp(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => docs.path);
      await Hive.openBox<dynamic>('held_orders');
      await Hive.openBox<dynamic>(kUsageBoxName);
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    Future<void> done(WidgetTester tester) => tester.runAsync(() async {
          await tester.pumpWidget(const SizedBox());
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });

    testWidgets(
        'Finish erasing that cannot write says so and keeps the question',
        (tester) async {
      late ProviderContainer c;
      await tester.runAsync(() async {
        final db = AppDatabase(NativeDatabase.memory());
        await db.customSelect('SELECT 1').get();
        await db.close(); // every erase now fails
        c = ProviderContainer(
            overrides: [databaseProvider.overrideWithValue(db)]);
        await real.put(kFactoryResetPendingKey, true);
      });
      settings.failDeletes = 999; // and the flag will not clear
      await tester.pumpWidget(AppRoot(
        container: c,
        startup: Future.value(const StartupResult(resetChoice: true)),
        settingsBoxForTest: settings,
      ));
      await tester.pump();
      await tester.pump();
      expect(find.text(kResetChoiceTitle), findsOneWidget);
      expect(find.text(kResetFinishFailed), findsNothing);

      await tester.runAsync(() => tester.tap(find.text('Finish erasing')));
      await pumpUntil(
          tester, () => find.text(kResetFinishFailed).evaluate().isNotEmpty);
      expect(
          find.text(
              "Couldn't finish erasing. Free up some space on this device, "
              'then try again.'),
          findsOneWidget);
      expect(find.text(kResetChoiceTitle), findsOneWidget);
      expect(real.containsKey(kFactoryResetPendingKey), isTrue);
      await done(tester);
    });

    Future<void> startFresh(WidgetTester tester) async {
      await tester.pumpWidget(AppRoot(
        startupDbError: SqliteException(26, 'file is not a database'),
        settingsBoxForTest: settings,
      ));
      expect(find.text(kStartFreshButton), findsOneWidget);
      // Run on the real clock, not awaited (it waits for frames); the
      // confirm dialog itself is covered in open_failure_recovery_test.
      final state = tester.state<AppRootState>(find.byType(AppRoot));
      await tester.runAsync(() async {
        unawaited(state.startFresh());
      });
    }

    testWidgets('Start fresh clears a leftover reset flag', (tester) async {
      await tester.runAsync(() async {
        await real.putAll({
          'onboarding_complete': true,
          kWhatsNewSeenKey: kAppVersion,
          kFactoryResetPendingKey: true,
        });
        File(p.join(docs.path, 'pos_database.db')).writeAsStringSync('junk');
      });
      await startFresh(tester);
      await pumpUntil(tester, () => find.byType(POSApp).evaluate().isNotEmpty);
      expect(real.containsKey(kFactoryResetPendingKey), isFalse,
          reason: 'the next launch must not wipe the fresh shop settings');
      expect(find.text(kStartFreshDoneNotice), findsOneWidget);
      await tester.pump(const Duration(seconds: 9));
      await done(tester);
    });

    testWidgets(
        '… and refuses, touching nothing, when it cannot clear it first '
        '(so no kill can leave the flag set over a set-aside database)',
        (tester) async {
      final file = File(p.join(docs.path, 'pos_database.db'));
      await tester.runAsync(() async {
        await real.putAll(
            {'onboarding_complete': true, kFactoryResetPendingKey: true});
        file.writeAsStringSync('junk');
      });
      settings.failDeletes = 999;
      await startFresh(tester);
      await pumpUntil(
          tester, () => find.text(kStartFreshCannotSave).evaluate().isNotEmpty);
      expect(
          find.text("Open POS couldn't save a change. Free up some space on "
              'this device, then try again.'),
          findsOneWidget);
      expect(find.byType(POSApp), findsNothing);
      expect(file.readAsStringSync(), 'junk', reason: 'not set aside');
      expect(
          docs.listSync().where((e) => e.path.contains('.broken-')), isEmpty);
      expect(real.containsKey(kFactoryResetPendingKey), isTrue);
      await done(tester);
    });

    // Replaces the old "kill between set-aside and flag clear" test: that
    // state can no longer arise, because the flag is cleared (confirmed)
    // while the database is still in place. This proves the order.
    testWidgets(
        'kill-point closed: Start fresh clears the flag before it sets the '
        'database aside', (tester) async {
      final file = File(p.join(docs.path, 'pos_database.db'));
      await tester.runAsync(() async {
        await real.putAll({
          'onboarding_complete': true,
          kWhatsNewSeenKey: kAppVersion,
          kFactoryResetPendingKey: true,
        });
        file.writeAsStringSync('junk');
      });
      bool? dbInPlaceAtClear;
      settings.onDelete = (key) {
        if (key == kFactoryResetPendingKey) {
          dbInPlaceAtClear ??= file.existsSync();
        }
      };
      await startFresh(tester);
      await pumpUntil(tester, () => find.byType(POSApp).evaluate().isNotEmpty);
      expect(dbInPlaceAtClear, isTrue,
          reason: 'the flag went before the file was moved');
      expect(real.containsKey(kFactoryResetPendingKey), isFalse);
      expect(docs.listSync().where((e) => e.path.contains('.broken-')),
          isNotEmpty);
      await tester.pump(const Duration(seconds: 9));
      await done(tester);
    });
  });
}
