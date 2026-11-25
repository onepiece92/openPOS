import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/app_root.dart';
import 'package:pos_app/core/database/connection/native.dart';
import 'package:pos_app/features/backup/data/restore_journal.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';

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
      await tester.runAsync(() async {
        await tester.tap(find.text('Try again'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      expect(find.textContaining('has not been undone'), findsOneWidget);
      expect(Hive.isBoxOpen('settings'), isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a successful retry opens the app, toasts, and schedules '
        'the auto-backup', (tester) async {
      await tester.pumpWidget(AppRoot(
        startupFatal: kRecoveryFailedMessage,
        recoverForRetry: () async => RestoreRecovery.rolledBack,
      ));
      await tester.runAsync(() async {
        await tester.tap(find.text('Try again'));
        // Real Hive + Drift (background isolate) IO.
        for (var i = 0; i < 50 && !Hive.isBoxOpen('settings'); i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();

      expect(find.text('Restore failed'), findsNothing);
      expect(Hive.isBoxOpen('settings'), isTrue);
      expect(find.text(restoreRecoveryNotice(RestoreRecovery.rolledBack)!),
          findsOneWidget);
      final state = tester.state<AppRootState>(find.byType(AppRoot));
      expect(state.autoBackupScheduledForTest, isTrue);

      await tester.pump(const Duration(seconds: 5)); // toast runs its course
      await tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox()); // closes timer + DB
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
        contains('put back'));
    expect(restoreRecoveryNotice(RestoreRecovery.recoveredWithoutJournal),
        contains('check'));
  });
}
