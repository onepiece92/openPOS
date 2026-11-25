import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/widgets.dart';

/// Closes the database when the OS asks the app to quit, before the Flutter
/// engine starts tearing the Dart VM down.
///
/// Why: on desktop, quitting (Cmd+Q, or closing the last window) destroys
/// the engine while the database is still open on Drift's background
/// isolate. That isolate then notices its client is gone and closes SQLite
/// by itself, and `sqlite3_close` runs the destructors of the SQL functions
/// Drift registered — FFI callbacks into Dart. If the VM is already
/// shutting down at that moment it aborts the process ("GetFfiCallbackMetadata
/// called after shutdown"): a crash report on quit, roughly one quit in
/// four. Closing here, while the VM is fully alive, removes the race.
///
/// The exit request is only delivered where the embedder supports it
/// (macOS, Windows, Linux). On Android and iOS it never fires, so this is a
/// no-op there.
class DatabaseExitGuard {
  DatabaseExitGuard(
    this._closeDatabase, {
    this.timeout = const Duration(seconds: 3),
  }) {
    _listener = AppLifecycleListener(onExitRequested: handleExitRequest);
  }

  final Future<void> Function() _closeDatabase;

  /// Upper bound on how long quitting may wait for the close.
  final Duration timeout;
  late final AppLifecycleListener _listener;

  /// Always lets the app exit — a failed or slow close must never trap the
  /// user in an app that refuses to quit.
  @visibleForTesting
  Future<AppExitResponse> handleExitRequest() async {
    try {
      await _closeDatabase().timeout(timeout);
    } catch (_) {
      // Nothing useful to do while quitting; committed data is already
      // durable (WAL + synchronous=FULL) whether or not the close ran.
    }
    return AppExitResponse.exit;
  }

  void dispose() => _listener.dispose();
}
