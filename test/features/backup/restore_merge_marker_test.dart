import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/backup/data/restore_merge_marker.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/features/review/data/review_state_store.dart';
import 'package:pos_app/features/review/domain/review_policy.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/domain/usage_summary.dart';
import 'package:pos_app/startup.dart';

/// The restore's merge-back survives a kill on the error screen: it is kept
/// on disk until it has run.
void main() {
  late Directory docs;
  File marker() => File(p.join(docs.path, kRestoreMergeMarkerName));

  final before = ReviewState(
    firstLaunchAt: DateTime(2026, 1, 1),
    lastPromptAt: DateTime(2026, 10, 1),
    lastPromptVersion: '1.1.0+10',
    lastPromptShownAt: DateTime(2026, 10, 2),
  );
  const usage = UsageSnapshot(
    counts: {
      UsageEvent.csvExported:
          UsageCount(9, firstMonth: '2026-02', lastMonth: '2026-11'),
    },
    countingOn: false,
    disclosureShown: true,
    askedVersion: '1.1.0+10',
  );

  setUp(() async {
    docs = await Directory.systemTemp.createTemp('pos_merge_marker_');
    Hive.init(docs.path);
    await Hive.openBox<dynamic>('settings');
    writeRestoreMergeMarker(before, usage);
    await Hive.close();
  });
  tearDown(() async {
    await Hive.close();
    await docs.delete(recursive: true);
  });

  Future<StartupResult> launch(RestoreRecovery r) => startUp(
        recover: () async => r,
        initHive: () async => Hive.init(docs.path),
        openStores: () async {
          for (final n in kStartupHiveBoxes) {
            await Hive.openBox<dynamic>(n);
          }
        },
      );

  test('next launch after a committed restore: merged, and said so', () async {
    expect(marker().existsSync(), isTrue);
    final r = await launch(RestoreRecovery.completed);
    expect(r.notice, kRestoreCompletedOnRetryNotice);
    expect(marker().existsSync(), isFalse);
    final review = ReviewStateStore(Hive.box<dynamic>('settings')).read();
    expect(review.lastPromptAt, DateTime(2026, 10, 1));
    expect(review.lastPromptVersion, '1.1.0+10');
    expect(review.lastPromptShownAt, DateTime(2026, 10, 2));
    expect(Hive.box<dynamic>('settings').get(kReviewFirstLaunchAt),
        DateTime(2026, 1, 1).toIso8601String());
    final box = Hive.box<dynamic>(kUsageBoxName);
    expect(readUsageCounts(box)[UsageEvent.csvExported]!.count, 9);
    expect(box.get(kUsageCountingOnKey), isFalse);
    expect(box.get(kUsageAskedVersionKey), '1.1.0+10');
  });

  test('after a rollback: merged quietly (harmless), marker gone', () async {
    final r = await launch(RestoreRecovery.rolledBack);
    expect(r.notice, restoreRecoveryNotice(RestoreRecovery.rolledBack));
    expect(marker().existsSync(), isFalse);
  });

  test('no marker: nothing happens', () async {
    marker().deleteSync();
    final r = await launch(RestoreRecovery.completed);
    expect(r.notice, isNull);
    expect(Hive.isBoxOpen(kUsageBoxName), isFalse,
        reason: 'the usage box still opens lazily');
  });

  test('an unreadable marker is dropped, never fatal', () async {
    marker().writeAsStringSync('{not json');
    final r = await launch(RestoreRecovery.completed);
    expect(r.notice, isNull);
    expect(marker().existsSync(), isFalse);
  });

  test('without an open settings box the helpers do nothing', () async {
    expect(await finishPendingRestoreMerge(RestoreRecovery.completed), isFalse);
    deleteRestoreMergeMarker();
    expect(marker().existsSync(), isTrue);
  });
}
