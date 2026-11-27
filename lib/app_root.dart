import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/app.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/close_on_exit.dart';
import 'package:pos_app/core/database/database_open_errors.dart';
import 'package:pos_app/core/database/upgrade_progress.dart';
import 'package:pos_app/core/restart_notice.dart';
import 'package:pos_app/core/database/connection/native.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/backup/data/open_failure_recovery.dart';
import 'package:pos_app/features/backup/data/restore_merge_marker.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/features/help/support_contact.dart';
import 'package:pos_app/features/review/data/review_state_store.dart';
import 'package:pos_app/features/settings/data/factory_reset.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/usage_providers.dart';
import 'package:pos_app/startup.dart'
    show StartupResult, checkDatabaseFileBeforeOpen, startReviewClock;

/// Owns the Riverpod container so the whole app can be hot-restarted —
/// needed to restore a backup: close DB + Hive, swap files on disk, then
/// bring everything back up on the restored data.
class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    this.container,
    this.startup,
    this.startupNotice,
    this.startupFatal,
    this.startupDbError,
    this.recoverForRetry,
  });

  /// The container the startup DB check ran on (so its connection is
  /// reused); a fresh one when null.
  final ProviderContainer? container;

  /// The launch's `startUp` (restore recovery, Hive, the startup stores,
  /// the database check), still running when the first frame is drawn.
  /// Until it resolves only [StartupSurface] is shown — nothing that reads
  /// Hive or the database builds. Its result then replaces
  /// [startupNotice] / [startupFatal] / [startupDbError]. When null, those
  /// three are the startup result (already resolved; used by tests).
  final Future<StartupResult>? startup;

  /// Toast for the first frame, e.g. after startup restore recovery.
  final String? startupNotice;

  /// Start on the error screen with nothing opened (startup recovery
  /// failed); "Try again" reruns recovery before opening the stores.
  final String? startupFatal;

  /// The startup `SELECT 1` failed: start on the error screen with a plain
  /// message (see [describeDatabaseOpenFailure]).
  final Object? startupDbError;

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
  late ProviderContainer _container;
  bool _restoring = false;
  String _splashMessage = kRestoringSplashText;
  String? _notice; // one-shot toast shown after a restart
  String? _fatal; // set when no data could be reopened after a restore
  // Error-screen heading and whether it offers "Try again"; set together
  // with [_fatal].
  String _fatalTitle = kRestoreFailedTitle;
  bool _fatalCanRetry = true;
  // The error screen is showing a database-open failure (not a restore):
  // a failed retry keeps the plain wording.
  bool _dbOpenFailure = false;
  // …and the error says the FILE is missing or damaged
  // ([isDatabaseFileDamaged]): only then are "Restore latest automatic
  // backup" and "Start fresh" offered.
  bool _dbFileDamaged = false;
  // One plain line under the error message (e.g. why Start fresh refused).
  String? _errorNote;
  // A factory reset is pending on data that is still there: the blocking
  // "Finish erasing" / "Keep my data" question is showing.
  bool _resetChoice = false;
  // "Keep my data" could not clear the flag yet.
  bool _resetKeepFailed = false;

  /// How long after the first frame the daily auto-backup waits, so its
  /// `VACUUM INTO` + zip don't compete with startup work.
  static const autoBackupDelay = Duration(seconds: 10);
  Timer? _autoBackupTimer;
  Future<void>? _autoBackupRun; // in flight; a restore waits for it

  // Installed in initState, before startUp resolves: a quit during startup
  // first waits (bounded by the guard's timeout) for startUp — so a
  // migration is never cut off half-way — then closes the database.
  late final DatabaseExitGuard _exitGuard;

  // [AppRoot.startup] has not resolved yet: [StartupSurface] is showing.
  bool _starting = false;
  // The check is taking longer than [kStartupLineDelay]: show one line.
  bool _startupSlow = false;
  Timer? _startupSlowTimer;
  // Runs for [kStartupLineMinVisible] once the line is up, so it never
  // flashes for a few milliseconds; a result arriving meanwhile waits in
  // [_heldStartupResult].
  Timer? _startupLineMinTimer;
  StartupResult? _heldStartupResult;

  @visibleForTesting
  bool get autoBackupScheduledForTest => _autoBackupTimer != null;

  @visibleForTesting
  ProviderContainer get containerForTest => _container;

  @visibleForTesting
  DatabaseExitGuard get exitGuardForTest => _exitGuard;

  @override
  void initState() {
    super.initState();
    _container = widget.container ?? ProviderContainer();
    _exitGuard = DatabaseExitGuard(_closeDatabaseForExit);
    final startup = widget.startup;
    if (startup == null) {
      _applyStartup(StartupResult(
        notice: widget.startupNotice,
        fatal: widget.startupFatal,
        dbError: widget.startupDbError,
      ));
      return;
    }
    _starting = true;
    // A fast open (milliseconds) never shows any text; only a slow one —
    // e.g. a migration on a cold low-end phone — gets a line.
    _startupSlowTimer = Timer(kStartupLineDelay, () {
      if (!mounted || !_starting) return;
      _startupLineMinTimer = Timer(kStartupLineMinVisible, () {
        _startupLineMinTimer = null;
        final held = _heldStartupResult;
        if (held != null) _showStartupResult(held);
      });
      setState(() => _startupSlow = true);
    });
    startup.then(_startupResolved,
        onError: (Object e) => _startupResolved(StartupResult(dbError: e)));
  }

  void _startupResolved(StartupResult result) {
    _startupSlowTimer?.cancel();
    _startupSlowTimer = null;
    if (!mounted) return;
    // A line that just went up stays readable rather than flashing.
    if (_startupLineMinTimer != null) {
      _heldStartupResult = result;
      return;
    }
    _showStartupResult(result);
  }

  void _showStartupResult(StartupResult result) {
    _heldStartupResult = null;
    if (!mounted) return;
    setState(() {
      _starting = false;
      _startupSlow = false;
      _applyStartup(result);
    });
  }

  /// Takes on the startup result: toast or error screen, then the exit
  /// guard and the auto-backup timer (10 s after the app's first frame).
  void _applyStartup(StartupResult result) {
    _notice = result.notice;
    _fatal = result.fatal;
    _resetChoice = result.resetChoice;
    final dbError = result.dbError;
    if (_fatal == null && dbError != null) _showDbOpenFailure(dbError);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _autoBackupTimer = Timer(autoBackupDelay, _startAutoBackup);
    });
  }

  /// Puts the plain database-open message on the error screen (callers
  /// wrap it in setState where needed).
  void _showDbOpenFailure(Object error) {
    final f = describeDatabaseOpenFailure(error);
    _fatal = f.message;
    _fatalTitle = f.title;
    _fatalCanRetry = f.canRetry;
    _dbOpenFailure = true;
    _dbFileDamaged = isDatabaseFileDamaged(error);
    _errorNote = null;
  }

  /// Fires once, [autoBackupDelay] after the first frame. Skipped when the
  /// widget is gone or a restore has begun / left the app without data;
  /// [restoreFrom] and [dispose] also cancel the pending timer.
  void _startAutoBackup() {
    _autoBackupTimer = null;
    if (!mounted || _restoring || _fatal != null || _resetChoice) return;
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
    // Quit during startup: let startUp finish first (the guard bounds the
    // wait) — closing under a running migration or the first query would
    // be worse than waiting for it.
    final startup = widget.startup;
    if (_starting && startup != null) {
      try {
        await startup;
      } catch (_) {/* the error screen's container is closed below */}
    }
    final container = _container;
    // Never opened (e.g. the error screen): do not create it just to close.
    if (!container.exists(databaseProvider)) return;
    await container.read(databaseProvider).close();
  }

  @override
  void dispose() {
    _exitGuard.dispose();
    _startupSlowTimer?.cancel();
    _startupLineMinTimer?.cancel();
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
      _splashMessage = kRestoringSplashText;
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
            swap: () => _swapInIsolate(zipPath, dbPath, hiveFiles, photosPath),
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
          _container
              .read(usageCounterProvider)
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
          _fatalTitle = kRestoreFailedTitle;
          _fatalCanRetry = true;
          _dbOpenFailure = false;
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
    if (verifyingRestore) {
      // The restored data is the user's explicit choice: a reset-pending
      // flag a backup might carry (backups strip it, older ones may not)
      // must not re-arm an erase. Best effort: the launch finisher never
      // erases a database that still holds data anyway.
      try {
        await clearFactoryResetPendingConfirmed(Hive.box<dynamic>('settings'),
            attempts: 1);
      } catch (_) {}
    }
    await checkDatabaseFileBeforeOpen();
    final c = ProviderContainer();
    _container = c;
    await c.read(databaseProvider).customSelect('SELECT 1').get();
  }

  /// Factory reset, as a restart: unmounts the app, then [runFactoryReset]
  /// — a durable pending flag, the database erase (one transaction), the
  /// old container released, then held tickets, usage, receipt photos and
  /// settings last — and brings the app back on a fresh container, so no
  /// provider, SnackBar or usage counter carries state across and the app
  /// comes up like a first run (onboarding, then the usage notice once).
  /// Automatic backups are kept.
  ///
  /// Outcomes: done → onboarding; the erase refused and the flag confirmed
  /// cleared → back on the unchanged data with [kFactoryResetFailedNotice];
  /// nothing erased but the flag not confirmed cleared → the blocking
  /// [kResetChoiceTitle] question; erased but not all cleared → the error
  /// screen, whose "Try again" (like the next launch) finishes the reset.
  /// Never an app on half-erased stores, never "not changed" with a stale
  /// flag. Also the question's "Finish erasing".
  Future<void> factoryReset() async {
    if (_restoring || _fatal != null) return;
    _autoBackupTimer?.cancel();
    _autoBackupTimer = null;
    setState(() {
      _restoring = true;
      _resetChoice = false;
      _resetKeepFailed = false;
      _splashMessage = kFactoryResetProgress;
    });
    String? notice;
    String? fatal;
    var choice = false;
    try {
      final inFlight = _autoBackupRun;
      if (inFlight != null) await inFlight;
      await WidgetsBinding.instance.endOfFrame;
      final old = _container;
      final outcome = await runFactoryReset(
        settings: Hive.box<dynamic>('settings'),
        eraseDatabase: () =>
            old.read(databaseProvider).eraseAllDataAndCompact(),
        releaseDatabase: () async {
          try {
            // Write pending usage counts now, so tearing the container
            // down cannot write them back after the usage box is cleared.
            if (old.exists(usageCounterProvider)) {
              await old.read(usageCounterProvider).flush();
            }
            await old.read(databaseProvider).close();
          } finally {
            old.dispose();
            _container = ProviderContainer();
          }
        },
        heldOrders: Hive.box<dynamic>('held_orders'),
        usage: usageBoxForReset,
        receipts: receiptsDir,
      );
      switch (outcome) {
        case FactoryResetOutcome.done:
          await startReviewClock(); // a fresh install's clock
        case FactoryResetOutcome.refused:
          notice = kFactoryResetFailedNotice;
        case FactoryResetOutcome.undecided:
          choice = true;
        case FactoryResetOutcome.incomplete:
          fatal = kFactoryResetIncompleteNotice;
      }
    } catch (_) {
      // Only the review clock can get here; the reset itself is done.
    } finally {
      if (mounted) {
        setState(() {
          _restoring = false;
          _notice = notice;
          _resetChoice = choice;
          if (fatal != null) {
            _fatal = fatal;
            _fatalTitle = kFactoryResetIncompleteTitle;
            _fatalCanRetry = true;
            _dbOpenFailure = false;
          }
        });
      } else {
        _restoring = false;
      }
    }
  }

  Future<void> _retryOpen() async {
    setState(() {
      _restoring = true;
      _splashMessage = kRestoringSplashText;
    });
    String? fatal;
    String? notice;
    Object? dbError;
    var choice = false;
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
      // A factory reset that stopped part-way (here or before a kill) is
      // finished before the app opens on its stores.
      final c = _container;
      final pendingReset = await finishPendingFactoryResetOnLaunch(
          () => c.read(databaseProvider));
      choice = pendingReset == PendingFactoryReset.askUser;
      // startUp() skipped this when recovery failed; no-op otherwise.
      await startReviewClock();
      notice = pendingReset == PendingFactoryReset.finished
          ? kFactoryResetFinishedNotice
          : restoreRecoveryNotice(recovered);
      // A restore that ended on this error screen may have been accepted
      // after all (commit recorded, not confirmed): finish its merge and
      // say so.
      if (await finishPendingRestoreMerge(recovered)) {
        notice = kRestoreCompletedOnRetryNotice;
        _container.read(usageCounterProvider).record(UsageEvent.backupRestored);
      }
    } catch (e) {
      dbError = e;
      fatal = 'Still unable to open the app data: $e';
    } finally {
      if (mounted) {
        setState(() {
          _restoring = false;
          _fatal = fatal;
          _resetChoice = fatal == null && choice;
          if (fatal == null) {
            _notice = choice ? null : notice;
            _dbOpenFailure = false;
          } else if (dbError != null &&
              (_dbOpenFailure || isDatabaseTooNew(dbError))) {
            _showDbOpenFailure(dbError);
          }
        });
        // This launch's auto-backup was skipped while on the error screen.
        if (fatal == null && !choice && _autoBackupTimer == null) {
          _autoBackupTimer = Timer(autoBackupDelay, _startAutoBackup);
        }
      }
    }
  }

  /// The disposable container of the error screen: its database never
  /// opened (or opened broken), so it is closed best-effort and replaced by
  /// a fresh one before a restore or a fresh start touches the files.
  Future<void> _dropFailedContainer() async {
    final old = _container;
    try {
      if (old.exists(databaseProvider)) {
        await old.read(databaseProvider).close();
      }
    } catch (_) {/* it never opened */}
    old.dispose();
    _container = ProviderContainer();
  }

  /// "Restore latest automatic backup" on the open-failure screen: the
  /// NORMAL journaled [restoreFrom] of the backup the user picked.
  @visibleForTesting
  Future<void> restoreFromErrorScreen(File zip) async {
    if (_restoring) return;
    await _dropFailedContainer();
    try {
      await restoreFrom(zip);
    } catch (_) {/* restoreFrom has already put the outcome on screen */}
  }

  /// "Start fresh" (confirmed): sets the database that would not open
  /// aside — never deleted — and creates a new, empty one; settings are
  /// kept. Only ever on the user's say-so, never automatically.
  @visibleForTesting
  Future<void> startFresh() async {
    if (_restoring) return;
    // Its follow-up writes need the settings and held-tickets boxes; never
    // touch the database file unless they are open.
    if (!kStartupHiveBoxes.every(Hive.isBoxOpen)) {
      setState(() => _errorNote = kStartFreshNeedsStores);
      return;
    }
    setState(() {
      _errorNote = null;
      _restoring = true;
      _splashMessage = kStartFreshProgress;
    });
    Object? error;
    try {
      await _dropFailedContainer();
      await setAsideDatabaseFile(await databaseFile(), DateTime.now());
      // Created directly: checkDatabaseFileBeforeOpen would (rightly)
      // refuse a missing file under a finished onboarding.
      await _container.read(databaseProvider).customSelect('SELECT 1').get();
    } catch (e) {
      error = e;
    }
    if (!mounted) return;
    setState(() {
      _restoring = false;
      if (error == null) {
        _fatal = null;
        _dbOpenFailure = false;
        _notice = kStartFreshDoneNotice;
      } else {
        _showDbOpenFailure(error);
      }
    });
    if (error == null && _autoBackupTimer == null) {
      _autoBackupTimer = Timer(autoBackupDelay, _startAutoBackup);
    }
  }

  /// "Keep my data": clears the pending flag, retrying, and opens the app
  /// on its data only once that is confirmed — otherwise the question
  /// stays, with [kResetKeepFailed].
  Future<void> _keepData() async {
    final kept = await clearFactoryResetPendingConfirmed(
        Hive.box<dynamic>('settings'),
        attempts: 5);
    if (!mounted) return;
    setState(() {
      _resetKeepFailed = !kept;
      if (kept) {
        _resetChoice = false;
        _notice = kResetKeptNotice;
      }
    });
    if (kept && _autoBackupTimer == null) {
      _autoBackupTimer = Timer(autoBackupDelay, _startAutoBackup);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_starting) return StartupSurface(showLine: _startupSlow);
    if (_restoring) return _RestoringSplash(message: _splashMessage);
    if (_fatal != null) {
      // A database that would not open (missing, empty, corrupt) — not
      // one from a newer app — offers the two ways out besides Try again.
      final recoverable = _dbOpenFailure && _dbFileDamaged && _fatalCanRetry;
      return _RestoreFailedScreen(
        title: _fatalTitle,
        message: _fatal!,
        note: recoverable ? _errorNote : null,
        onRetry: _fatalCanRetry ? _retryOpen : null,
        onRestoreBackup: recoverable ? restoreFromErrorScreen : null,
        onStartFresh: recoverable ? startFresh : null,
      );
    }
    if (_resetChoice) {
      return _ResetChoiceScreen(
        keepFailed: _resetKeepFailed,
        onFinish: factoryReset,
        onKeep: _keepData,
      );
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

/// How long the launch surface stays blank before it says what it is
/// waiting for. A normal open takes a few milliseconds and shows nothing.
const kStartupLineDelay = Duration(milliseconds: 300);

/// Once shown, the line stays at least this long (no flash when startup
/// takes 300–400 ms).
const kStartupLineMinVisible = Duration(milliseconds: 500);

/// The launch surface's line while the database opens…
const kOpeningAppText = 'Opening Open POS…';

/// …and while it is being migrated to this version's schema.
const kUpdatingDataText = 'Updating your data…';

/// Launch-screen background: Android's launch window is
/// `?android:colorBackground` of Theme.Light / Theme.Black (white, or black
/// in dark mode); iOS's LaunchScreen.storyboard is always white.
@visibleForTesting
Color launchSurfaceColor(Brightness platformBrightness, TargetPlatform os) =>
    os == TargetPlatform.iOS || platformBrightness == Brightness.light
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);

/// The first frame: the native launch screen's plain colour, so the hand-
/// off from it is invisible. Text only when [showLine] (startup is slow):
/// [kUpdatingDataText] while a migration runs, else [kOpeningAppText].
/// Deliberately not a MaterialApp: nothing here reads Hive, settings, the
/// router or the database.
class StartupSurface extends StatelessWidget {
  const StartupSurface({super.key, required this.showLine});
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.maybePlatformBrightnessOf(context) ??
        View.maybeOf(context)?.platformDispatcher.platformBrightness ??
        Brightness.light;
    final background = launchSurfaceColor(brightness, defaultTargetPlatform);
    final dark = background == const Color(0xFF000000);
    return ColoredBox(
      color: background,
      child: !showLine
          ? const SizedBox.expand()
          : Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: ValueListenableBuilder<bool>(
                  valueListenable: databaseUpgradeRunning,
                  builder: (_, upgrading, __) => Text(
                    upgrading ? kUpdatingDataText : kOpeningAppText,
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 16,
                      decoration: TextDecoration.none,
                      color: dark
                          ? const Color(0xFFB0B0B0)
                          : const Color(0xFF555555),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// The splash shown while a backup is restored.
const kRestoringSplashText = 'Restoring backup…';

/// Error-screen heading for a failed restore or startup recovery.
const kRestoreFailedTitle = 'Restore failed';

/// What the error screen says when the database would not open.
({
  String title,
  String message,
  bool canRetry
}) describeDatabaseOpenFailure(Object error) => isDatabaseTooNew(error)
    ? (title: kDataTooNewTitle, message: kDataTooNewMessage, canRetry: false)
    : (
        title: kDataOpenFailedTitle,
        message: kDataOpenFailedMessage,
        canRetry: true,
      );

class _RestoringSplash extends StatelessWidget {
  const _RestoringSplash({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        ),
      );
}

/// The blocking question for a pending factory reset whose data is still
/// on the device. Text only; nothing else of the app builds behind it.
class _ResetChoiceScreen extends StatefulWidget {
  const _ResetChoiceScreen({
    required this.keepFailed,
    required this.onFinish,
    required this.onKeep,
  });
  final bool keepFailed;
  final Future<void> Function() onFinish;
  final Future<void> Function() onKeep;

  @override
  State<_ResetChoiceScreen> createState() => _ResetChoiceScreenState();
}

class _ResetChoiceScreenState extends State<_ResetChoiceScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
                    const Text(
                      kResetChoiceTitle,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    const Text(kResetChoiceMessage,
                        textAlign: TextAlign.center),
                    if (widget.keepFailed) ...[
                      const SizedBox(height: 12),
                      const Text(kResetKeepFailed, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : () => _run(widget.onKeep),
                      child: const Text(kResetChoiceKeep),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : () => _run(widget.onFinish),
                      child: const Text(kResetChoiceFinish),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _RestoreFailedScreen extends StatelessWidget {
  const _RestoreFailedScreen({
    required this.title,
    required this.message,
    required this.onRetry,
    this.note,
    this.onRestoreBackup,
    this.onStartFresh,
  });

  /// An extra plain line under [message].
  final String? note;

  /// Null hides "Restore latest automatic backup" / "Start fresh" (only a
  /// database that would not open offers them).
  final Future<void> Function(File zip)? onRestoreBackup;
  final Future<void> Function()? onStartFresh;

  Future<void> _pickBackup(BuildContext context) async {
    final backups = await listAutoBackups();
    if (!context.mounted) return;
    if (backups.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: const Text(kNoAutoBackups),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    final picked = await showDialog<File>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text(kPickBackupTitle),
        children: [
          for (var i = 0; i < backups.length; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, backups[i].$1),
              child: Text(autoBackupLabel(backups[i].$2, newest: i == 0)),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (picked != null) await onRestoreBackup!(picked);
  }

  Future<void> _confirmStartFresh(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(kStartFreshTitle),
        content: const Text(kStartFreshMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(kStartFreshButton),
          ),
        ],
      ),
    );
    if (ok == true) await onStartFresh!();
  }

  final String title;
  final String message;

  /// Null hides "Try again" (the data is from a newer app).
  final VoidCallback? onRetry;

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
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center),
                    if (note != null) ...[
                      const SizedBox(height: 12),
                      Text(note!, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 24),
                    if (onRetry != null) ...[
                      FilledButton(
                        onPressed: onRetry,
                        child: const Text('Try again'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (onRestoreBackup != null) ...[
                      Builder(
                        builder: (context) => OutlinedButton(
                          onPressed: () => _pickBackup(context),
                          child: const Text(kRestoreLatestBackupButton),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (onStartFresh != null) ...[
                      Builder(
                        builder: (context) => TextButton(
                          onPressed: () => _confirmStartFresh(context),
                          child: const Text(kStartFreshButton),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
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
