import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/features/backup/data/temp_files.dart';
import 'package:pos_app/core/database/connection/native.dart';
import 'package:pos_app/core/database/database_open_errors.dart';
import 'package:pos_app/core/providers/hive_provider.dart'
    show kOnboardingCompleteKey;
import 'package:pos_app/features/backup/data/restore_merge_marker.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/features/review/data/review_state_store.dart';
import 'package:pos_app/features/settings/data/factory_reset.dart';

/// How the app should come up: with an optional toast, or — when [fatal] is
/// set — on the error screen with nothing opened.
class StartupResult {
  const StartupResult(
      {this.notice, this.fatal, this.dbError, this.resetChoice = false});
  final String? notice;
  final String? fatal;

  /// The first database query failed (e.g. the file is from a newer app):
  /// the app starts on the error screen, see `AppRoot.startupDbError`.
  final Object? dbError;

  /// A factory reset is pending on a database that still holds data: the
  /// app starts on the blocking "Finish erasing" / "Keep my data" question.
  final bool resetChoice;
}

/// Launch startup, run while `AppRoot` shows its plain first frame (see
/// `AppRoot.startup`), in this order:
/// 1. [recover] an interrupted restore — before Hive is even initialised,
///    so no box or DB file is touched while a swap may be half done;
/// 2. [initHive] (sets Hive's path only; opens nothing);
/// 3. [openStores], skipped when recovery failed: opening then would let
///    Drift create an empty DB while the real one is still in `.bak`.
///    `AppRoot`'s retry reruns recovery and opens the stores itself;
/// 4. [checkDatabase], when given: the database's first query (`SELECT 1`
///    on the connection the app goes on to use, so it costs one trivial
///    query). A failure is returned as [StartupResult.dbError] instead of
///    surfacing later as broken screens;
/// 5. [finishFactoryReset], when given and the check passed: completes a
///    factory reset a kill interrupted (one settings key read when there
///    is none), then restarts the review clock it cleared — still before
///    any screen builds, so no screen ever sees half-erased stores. A
///    failure goes to the error screen like a failed check ("Try again"
///    finishes it).
///
/// The parameters exist for tests; `main()` uses the defaults and passes
/// [checkDatabase].
Future<StartupResult> startUp({
  Future<RestoreRecovery?> Function()? recover,
  Future<void> Function()? initHive,
  Future<void> Function()? openStores,
  Future<void> Function()? checkDatabase,
  Future<PendingFactoryReset> Function()? finishFactoryReset,
  Future<void> Function()? sweepTemp,
}) async {
  final recovery = await (recover ?? recoverInterruptedRestoreAtStartup)();
  // Shared exports and backup working files a kill left in temp; before
  // anything could be writing one. Never throws.
  await (sweepTemp ?? sweepAppTempLeftovers)();
  await (initHive ?? () => Hive.initFlutter())();
  if (recovery == null) {
    return const StartupResult(fatal: kRecoveryFailedMessage);
  }
  await (openStores ?? openStartupStores)();
  if (checkDatabase != null) {
    try {
      await checkDatabase();
    } catch (e) {
      return StartupResult(dbError: e);
    }
  }
  var resetFinished = false;
  if (finishFactoryReset != null) {
    try {
      switch (await finishFactoryReset()) {
        case PendingFactoryReset.none:
          break;
        case PendingFactoryReset.finished:
          resetFinished = true;
          await startReviewClock();
        case PendingFactoryReset.askUser:
          return const StartupResult(resetChoice: true);
      }
    } catch (e) {
      return StartupResult(dbError: e);
    }
  }
  // A restore killed on its error screen: finish its merge (one exists
  // check when there is none).
  if (await finishPendingRestoreMerge(recovery)) {
    return const StartupResult(notice: kRestoreCompletedOnRetryNotice);
  }
  return StartupResult(
      notice: restoreRecoveryNotice(recovery) ??
          (resetFinished ? finishedResetNotice() : null));
}

/// Opens the Hive boxes before the ProviderContainer exists so providers
/// can read synchronously (the DB itself is owned by `databaseProvider`),
/// and starts the review-prompt clock (no-op after the first launch).
Future<void> openStartupStores() async {
  await Future.wait([
    // Not the lazily-opened `usage` box: it must not delay the first frame.
    for (final name in kStartupHiveBoxes) Hive.openBox<dynamic>(name),
  ]);
  await startReviewClock();
}

/// Starts the review-prompt clock (no-op after the first launch). Needs
/// the settings box open. Also run by `AppRoot`'s retry, which opens the
/// stores itself when startup recovery had failed.
Future<void> startReviewClock() =>
    ReviewStateStore(Hive.box<dynamic>('settings'))
        .ensureFirstLaunch(DateTime.now());

/// Run just before the database's first open (launch, Try again, the
/// reopen after a restore): a missing or 0-byte database file while
/// onboarding is complete is refused with [DatabaseMissingError] — the
/// error screen — instead of Drift quietly creating an empty database
/// under the old settings. Needs the settings box open; costs one exists
/// check and one length.
Future<void> checkDatabaseFileBeforeOpen() async => assertDatabaseFilePresent(
      onboardingComplete:
          Hive.box<dynamic>('settings').get(kOnboardingCompleteKey) == true,
      file: await databaseFile(),
    );
