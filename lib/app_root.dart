import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/app.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/close_on_exit.dart';
import 'package:pos_app/core/restart_notice.dart';
import 'package:pos_app/core/database/connection/native.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/backup/data/restore_merge_marker.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/features/help/support_contact.dart';
import 'package:pos_app/features/review/data/review_state_store.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/usage_providers.dart';
import 'package:pos_app/startup.dart' show startReviewClock;

/// Owns the Riverpod container so the whole app can be hot-restarted —
/// needed to restore a backup: close DB + Hive, swap files on disk, then
/// bring everything back up on the restored data.
class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    this.startupNotice,
    this.startupFatal,
    this.recoverForRetry,
  });

  /// Toast for the first frame, e.g. after startup restore recovery.
  final String? startupNotice;

  /// Start on the error screen with nothing opened (startup recovery
  /// failed); "Try again" reruns recovery before opening the stores.
  final String? startupFatal;

  /// Recovery used by "Try again"; defaults to
  /// [recoverInterruptedRestoreAtStartup]. Null result = still failing.
  @visibleForTesting
  final Future<RestoreRecovery?> Function()? recoverForRetry;

  static AppRootState of(BuildContext context) =>
      context.findAncestorStateOfType<AppRootState>()!;

  @override
  State<AppRoot> createState() => AppRootState();
}

class AppRootState extends State<AppRoot> {
  ProviderContainer _container = ProviderContainer();
  bool _restoring = false;
  String? _notice; // one-shot toast shown after a restart
  String? _fatal; // set when no data could be reopened after a restore

  /// How long after the first frame the daily auto-backup waits, so its
  /// `VACUUM INTO` + zip don't compete with startup work.
  static const autoBackupDelay = Duration(seconds: 10);
  Timer? _autoBackupTimer;
  Future<void>? _autoBackupRun; // in flight; a restore waits for it

  late final DatabaseExitGuard _exitGuard;

  @visibleForTesting
  bool get autoBackupScheduledForTest => _autoBackupTimer != null;

  @override
  void initState() {
    super.initState();
    _notice = widget.startupNotice;
    _fatal = widget.startupFatal;
    _exitGuard = DatabaseExitGuard(_closeDatabaseForExit);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _autoBackupTimer = Timer(autoBackupDelay, _startAutoBackup);
    });
  }

  /// Fires once, [autoBackupDelay] after the first frame. Skipped when the
  /// widget is gone or a restore has begun / left the app without data;
  /// [restoreFrom] and [dispose] also cancel the pending timer.
  void _startAutoBackup() {
    _autoBackupTimer = null;
    if (!mounted || _restoring || _fatal != null) return;
    final run = _container
        .read(snapshotCoordinatorProvider)
        .runAutoBackupIfDue() // never throws
        .then<void>((_) {});
    _autoBackupRun = run;
    unawaited(run.whenComplete(() {
      if (identical(_autoBackupRun, run)) _autoBackupRun = null;
    }));
  }

  /// The app is quitting (desktop): close the database of the current
  /// container while the Dart VM is still fully up — see
  /// [DatabaseExitGuard]. During a restore the stores are already released
  /// (or being swapped by [restoreFrom]), so there is nothing to close here.
  Future<void> _closeDatabaseForExit() async {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = null;
    if (_restoring) return;
    final container = _container;
    // Never opened (e.g. the error screen): do not create it just to close.
    if (!container.exists(databaseProvider)) return;
    await container.read(databaseProvider).close();
  }

  @override
  void dispose() {
    _exitGuard.dispose();
    _autoBackupTimer?.cancel();
    _autoBackupTimer = null;
    _container.dispose();
    super.dispose();
  }

  /// Restores [zip] and restarts the app on the restored data.
  ///
  /// "Backup restored" is shown only once the restored DB has opened (which
  /// runs any migrations) and answered a first query. Outcomes otherwise:
  /// * the backup is rejected before any file is touched
  ///   ([SnapshotFormatException], IO error, or the old DB failed to close)
  ///   → app reopens on its unchanged data;
  /// * the backup was swapped in but failed to open
  ///   ([RestoreRolledBackException]) → the `.bak` DB and Hive files are
  ///   put back and the app reopens on them;
  /// * nothing can be reopened ([RestoreFatalException]) → an error screen
  ///   with a retry button, never an endless splash.
  /// The error is rethrown after the UI has been updated.
  Future<void> restoreFrom(File zip) async {
    if (_restoring) return;
    // A restore pre-empts this launch's pending auto-backup.
    _autoBackupTimer?.cancel();
    _autoBackupTimer = null;
    // The usage box opens lazily: open it (so it is in the file list below)
    // and write pending counts, then remember it for the merge-back.
    final usage = _container.read(usageCounterProvider);
    await usage.ensureLoaded();
    await usage.flush();
    // The counting switch is this device's choice, not the backup's.
    final usageBefore = usageSnapshotBeforeRestore(
        countingOn: _container
            .read(featureFlagsProvider)
            .stored(Feature.usageCounting));
    // Resolve paths while Hive is still open (box.path needs an open box).
    final dbPath = (await databaseFile()).path;
    final hiveFiles = snapshotHiveBoxFiles();
    final photosPath = (await receiptsDir()).path;
    final zipPath = zip.path;
    // Review-reminder bookkeeping lives in the settings box, which the
    // restore replaces: remember it now, merge it back after the reopen so
    // an older backup cannot move the last-prompt date backwards.
    final reviewBefore = reviewStateBeforeRestore();
    // Kept on disk until the merge has run: a restore that ends on the
    // error screen (and maybe a kill) finishes it later, see _retryOpen
    // and startUp.
    writeRestoreMergeMarker(reviewBefore, usageBefore);

    // 1. Unmount the app tree so no widget can issue queries mid-swap.
    setState(() {
      _restoring = true;
      _fatal = null;
    });

    Object? error;
    String? notice;
    String? fatal;
    try {
      // An auto-backup already under way reads the DB through the current
      // container; let it finish before that container is torn down.
      final inFlight = _autoBackupRun;
      if (inFlight != null) await inFlight;
      await WidgetsBinding.instance.endOfFrame;

      // 2. Release both stores. If that fails, nothing on disk is touched.
      var released = false;
      try {
        await _releaseStores();
        released = true;
      } catch (e) {
        error = e;
        notice = 'Restore failed: $e. Your data was not changed.';
        try {
          await _reopenStores();
        } catch (e2) {
          fatal = '${RestoreFatalException(cause: e, reopenError: e2)}';
        }
      }

      if (released) {
        // 3. Verify + swap off the UI isolate, reopen, roll back on failure.
        try {
          await const SnapshotService().restoreWithRollback(
            swap: () =>
                _swapInIsolate(zipPath, dbPath, hiveFiles, photosPath),
            // The first reopen verifies the restored data while its journal
            // is still uncommitted; restoreWithRollback itself refuses to
            // reopen the old data while a journal is pending.
            reopen: () => _reopenStores(verifyingRestore: true),
            release: _releaseStores,
            journal: SnapshotService.journalFileFor(File(dbPath)),
          );
          notice = 'Backup restored';
          await mergeReviewStateAfterRestore(reviewBefore); // never throws
          await mergeUsageAfterRestore(usageBefore); // never throws
          _container.read(usageCounterProvider)
              .record(UsageEvent.backupRestored);
        } on RestoreFatalException catch (e) {
          error = e;
          fatal = '$e';
          // The disk may hold the backup: the merge marker stays for
          // _retryOpen / the next launch.
        } on RestoreRolledBackException catch (e) {
          error = e;
          notice = 'Restore failed: $e';
          // Back on the old box: the merge finds nothing to change.
          await mergeReviewStateAfterRestore(reviewBefore);
          await mergeUsageAfterRestore(usageBefore);
        } catch (e) {
          error = e;
          notice = 'Restore failed: $e. Your data was not changed.';
        }
      }
    } catch (e) {
      error ??= e;
      fatal ??= 'Restore failed: $e';
    } finally {
      // Merged (or nothing was swapped): the marker has done its job.
      if (fatal == null) deleteRestoreMergeMarker();
      if (mounted) {
        setState(() {
          _restoring = false;
          _fatal = fatal;
          _notice = fatal == null ? notice : null;
        });
      } else {
        _restoring = false;
      }
    }
    if (error != null) throw error;
  }

  /// Static so the isolate closure captures only these plain values, never
  /// `this` (State is not sendable).
  static Future<RestoreBackup> _swapInIsolate(
    String zipPath,
    String dbPath,
    Map<String, String> hiveFiles,
    String photosPath,
  ) =>
      Isolate.run(() => const SnapshotService().restore(
            zip: File(zipPath),
            dbFile: File(dbPath),
            hiveBoxFiles: hiveFiles,
            receiptsDir: Directory(photosPath),
            currentSchemaVersion: AppDatabase.currentSchemaVersion,
          ));

  /// Closes the DB and Hive. The old container is disposed even if closing
  /// the DB throws.
  Future<void> _releaseStores() async {
    final old = _container;
    try {
      // Never opened (startup error screen): don't create it to close it.
      if (old.exists(databaseProvider)) {
        await old.read(databaseProvider).close();
      }
    } finally {
      old.dispose();
      await Hive.close();
    }
  }

  /// Opens Hive + a fresh container and runs a first query, so a broken DB
  /// or failed migration surfaces here rather than after "restored".
  ///
  /// Refuses ([PendingRestoreException]) while an uncommitted restore
  /// journal exists — the disk may hold the backup's data or a mix, and
  /// the next recovery would discard anything recorded on it — unless
  /// [verifyingRestore] (the reopen that decides whether to commit).
  Future<void> _reopenStores({bool verifyingRestore = false}) async {
    if (!verifyingRestore) {
      SnapshotService.assertNoPendingRestore(
          SnapshotService.journalFileFor(await databaseFile()));
    }
    for (final name in kSnapshotHiveBoxes) {
      await Hive.openBox<dynamic>(name);
    }
    final c = ProviderContainer();
    _container = c;
    await c.read(databaseProvider).customSelect('SELECT 1').get();
  }

  Future<void> _retryOpen() async {
    setState(() => _restoring = true);
    String? fatal;
    String? notice;
    try {
      try {
        await _releaseStores();
      } catch (_) {/* stores may already be half-closed */}
      // An unfinished restore (startup recovery or a rollback failed) must
      // be put right before anything opens, or Drift could create an empty
      // DB over the missing one.
      final recovered = await (widget.recoverForRetry ??
          recoverInterruptedRestoreAtStartup)();
      if (recovered == null) {
        throw StateError('the interrupted restore could not be undone');
      }
      await _reopenStores();
      // startUp() skipped this when recovery failed; no-op otherwise.
      await startReviewClock();
      notice = restoreRecoveryNotice(recovered);
      // A restore that ended on this error screen may have been accepted
      // after all (commit recorded, not confirmed): finish its merge and
      // say so.
      if (await finishPendingRestoreMerge(recovered)) {
        notice = kRestoreCompletedOnRetryNotice;
        _container.read(usageCounterProvider).record(UsageEvent.backupRestored);
      }
    } catch (e) {
      fatal = 'Still unable to open the app data: $e';
    } finally {
      if (mounted) {
        setState(() {
          _restoring = false;
          _fatal = fatal;
          if (fatal == null) _notice = notice;
        });
        // This launch's auto-backup was skipped while on the error screen.
        if (fatal == null && _autoBackupTimer == null) {
          _autoBackupTimer = Timer(autoBackupDelay, _startAutoBackup);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) return const _RestoringSplash();
    if (_fatal != null) {
      return _RestoreFailedScreen(message: _fatal!, onRetry: _retryOpen);
    }
    return UncontrolledProviderScope(
      // New key per container → subtree is rebuilt from scratch on restart.
      key: ObjectKey(_container),
      container: _container,
      child: _notice == null
          ? const POSApp()
          : RestartNoticeOverlay(
              message: _notice!,
              onDone: () => setState(() => _notice = null),
              child: const POSApp(),
            ),
    );
  }
}

class _RestoringSplash extends StatelessWidget {
  const _RestoringSplash();

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Restoring backup…'),
              ],
            ),
          ),
        ),
      );
}

class _RestoreFailedScreen extends StatelessWidget {
  const _RestoreFailedScreen({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Restore failed',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: onRetry,
                      child: const Text('Try again'),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) => TextButton.icon(
                        onPressed: () => openSupportWhatsAppOrExplain(context),
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text('Contact support on WhatsApp '
                            '($kSupportWhatsAppDisplay)'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// Bottom toast rendered *above* the MaterialApp (which is being recreated,
/// so a ScaffoldMessenger from before the restart no longer exists).
/// Public for the usage-host test, which reproduces AppRoot's removal of it.
class RestartNoticeOverlay extends StatefulWidget {
  const RestartNoticeOverlay({
    super.key,
    required this.message,
    required this.onDone,
    required this.child,
  });
  final String message;
  final VoidCallback onDone;
  final Widget child;

  @override
  State<RestartNoticeOverlay> createState() => RestartNoticeOverlayState();
}

class RestartNoticeOverlayState extends State<RestartNoticeOverlay> {
  @override
  void initState() {
    super.initState();
    restartNoticeShowing.value = true;
    Future<void>.delayed(restartNoticeDuration(widget.message), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    restartNoticeShowing.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            widget.child,
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: SafeArea(
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF1F2933),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Text(
                      widget.message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
