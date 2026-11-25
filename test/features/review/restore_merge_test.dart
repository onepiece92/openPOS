import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/features/review/data/review_state_store.dart';
import 'package:pos_app/features/review/domain/review_policy.dart';

/// The restore flow replaces the settings box, which also holds the review
/// reminder's bookkeeping. These tests run the same sequence as
/// `AppRoot.restoreFrom` — capture, close Hive, swap real files with
/// [SnapshotService.restoreWithRollback], reopen, merge — on real files.
void main() {
  const svc = SnapshotService();
  const schema = AppDatabase.currentSchemaVersion;
  late Directory tmp;
  late Directory live;
  late Directory old;

  File dbFileIn(Directory d) => File(p.join(d.path, 'pos_database.db'));
  String hivePathIn(Directory d) => p.join(d.path, 'settings.hive');

  final installedOld = DateTime(2026, 1, 10);
  final promptedOld = DateTime(2026, 3, 1);
  final installedLive = DateTime(2026, 2, 1);
  final promptedLive = DateTime(2026, 9, 1);

  Future<void> seed(Directory dir, Map<String, Object?> settings) async {
    final db = AppDatabase(NativeDatabase(dbFileIn(dir)));
    await db.customSelect('SELECT 1').get();
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    await db.close();
    Hive.init(dir.path);
    final box = await Hive.openBox<dynamic>('settings');
    await box.putAll(settings);
    await box.flush();
    await Hive.close();
  }

  Future<File> backupOf(Directory dir) => svc.create(
        dbFile: dbFileIn(dir),
        hiveBoxFiles: {'settings': hivePathIn(dir)},
        outDir: tmp,
        schemaVersion: schema,
      );

  Future<void> openLive() async {
    Hive.init(live.path);
    await Hive.openBox<dynamic>('settings');
  }

  ReviewState liveState() =>
      ReviewStateStore(Hive.box<dynamic>('settings')).read();

  /// What AppRoot.restoreFrom does around the swap, minus the widgets.
  Future<void> restoreLikeTheApp(File zip, {bool failFirstReopen = false}) async {
    final before = reviewStateBeforeRestore(); // boxes still open
    expect(before, isNotNull);
    await Hive.close(); // _releaseStores
    var reopens = 0;
    try {
      await svc.restoreWithRollback(
        journal: SnapshotService.journalFileFor(dbFileIn(live)),
        swap: () => svc.restore(
          zip: zip,
          dbFile: dbFileIn(live),
          hiveBoxFiles: {'settings': hivePathIn(live)},
          currentSchemaVersion: schema,
        ),
        reopen: () async {
          await openLive();
          if (failFirstReopen && reopens++ == 0) {
            throw StateError('migration blew up');
          }
        },
        release: Hive.close,
      );
      await mergeReviewStateAfterRestore(before);
    } on RestoreRolledBackException {
      await mergeReviewStateAfterRestore(before);
    }
  }

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_review_restore_');
    live = await Directory(p.join(tmp.path, 'live')).create();
    old = await Directory(p.join(tmp.path, 'old')).create();
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  Future<void> seedLive() => seed(live, {
        'business_name': 'Live Shop',
        kReviewFirstLaunchAt: installedLive.toIso8601String(),
        kReviewLastPromptAt: promptedLive.toIso8601String(),
        kReviewLastPromptVersion: '1.1.0+10',
      });

  test('restoring an older settings box does not move the last prompt back',
      () async {
    await seed(old, {
      'business_name': 'Old Shop',
      kReviewFirstLaunchAt: installedOld.toIso8601String(),
      kReviewLastPromptAt: promptedOld.toIso8601String(),
      kReviewLastPromptVersion: '1.0.0+9',
    });
    final zip = await backupOf(old);
    await seedLive();
    await openLive();

    await restoreLikeTheApp(zip);

    final box = Hive.box<dynamic>('settings');
    expect(box.get('business_name'), 'Old Shop', reason: 'restore happened');
    final s = liveState();
    expect(s.lastPromptAt, promptedLive);
    expect(s.lastPromptVersion, '1.1.0+10');
    expect(s.firstLaunchAt, installedOld, reason: 'earliest install wins');
    // And so the rule still refuses to ask again for this version.
    expect(
        shouldRequestReview(s,
            completedSales: 500,
            now: promptedLive.add(const Duration(days: 400)),
            currentVersion: '1.1.0+10'),
        isFalse);
  });

  test('a backup from before the feature keeps the pre-restore state',
      () async {
    await seed(old, {'business_name': 'Old Shop'});
    final zip = await backupOf(old);
    await seedLive();
    await openLive();

    await restoreLikeTheApp(zip);

    expect(Hive.box<dynamic>('settings').get('business_name'), 'Old Shop');
    final s = liveState();
    expect(s.firstLaunchAt, installedLive);
    expect(s.lastPromptAt, promptedLive);
    expect(s.lastPromptVersion, '1.1.0+10');
  });

  test('a backup with a newer prompt date keeps that newer date', () async {
    final newer = promptedLive.add(const Duration(days: 30));
    await seed(old, {
      kReviewFirstLaunchAt: installedOld.toIso8601String(),
      kReviewLastPromptAt: newer.toIso8601String(),
      kReviewLastPromptVersion: '1.2.0+11',
    });
    final zip = await backupOf(old);
    await seedLive();
    await openLive();

    await restoreLikeTheApp(zip);

    expect(liveState().lastPromptAt, newer);
    expect(liveState().lastPromptVersion, '1.2.0+11');
  });

  test('rollback: the old box is back and the merge writes nothing',
      () async {
    await seed(old, {
      'business_name': 'Old Shop',
      kReviewFirstLaunchAt: installedOld.toIso8601String(),
      kReviewLastPromptAt: promptedOld.toIso8601String(),
      kReviewLastPromptVersion: '1.0.0+9',
    });
    final zip = await backupOf(old);
    await seedLive();
    final bytesBefore = File(hivePathIn(live)).readAsBytesSync();
    await openLive();

    await restoreLikeTheApp(zip, failFirstReopen: true);

    final box = Hive.box<dynamic>('settings');
    expect(box.get('business_name'), 'Live Shop', reason: 'rolled back');
    final s = liveState();
    expect(s.firstLaunchAt, installedLive);
    expect(s.lastPromptAt, promptedLive);
    expect(s.lastPromptVersion, '1.1.0+10');
    await box.flush();
    expect(File(hivePathIn(live)).readAsBytesSync(), bytesBefore,
        reason: 'merge after rollback must not write to the box');
  });

  test('merging a state into the box it came from is a no-op', () async {
    await seedLive();
    await openLive();
    final box = Hive.box<dynamic>('settings');
    final events = <BoxEvent>[];
    final sub = box.watch().listen(events.add);
    await mergeReviewStateAfterRestore(reviewStateBeforeRestore());
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(events, isEmpty);
  });

  test('the helpers never throw when the box is closed', () async {
    expect(reviewStateBeforeRestore(), isNull);
    await mergeReviewStateAfterRestore(null);
    await mergeReviewStateAfterRestore(
        ReviewState(firstLaunchAt: installedLive));
  });
}
