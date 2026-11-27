import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/hive_provider.dart'
    show kAutoBackupLastAt;
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart'
    show hasUserData;
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
  File broken() => File('${dbFile().path}.broken-20261101-090000');
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
            items: const []).toJson()));
    await held.put(kTicketSeqKey, 5);
    await usage.put(kUsageDisclosureShownKey, true);
    receipts().createSync();
    File(p.join(receipts().path, 'r.jpg')).writeAsBytesSync([1]);
    // A damaged database set aside earlier by "Start fresh".
    broken().writeAsStringSync('old sales');
  });

  tearDown(() async {
    await db.close();
    await Hive.close();
    docs.deleteSync(recursive: true);
  });

  Future<int> rows(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM "$table"').getSingle())
          .read<int>('n');

  /// Exactly one of the allowed states, judged on every store: 'old' (the
  /// shop intact, nothing pending), 'old, asking' (intact with the flag
  /// still set — the launch asks before erasing) or 'fresh'.
  Future<String> shopState() async {
    final old = [
      await rows('products') > 0,
      await rows('orders') > 0,
      settings.get('onboarding_complete') == true,
      settings.get('store_name') == 'Old Shop',
      held.containsKey('t1'),
      usage.containsKey(kUsageDisclosureShownKey),
      receipts().existsSync(),
      broken().existsSync(),
    ];
    if (old.every((x) => x)) {
      return isFactoryResetPending(settings) ? 'old, asking' : 'old';
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
        database: () async => dbFile(),
        afterStep: (s) {
          if (s == killAt) throw _Kill();
        },
      );

  /// What the next launch does (startUp step 5).
  Future<PendingFactoryReset> finishOnLaunch() => finishPendingFactoryReset(
        settings: settings,
        databaseHasUserData: () => hasUserData(db),
        eraseDatabase: db.eraseAllData,
        heldOrders: held,
        usage: () async => usage,
        receipts: () async => receipts(),
        database: () async => dbFile(),
      );

  test('killed before the reset started: the old shop, untouched', () async {
    await relaunch();
    expect(await finishOnLaunch(), PendingFactoryReset.none);
    expect(await shopState(), 'old');
  });

  for (final step in FactoryResetStep.values) {
    final beforeCommit = step == FactoryResetStep.flagWritten;
    test(
        'killed after "${step.name}": the next launch '
        '${beforeCommit ? 'asks (the data is still there)' : 'is a fresh shop'}',
        () async {
      try {
        await reset(killAt: step);
      } on _Kill {/* the app died here */}
      await relaunch();
      final pending = await finishOnLaunch();
      if (beforeCommit) {
        expect(pending, PendingFactoryReset.askUser);
        expect(await shopState(), 'old, asking', reason: 'nothing erased');
        return;
      }
      expect(
          pending,
          step == FactoryResetStep.settingsCleared
              ? PendingFactoryReset.none
              : PendingFactoryReset.finished,
          reason: 'pending until the very last write');
      expect(await shopState(), 'fresh');
    });
  }

  test(
      'the flag written but the DB erase not committed: the launch asks, '
      'never erases; Keep my data keeps it', () async {
    await markFactoryResetPending(settings);
    // (eraseAllData never committed.)
    await relaunch();
    expect(await finishOnLaunch(), PendingFactoryReset.askUser);
    expect(await shopState(), 'old, asking');
    expect(await clearFactoryResetPendingConfirmed(settings), isTrue);
    await relaunch();
    expect(await finishOnLaunch(), PendingFactoryReset.none);
    expect(await shopState(), 'old');
  });

  test('… and Finish erasing (a fresh reset run) gives a fresh shop', () async {
    await markFactoryResetPending(settings);
    await relaunch();
    expect(await finishOnLaunch(), PendingFactoryReset.askUser);
    expect(await reset(), FactoryResetOutcome.done);
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
    expect(await finishOnLaunch(), PendingFactoryReset.finished);
    expect(await shopState(), 'fresh');
  });

  test('a clean reset: done, fresh, nothing pending', () async {
    expect(await reset(), FactoryResetOutcome.done);
    expect(await shopState(), 'fresh');
    await relaunch();
    expect(await finishOnLaunch(), PendingFactoryReset.none);
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
      database: () async => dbFile(),
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
      database: () async => dbFile(),
    );
    expect(outcome, FactoryResetOutcome.refused);
    expect(await shopState(), 'old');
    await relaunch();
    expect(await finishOnLaunch(), PendingFactoryReset.none);
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
    expect(await finishOnLaunch(), PendingFactoryReset.finished);
    expect(await shopState(), 'fresh');
  });

  test('startUp asks (resetChoice) when the pending reset finds data',
      () async {
    await markFactoryResetPending(settings);
    await relaunch();
    final r = await startUp(
      recover: () async => RestoreRecovery.none,
      initHive: () async {},
      openStores: () async {},
      checkDatabase: () async {},
      finishFactoryReset: finishOnLaunch,
    );
    expect(r.resetChoice, isTrue);
    expect(r.notice, isNull);
    expect(await shopState(), 'old, asking');
  });

  test('startUp finishes a pending reset after the DB check, then toasts',
      () async {
    await markFactoryResetPending(settings);
    await db.eraseAllData(); // the kill came after the commit
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
