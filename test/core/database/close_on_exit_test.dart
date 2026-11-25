import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/close_on_exit.dart';

import '../../_support/test_db.dart';

/// Quitting the desktop app closes the database first (see
/// [DatabaseExitGuard] for the crash this prevents) and never blocks the
/// quit.
void main() {
  testWidgets('an exit request waits for the database to close, then exits',
      (tester) async {
    final closing = Completer<void>();
    var closeCalls = 0;
    final guard = DatabaseExitGuard(() {
      closeCalls++;
      return closing.future;
    });
    addTearDown(guard.dispose);

    // What the engine does when the user presses Cmd+Q / closes the window.
    AppExitResponse? response;
    unawaited(
        tester.binding.handleRequestAppExit().then((r) => response = r));
    await tester.pump();
    expect(closeCalls, 1);
    expect(response, isNull, reason: 'exit is held until the close finishes');

    closing.complete();
    await tester.pump();
    expect(response, AppExitResponse.exit);
  });

  testWidgets('a real database is closed by the time exit is allowed',
      (tester) async {
    await tester.runAsync(() async {
      final db = openInMemoryDatabase();
      await db.customSelect('SELECT 1').get();
      final guard = DatabaseExitGuard(db.close);
      addTearDown(guard.dispose);

      expect(await guard.handleExitRequest(), AppExitResponse.exit);
      await expectLater(
          db.customSelect('SELECT 1').get(), throwsA(anything),
          reason: 'the connection is closed');
    });
  });

  testWidgets('a close that throws still lets the app quit', (tester) async {
    final guard = DatabaseExitGuard(() async => throw StateError('boom'));
    addTearDown(guard.dispose);
    expect(await tester.binding.handleRequestAppExit(), AppExitResponse.exit);
  });

  testWidgets('a close that hangs cannot trap the user in the app',
      (tester) async {
    final guard = DatabaseExitGuard(() => Completer<void>().future,
        timeout: const Duration(seconds: 3));
    addTearDown(guard.dispose);

    AppExitResponse? response;
    unawaited(
        tester.binding.handleRequestAppExit().then((r) => response = r));
    await tester.pump(const Duration(seconds: 2));
    expect(response, isNull);
    await tester.pump(const Duration(seconds: 2));
    expect(response, AppExitResponse.exit);
  });

  testWidgets('after dispose the guard no longer answers exit requests',
      (tester) async {
    var closeCalls = 0;
    DatabaseExitGuard(() async => closeCalls++).dispose();
    await tester.binding.handleRequestAppExit();
    expect(closeCalls, 0);
  });
}
