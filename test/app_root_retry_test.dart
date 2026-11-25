import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/app_root.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';

/// A failed startup recovery must land on the error screen with nothing
/// opened, and "Try again" must rerun recovery before opening anything.
void main() {
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
