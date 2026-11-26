import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/app_root.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/connection/native.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/cart/data/ticket_sequence.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';

import 'app_root_retry_test.dart' show pumpUntil;

/// Factory Reset end to end: the app restarts like a first run.
void main() {
  late Directory docs;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() {
    docs = Directory.systemTemp.createTempSync('pos_reset_restart_');
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
      'erases everything listed, keeps the ticket counter and automatic '
      'backups, and comes back on onboarding; the usage notice shows once',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1600);
    addTearDown(tester.view.reset);
    final receipts = Directory(p.join(docs.path, 'receipts'));
    final backup = File(p.join(docs.path, 'backups', 'auto', 'auto.zip'));
    await tester.runAsync(() async {
      final db = AppDatabase(
          NativeDatabase(File(p.join(docs.path, kDatabaseFileName))));
      await db.into(db.tables).insert(TablesCompanion.insert(name: 'T1'));
      await db.close();
      final settings = await Hive.openBox<dynamic>('settings');
      await settings.put('onboarding_complete', true);
      final held = await Hive.openBox<dynamic>('held_orders');
      await held.put(
          't1',
          jsonEncode(HeldOrder(
              id: 't1',
              ticketNumber: '#0005',
              label: '#0005',
              createdAt: DateTime(2026, 1, 1),
              items: const []).toJson()));
      await held.put(kTicketSeqKey, 5);
      final usage = await Hive.openBox<dynamic>(kUsageBoxName);
      await usage.put(kUsageDisclosureShownKey, true);
      receipts.createSync();
      File(p.join(receipts.path, 'r.jpg')).writeAsBytesSync([1]);
      backup.parent.createSync(recursive: true);
      backup.writeAsBytesSync([9]);
    });

    await tester.pumpWidget(const AppRoot());
    final state = tester.state<AppRootState>(find.byType(AppRoot));
    final before = state.containerForTest;
    await tester.pump();
    expect(find.byType(OnboardingScreen), findsNothing);

    // Started on the real clock (like a tap in AppRoot's retry test), so
    // its file writes finish; not awaited: it waits for a frame, which
    // pumpUntil pumps.
    late Future<void> reset;
    await tester.runAsync(() async {
      reset = state.factoryReset();
    });
    await pumpUntil(
        tester, () => find.byType(OnboardingScreen).evaluate().isNotEmpty);

    await tester.runAsync(() => reset);
    final c = state.containerForTest;
    expect(identical(c, before), isFalse, reason: 'a fresh container');
    final db = c.read(databaseProvider);
    final tables = await tester.runAsync(() => db.select(db.tables).get());
    expect(tables, isEmpty);
    final held = Hive.box<dynamic>('held_orders');
    expect(held.keys, [kTicketSeqKey]);
    expect(held.get(kTicketSeqKey), 5);
    expect(
        Hive.box<dynamic>(kUsageBoxName).get(kUsageDisclosureShownKey), isNull);
    expect(Hive.box<dynamic>('settings').get('onboarding_complete'), isNull);
    expect(receipts.existsSync(), isFalse);
    expect(backup.existsSync(), isTrue);
    expect(state.autoBackupScheduledForTest, isFalse,
        reason: 'no backup of the empty data right after a reset');

    // Not over onboarding; once it is done, the usage notice shows once.
    final disclosure = find.byKey(const ValueKey('usage-disclosure'));
    expect(disclosure, findsNothing);
    await tester.runAsync(
        () => c.read(settingsProvider.notifier).setOnboardingComplete(true));
    await pumpUntil(tester, () => disclosure.evaluate().isNotEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(disclosure, findsOneWidget);

    await tester.runAsync(() async {
      await tester.pumpWidget(const SizedBox());
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
  });
}
