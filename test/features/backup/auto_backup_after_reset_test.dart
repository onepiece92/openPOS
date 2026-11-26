import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/features/settings/data/factory_reset.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';

import '../../_support/sales.dart';

/// The automatic backups kept on the device are how a regretted factory
/// reset is undone: backups of the empty data must never push them out.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory docs;
  late AppDatabase db;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    docs = Directory.systemTemp.createTempSync('pos_auto_reset_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => docs.path);
    Hive.init(docs.path);
    for (final name in kSnapshotHiveBoxes) {
      await Hive.openBox<dynamic>(name);
    }
    db = AppDatabase(NativeDatabase(File(p.join(docs.path, 'pos.db'))));
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await db.close();
    await Hive.close();
    docs.deleteSync(recursive: true);
  });

  ProviderContainer launch() {
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Set<String> backupNames() => {
        for (final f in Directory(p.join(docs.path, 'backups', 'auto'))
            .listSync()
            .whereType<File>())
          p.basename(f.path)
      };

  test('after a reset, 8 days of launches with no data leave the 7 '
      'pre-reset backups untouched; data brings the backups back', () async {
    final day0 = DateTime(2026, 11, 1, 9);
    // Seven automatic backups from before the reset, one a day.
    final auto = Directory(p.join(docs.path, 'backups', 'auto'))
      ..createSync(recursive: true);
    for (var i = 0; i < kAutoBackupKeep; i++) {
      File(p.join(auto.path,
          '${SnapshotService.filePrefix}pre_$i${SnapshotService.fileSuffix}'))
        ..writeAsBytesSync([i])
        ..setLastModifiedSync(day0.subtract(Duration(days: 7 - i)));
    }
    final before = backupNames();
    expect(before, hasLength(kAutoBackupKeep));

    // The reset: data erased, settings cleared but the last run kept.
    final settings = Hive.box<dynamic>('settings');
    await settings.put('onboarding_complete', true);
    await settings.put(kAutoBackupLastAt, day0.toIso8601String());
    await seedProduct(db, sku: 'A');
    await db.eraseAllData();
    await eraseLocalStores(
      settings: settings,
      heldOrders: Hive.box<dynamic>('held_orders'),
      usage: Hive.box<dynamic>(kUsageBoxName),
      receipts: Directory(p.join(docs.path, 'receipts')),
    );
    expect(settings.get(kAutoBackupLastAt), day0.toIso8601String());
    expect(settings.containsKey('onboarding_complete'), isFalse);
    expect(await hasUserData(db), isFalse,
        reason: 'the reseeded expense categories are not user data');

    // A launch a day for 8 days, every one with a backup due.
    for (var d = 1; d <= 8; d++) {
      final c = launch();
      final made = await c
          .read(snapshotCoordinatorProvider)
          .runAutoBackupIfDue(now: day0.add(Duration(days: d)));
      expect(made, isNull, reason: 'day $d: nothing to back up');
      c.dispose();
    }
    expect(backupNames(), before, reason: 'all 7 kept, none added');
    expect(settings.get(kAutoBackupLastAt), day0.toIso8601String());

    // A product: the next due backup runs and pruning keeps the newest 7.
    await seedProduct(db, sku: 'B');
    expect(await hasUserData(db), isTrue);
    final c = launch();
    final made = await c
        .read(snapshotCoordinatorProvider)
        .runAutoBackupIfDue(now: day0.add(const Duration(days: 9)));
    expect(made, isNotNull);
    final after = backupNames();
    expect(after, hasLength(kAutoBackupKeep));
    expect(after, contains(p.basename(made!.path)));
    expect(after.difference(before), {p.basename(made.path)});
    expect(before.difference(after),
        {'${SnapshotService.filePrefix}pre_0${SnapshotService.fileSuffix}'},
        reason: 'only the oldest pre-reset backup made room');
  });

  test('each kind of user data counts', () async {
    expect(await hasUserData(db), isFalse);
    final cid = await seedCustomer(db);
    expect(await hasUserData(db), isTrue);
    await (db.delete(db.customers)..where((x) => x.id.equals(cid))).go();
    final cat = (await db.select(db.expenseCategories).get()).first;
    await db.into(db.expenses).insert(ExpensesCompanion.insert(
        categoryId: cat.id, amount: 1, date: DateTime(2026, 1, 1)));
    expect(await hasUserData(db), isTrue);
  });

  test('a backup that is not due runs no data query', () async {
    await Hive.box<dynamic>('settings')
        .put(kAutoBackupLastAt, DateTime(2026, 11, 1).toIso8601String());
    // Closed database: any query would fail the backup; none is made.
    await db.close();
    final c = launch();
    final made = await c
        .read(snapshotCoordinatorProvider)
        .runAutoBackupIfDue(now: DateTime(2026, 11, 1, 12));
    expect(made, isNull);
    expect(autoBackupLastError.value, isNull);
    db = AppDatabase(NativeDatabase.memory()); // for tearDown
  });
}
