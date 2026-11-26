import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/app_root.dart';
import 'package:pos_app/core/database/connection/native.dart';
import 'package:pos_app/features/backup/data/restore_journal.dart';
import 'package:pos_app/features/backup/data/restore_merge_marker.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/features/review/data/review_state_store.dart';
import 'package:pos_app/features/review/domain/review_policy.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/domain/usage_summary.dart';

/// Pumps, letting real async work (file IO, isolates) run between frames,
/// until [done] holds. Fails rather than hangs if it never does.
Future<void> pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 2000; i++) {
    if (done()) return;
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump();
  }
  fail('condition not reached');
}

/// A failed startup recovery must land on the error screen with nothing
/// opened, and "Try again" must rerun recovery before opening anything.
void main() {
  group('with a fake documents folder', () {
    late Directory docs;
    const channel = MethodChannel('plugins.flutter.io/path_provider');

    setUp(() {
      docs = Directory.systemTemp.createTempSync('pos_retry_');
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

    testWidgets('retry refuses to open while an uncommitted journal exists',
        (tester) async {
      final journal = SnapshotService.journalFileFor(
          File(p.join(docs.path, kDatabaseFileName)));
      RestoreJournal.begin(journal, plan: const [], staged: const []);

      await tester.pumpWidget(AppRoot(
        startupFatal: kRecoveryFailedMessage,
        // Claims success but leaves the journal: _reopenStores must refuse.
        recoverForRetry: () async => RestoreRecovery.rolledBack,
      ));
      await tester.runAsync(() => tester.tap(find.text('Try again')));
      final refused = find.textContaining('has not been undone');
      await pumpUntil(tester, () => refused.evaluate().isNotEmpty);

      expect(refused, findsOneWidget);
      expect(Hive.isBoxOpen('settings'), isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'a successful retry opens the app, toasts, and schedules '
        'the auto-backup', (tester) async {
      await tester.pumpWidget(AppRoot(
        startupFatal: kRecoveryFailedMessage,
        recoverForRetry: () async => RestoreRecovery.rolledBack,
      ));
      await tester.runAsync(() => tester.tap(find.text('Try again')));
      // Real Hive + Drift (background isolate) IO: wait for the outcome.
      final toast =
          find.text(restoreRecoveryNotice(RestoreRecovery.rolledBack)!);
      await pumpUntil(tester, () => toast.evaluate().isNotEmpty);

      expect(find.text('Restore failed'), findsNothing);
      expect(Hive.isBoxOpen('settings'), isTrue);
      expect(toast, findsOneWidget);
      final state = tester.state<AppRootState>(find.byType(AppRoot));
      expect(state.autoBackupScheduledForTest, isTrue);
      // The review clock startUp() skipped is started by the retry.
      expect(
          ReviewStateStore(Hive.box<dynamic>('settings')).read().firstLaunchAt,
          isNotNull);

      await tester.pump(const Duration(seconds: 5)); // toast runs its course
      await tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox()); // closes timer + DB
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
    });

    testWidgets(
        'retry that finds the restore committed says so and merges back',
        (tester) async {
      // What restoreFrom left on disk before it ended on the error screen.
      await tester.runAsync(() async {
        await Hive.openBox<dynamic>('settings');
        writeRestoreMergeMarker(
          ReviewState(
              firstLaunchAt: DateTime(2026, 1, 1),
              lastPromptAt: DateTime(2026, 10, 1),
              lastPromptVersion: '1.1.0+10',
              lastPromptShownAt: DateTime(2026, 10, 1)),
          const UsageSnapshot(counts: {
            UsageEvent.saleCompleted:
                UsageCount(42, firstMonth: '2026-05', lastMonth: '2026-11'),
          }, countingOn: true),
        );
        await Hive.close();
      });
      final marker = File(p.join(docs.path, kRestoreMergeMarkerName));
      expect(marker.existsSync(), isTrue);
      await tester.pumpWidget(AppRoot(
        startupFatal: 'Restore failed (x) and the app could not reopen',
        recoverForRetry: () async => RestoreRecovery.completed,
      ));
      await tester.runAsync(() => tester.tap(find.text('Try again')));
      final toast = find.text(kRestoreCompletedOnRetryNotice);
      await pumpUntil(tester, () => toast.evaluate().isNotEmpty);
      expect(kRestoreCompletedOnRetryNotice, 'The backup was restored.');
      final review = ReviewStateStore(Hive.box<dynamic>('settings')).read();
      expect(review.lastPromptAt, DateTime(2026, 10, 1));
      expect(review.lastPromptShownAt, DateTime(2026, 10, 1));
      final usage = Hive.box<dynamic>(kUsageBoxName);
      expect(readUsageCounts(usage)[UsageEvent.saleCompleted]!.count, 42);
      // The device's counting choice goes back on the Usage counting switch.
      final features = Hive.box<dynamic>('settings').get('features_v1');
      expect((features as Map)['usageCounting'], isTrue);
      expect(usage.containsKey(kUsageCountingOnKey), isFalse);
      expect(marker.existsSync(), isFalse);

      await tester.pump(const Duration(seconds: 5));
      await tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox());
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
    });

    testWidgets('a completed retry without a pending restore stays quiet',
        (tester) async {
      await tester.pumpWidget(AppRoot(
        startupFatal: kRecoveryFailedMessage,
        recoverForRetry: () async => RestoreRecovery.completed,
      ));
      await tester.runAsync(() => tester.tap(find.text('Try again')));
      await pumpUntil(tester, () => Hive.isBoxOpen('settings'));
      await tester.pump();
      expect(find.text(kRestoreCompletedOnRetryNotice), findsNothing);
      await tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox());
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
    });
  });

  testWidgets('failed recovery → error screen; retry reruns recovery first',
      (tester) async {
    var recoveries = 0;
    await tester.pumpWidget(AppRoot(
      startupFatal: kRecoveryFailedMessage,
      recoverForRetry: () async {
        recoveries++;
        return null; // still failing
      },
    ));

    expect(find.text('Restore failed'), findsOneWidget);
    expect(find.text(kRecoveryFailedMessage), findsOneWidget);
    expect(find.textContaining('.bak'), findsNothing);
    expect(find.text('Contact support on WhatsApp (+977 9802850777)'),
        findsOneWidget);
    expect(Hive.isBoxOpen('settings'), isFalse);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(recoveries, 1);
    // Recovery failed again: still on the error screen, nothing opened.
    expect(find.text('Restore failed'), findsOneWidget);
    expect(find.textContaining('could not be undone'), findsOneWidget);
    expect(Hive.isBoxOpen('settings'), isFalse);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(recoveries, 2);

    await tester.pumpWidget(const SizedBox()); // disposes timers
  });

  test('the notice for each recovery outcome', () {
    expect(restoreRecoveryNotice(RestoreRecovery.none), isNull);
    expect(restoreRecoveryNotice(RestoreRecovery.completed), isNull);
    expect(restoreRecoveryNotice(RestoreRecovery.rolledBack),
        'A restore was interrupted. Your previous data was put back.');
    expect(
        restoreRecoveryNotice(RestoreRecovery.recoveredWithoutJournal),
        "A restore was interrupted and its progress record couldn't be read. "
        'Your previous data was put back, but some receipt photos from the '
        'backup may remain. Please check your recent records.');
    expect(
        restoreRecoveryNotice(RestoreRecovery.missingFilesPutBack),
        'A restore was interrupted and some data was missing. The saved copy '
        'was put back. Please check your recent records.');
    expect(
        restoreRecoveryNotice(RestoreRecovery.recoveredWithoutJournalUncertain),
        "A restore was interrupted and its progress record couldn't be read. "
        'Your previous data may have been put back. Please check your recent '
        'records.');
    // The two long recovery notices stay up twice as long.
    for (final r in [
      RestoreRecovery.recoveredWithoutJournal,
      RestoreRecovery.recoveredWithoutJournalUncertain,
      RestoreRecovery.missingFilesPutBack,
    ]) {
      expect(restartNoticeDuration(restoreRecoveryNotice(r)!),
          const Duration(seconds: 8));
    }
    expect(
        restartNoticeDuration('Backup restored'), const Duration(seconds: 4));
    expect(
        restartNoticeDuration(
            restoreRecoveryNotice(RestoreRecovery.rolledBack)!),
        const Duration(seconds: 4));
    // Every outcome is handled explicitly (no catch-all), and none of the
    // texts point users at files they can't reach.
    for (final r in RestoreRecovery.values) {
      expect(restoreRecoveryNotice(r) ?? '', isNot(contains('.bak')));
    }
  });
}
