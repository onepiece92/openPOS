import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/hive_provider.dart' show kAutoBackupLastAt;
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/features/cart/data/ticket_sequence.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/settings/data/factory_reset.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/startup.dart';

import '../../_support/sales.dart';

class _Kill implements Exception {}

/// Factory reset is resumable: a kill at any point leaves, after the next
/// launch, either the old shop intact or a clean fresh shop — never a mix.
void main() {
  late Directory docs;
  late AppDatabase db;
  late Box<dynamic> settings, held, usage;
  Directory receipts() => Directory(p.join(docs.path, 'receipts'));
  File dbFile() => File(p.join(docs.path, 'pos.db'));
  const lastBackup = '2026-11-01T09:00:00.000';

  Future<void> openStores() async {
    db = AppDatabase(NativeDatabase(dbFile()));
    settings = await Hive.openBox<dynamic>('settings');
    held = await Hive.openBox<dynamic>('held_orders');
    usage = await Hive.openBox<dynamic>(kUsageBoxName);
  }

  /// The kill: everything in memory is gone; only the disk is left.
  Future<void> relaunch() async {
    await db.close();
    await Hive.close();
    await openStores();
  }

  setUp(() async {
    docs = Directory.systemTemp.createTempSync('pos_reset_resume_');
    Hive.init(docs.path);
    await openStores();
    // The old shop.
    final pid = await seedProduct(db, sku: 'A');
    await sell(db, AuditService(db), [line(pid)]);
    await settings.putAll({
      'onboarding_complete': true,
      'store_name': 'Old Shop',
      kAutoBackupLastAt: lastBackup,
    });
    await held.put(
        't1',
        jsonEncode(HeldOrder(
                id: 't1',
                ticketNumber: '#0005',
                label: '#0005',
                createdAt: DateTime(2026, 1, 1),
                items: const [])
            .toJson()));
    await held.put(kTicketSeqKey, 5);
    await usage.put(kUsageDisclosureShownKey, true);
    receipts().createSync();
    File(p.join(receipts().path, 'r.jpg')).writeAsBytesSync([1]);
  });

  tearDown(() async {
    await db.close();
    await Hive.close();
    docs.deleteSync(recursive: true);
  });

  Future<int> rows(String table) async => (await db
          .customSelect('SELECT COUNT(*) AS n FROM "$table"')
          .getSingle())
      .read<int>('n');

  /// Exactly one of the two allowed states, judged on every store.
  Future<String> shopState() async {
    final old = [
      await rows('products') > 0,
      await rows('orders') > 0,
      settings.get('onboarding_complete') == true,
      settings.get('store_name') == 'Old Shop',
      held.containsKey('t1'),
      usage.containsKey(kUsageDisclosureShownKey),
      receipts().existsSync(),
    ];
    if (old.every((x) => x)) {
      expect(isFactoryResetPending(settings), isFalse);
      return 'old';
    }
    if (old.every((x) => !x)) {
      expect(isFactoryResetPending(settings), isFalse);
      expect(settings.get(kAutoBackupLastAt), lastBackup,
          reason: 'the last automatic backup time survives');
      expect(held.get(kTicketSeqKey), 5, reason: 'ticket numbers never repeat');
      expect(await rows('expense_categories'), greaterThan(0),
          reason: 'first-run defaults reseeded');
      return 'fresh';
    }
    fail('a mix of old and erased data: $old');
  }

  Future<FactoryResetOutcome> reset({FactoryResetStep? killAt}) =>
      runFactoryReset(
        settings: settings,
        eraseDatabase: db.eraseAllData,
        releaseDatabase: () async {},
        heldOrders: held,
        usage: () async => usage,
        receipts: () async => receipts(),
        afterStep: (s) {
          if (s == killAt) throw _Kill();
        },
      );

  /// What the next launch does (startUp step 5).
  Future<bool> finishOnLaunch() => finishPendingFactoryReset(
        settings: settings,
        eraseDatabase: db.eraseAllData,
        heldOrders: held,
        usage: () async => usage,
        receipts: () async => receipts(),
      );

  test('killed before the reset started: the old shop, untouched', () async {
    await relaunch();
    expect(await finishOnLaunch(), isFalse);
    expect(await shopState(), 'old');
  });

  for (final step in FactoryResetStep.values) {
    test('killed after "${step.name}": the next launch is a fresh shop',
        () async {
      try {
        await reset(killAt: step);
      } on _Kill {/* the app died here */}
      await relaunch();
      final finished = await finishOnLaunch();
      expect(finished, step != FactoryResetStep.settingsCleared,
          reason: 'pending until the very last write');
      expect(await shopState(), 'fresh');
    });
  }

  test(
      'killed with the flag written but the DB erase not committed: '
      'finished on launch', () async {
    await markFactoryResetPending(settings);
    // (eraseAllData never committed.)
    await relaunch();
    expect(await rows('products'), greaterThan(0));
    expect(await finishOnLaunch(), isTrue);
    expect(await shopState(), 'fresh');
  });

  test('a torn settings write keeps the flag, so it is finished', () async {
    await markFactoryResetPending(settings);
    await db.eraseAllData();
    await clearHeldTicketsKeepingCounter(held);
    await usage.clear();
    await receipts().delete(recursive: true);
    // Half the settings deleteAll reached the disk; the flag is last.
    await settings.delete('onboarding_complete');
    await relaunch();
    expect(isFactoryResetPending(settings), isTrue);
    expect(await finishOnLaunch(), isTrue);
    expect(await shopState(), 'fresh');
  });

  test('a clean reset: done, fresh, nothing pending', () async {
    expect(await reset(), FactoryResetOutcome.done);
    expect(await shopState(), 'fresh');
    await relaunch();
    expect(await finishOnLaunch(), isFalse);
    expect(await shopState(), 'fresh');
  });

  test('the old connection failing to close is caught; the reset finishes',
      () async {
    final outcome = await runFactoryReset(
      settings: settings,
      eraseDatabase: db.eraseAllData,
      releaseDatabase: () async => throw StateError('close failed'),
      heldOrders: held,
      usage: () async => usage,
      receipts: () async => receipts(),
    );
    expect(outcome, FactoryResetOutcome.done);
    expect(await shopState(), 'fresh');
  });

  test('a refused DB erase changes nothing and leaves nothing pending',
      () async {
    final outcome = await runFactoryReset(
      settings: settings,
      eraseDatabase: () async => throw StateError('disk full'),
      releaseDatabase: () async {},
      heldOrders: held,
      usage: () async => usage,
      receipts: () async => receipts(),
    );
    expect(outcome, FactoryResetOutcome.refused);
    expect(await shopState(), 'old');
    await relaunch();
    expect(await finishOnLaunch(), isFalse);
    expect(await shopState(), 'old');
  });

  test('a local store that fails to clear: incomplete, still pending',
      () async {
    final outcome = await runFactoryReset(
      settings: settings,
      eraseDatabase: db.eraseAllData,
      releaseDatabase: () async {},
      heldOrders: held,
      usage: () async => usage,
      receipts: () async => throw const FileSystemException('busy'),
    );
    expect(outcome, FactoryResetOutcome.incomplete);
    expect(isFactoryResetPending(settings), isTrue);
    await relaunch();
    expect(await finishOnLaunch(), isTrue);
    expect(await shopState(), 'fresh');
  });

  test('startUp finishes a pending reset after the DB check, then toasts',
      () async {
    await markFactoryResetPending(settings);
    await relaunch();
    final order = <String>[];
    final r = await startUp(
      recover: () async => RestoreRecovery.none,
      initHive: () async {},
      openStores: () async => order.add('openStores'),
      checkDatabase: () async => order.add('check'),
      finishFactoryReset: () async {
        order.add('finish');
        return finishOnLaunch();
      },
    );
    expect(order, ['openStores', 'check', 'finish']);
    expect(r.notice, kFactoryResetFinishedNotice);
    expect(await shopState(), 'fresh');
  });

  test('startUp: a finish that fails goes to the error screen', () async {
    final r = await startUp(
      recover: () async => RestoreRecovery.none,
      initHive: () async {},
      openStores: () async {},
      checkDatabase: () async {},
      finishFactoryReset: () async => throw StateError('disk'),
    );
    expect(r.dbError, isA<StateError>());
  });
}
