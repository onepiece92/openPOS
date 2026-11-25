import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/domain/usage_summary.dart';

/// The usage box travels with backups; after a restore it is merged back
/// like the review state: max count, earliest first month, latest last
/// month, and this device's flags.
void main() {
  test('usage is a snapshot box, but not opened at startup', () {
    expect(kSnapshotHiveBoxes, ['settings', 'held_orders', kUsageBoxName]);
    expect(kStartupHiveBoxes, isNot(contains(kUsageBoxName)));
    expect(defaultHiveBoxPaths(Directory('/docs')),
        contains(p.join('/docs', 'usage.hive')),
        reason: 'restore recovery must put usage.hive back too');
  });

  group('mergeUsageBox', () {
    late Directory tmp;
    late Box<dynamic> box;
    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('pos_usage_merge_');
      Hive.init(tmp.path);
      box = await Hive.openBox<dynamic>(kUsageBoxName);
    });
    tearDown(() async {
      await Hive.close();
      await tmp.delete(recursive: true);
    });

    test('max count, earliest first, latest last; device flags kept', () async {
      // The restored (backup) box:
      await box.putAll({
        'e.saleCompleted': {'c': 300, 'f': '2026-01', 'l': '2026-06'},
        'e.csvImported': {'c': 2, 'f': '2026-02', 'l': '2026-02'},
        kUsageCountingOnKey: false,
        kUsageDisclosureShownKey: true,
        kUsageAskedVersionKey: '1.0.0+9',
      });
      // This device, before the restore:
      const before = UsageSnapshot(
        counts: {
          UsageEvent.saleCompleted:
              UsageCount(120, firstMonth: '2026-05', lastMonth: '2026-11'),
          UsageEvent.reportViewed:
              UsageCount(4, firstMonth: '2026-11', lastMonth: '2026-11'),
        },
        countingOn: true,
        disclosureShown: null, // never shown on this device
        askedVersion: '1.1.0+10',
      );
      await mergeUsageBox(box, before);
      expect(readUsageCounts(box), {
        UsageEvent.saleCompleted:
            const UsageCount(300, firstMonth: '2026-01', lastMonth: '2026-11'),
        UsageEvent.csvImported:
            const UsageCount(2, firstMonth: '2026-02', lastMonth: '2026-02'),
        UsageEvent.reportViewed:
            const UsageCount(4, firstMonth: '2026-11', lastMonth: '2026-11'),
      });
      expect(box.get(kUsageCountingOnKey), isTrue);
      expect(box.containsKey(kUsageDisclosureShownKey), isFalse);
      expect(box.get(kUsageAskedVersionKey), '1.1.0+10');
    });

    test('merging the box with its own snapshot changes nothing', () async {
      await box.putAll({
        'e.ticketHeld': {'c': 7, 'f': '2026-03', 'l': '2026-09'},
        kUsageCountingOnKey: true,
      });
      final before = UsageSnapshot.of(box);
      final snapshot = box.toMap();
      await mergeUsageBox(box, before);
      expect(box.toMap(), snapshot);
    });

    test('helpers never throw when the box is closed', () async {
      await box.close();
      expect(usageSnapshotBeforeRestore(), isNull);
      await mergeUsageAfterRestore(null);
      await mergeUsageAfterRestore(const UsageSnapshot(counts: {}));
    });
  });

  group('real restore, like AppRoot.restoreFrom', () {
    const svc = SnapshotService();
    const schema = AppDatabase.currentSchemaVersion;
    late Directory tmp;
    late Directory live;
    late Directory old;

    File dbIn(Directory d) => File(p.join(d.path, 'pos_database.db'));
    Map<String, String> boxesIn(Directory d, List<String> names) =>
        {for (final n in names) n: p.join(d.path, '$n.hive')};

    Future<void> seed(
        Directory dir, Map<String, Map<String, Object>> boxes) async {
      final db = AppDatabase(NativeDatabase(dbIn(dir)));
      await db.customSelect('SELECT 1').get();
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
      await db.close();
      Hive.init(dir.path);
      for (final e in boxes.entries) {
        final b = await Hive.openBox<dynamic>(e.key);
        await b.putAll(e.value);
        await b.flush();
      }
      await Hive.close();
    }

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('pos_usage_restore_');
      live = await Directory(p.join(tmp.path, 'live')).create();
      old = await Directory(p.join(tmp.path, 'old')).create();
    });
    tearDown(() async {
      await Hive.close();
      await tmp.delete(recursive: true);
    });

    Future<void> restore(File zip) async {
      Hive.init(live.path);
      for (final n in kSnapshotHiveBoxes) {
        await Hive.openBox<dynamic>(n);
      }
      final before = usageSnapshotBeforeRestore();
      expect(before, isNotNull);
      await Hive.close();
      await svc.restoreWithRollback(
        journal: SnapshotService.journalFileFor(dbIn(live)),
        swap: () => svc.restore(
          zip: zip,
          dbFile: dbIn(live),
          hiveBoxFiles: boxesIn(live, kSnapshotHiveBoxes),
          currentSchemaVersion: schema,
        ),
        reopen: () async {
          Hive.init(live.path);
          for (final n in kSnapshotHiveBoxes) {
            await Hive.openBox<dynamic>(n);
          }
        },
        release: Hive.close,
      );
      await mergeUsageAfterRestore(before);
    }

    test('a backup with a usage box is merged with the device', () async {
      await seed(old, {
        'settings': {'k': 'old'},
        kUsageBoxName: {
          'e.saleCompleted': {'c': 500, 'f': '2025-12', 'l': '2026-04'},
          kUsageCountingOnKey: false,
        },
      });
      final zip = await svc.create(
          dbFile: dbIn(old),
          hiveBoxFiles: boxesIn(old, kSnapshotHiveBoxes),
          outDir: tmp,
          schemaVersion: schema);
      await seed(live, {
        'settings': {'k': 'live'},
        kUsageBoxName: {
          'e.saleCompleted': {'c': 80, 'f': '2026-10', 'l': '2026-11'},
          kUsageDisclosureShownKey: true,
        },
      });
      await restore(zip);
      final box = Hive.box<dynamic>(kUsageBoxName);
      expect(Hive.box<dynamic>('settings').get('k'), 'old');
      expect(readUsageCounts(box)[UsageEvent.saleCompleted],
          const UsageCount(500, firstMonth: '2025-12', lastMonth: '2026-11'));
      expect(box.containsKey(kUsageCountingOnKey), isFalse,
          reason: "the device's (default) counting flag is kept");
      expect(box.get(kUsageDisclosureShownKey), isTrue);
    });

    test('an older backup without a usage box leaves the device box as is',
        () async {
      await seed(old, {
        'settings': {'k': 'old'},
      });
      final zip = await svc.create(
          dbFile: dbIn(old),
          hiveBoxFiles: boxesIn(old, ['settings']),
          outDir: tmp,
          schemaVersion: schema);
      await seed(live, {
        kUsageBoxName: {
          'e.csvExported': {'c': 3, 'f': '2026-11', 'l': '2026-11'},
        },
      });
      await restore(zip);
      expect(readUsageCounts(Hive.box<dynamic>(kUsageBoxName)), {
        UsageEvent.csvExported:
            const UsageCount(3, firstMonth: '2026-11', lastMonth: '2026-11')
      });
    });
  });
}
