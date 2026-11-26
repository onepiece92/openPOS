import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/providers/hive_provider.dart'
    show kAutoBackupLastAt;
import 'package:pos_app/features/backup/data/snapshot_providers.dart'
    show receiptsDir;
import 'package:pos_app/features/cart/data/ticket_sequence.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';

/// Factory Reset's confirm dialog: exactly what goes and what stays.
/// test/features/settings/factory_reset_text_test.dart maps every table
/// `AppDatabase.eraseAllData` deletes, every Hive box and the receipts
/// folder to a phrase in [kFactoryResetBody] — add the words there when
/// the reset erases something new.
const kFactoryResetTitle = 'Erase everything?';
const kFactoryResetBody =
    'This permanently deletes everything in Open POS on this device: sales, '
    'refunds and day closes, products and categories, customers, expenses '
    'and expense categories, tax rates, stock history, held tickets, tables, '
    'receipt photos, usage counts, the activity log and your settings.';

/// Second sentence when at least one automatic backup is on the device.
const kFactoryResetBackupsKept =
    'Automatic backups already saved on this device are kept; they don\'t '
    'include receipt photos. You can restore one from '
    'Settings › Backup & Restore.';

/// Second sentence when there is none.
const kFactoryResetNoBackups =
    'There are no automatic backups on this device, so this cannot be '
    'undone.';

const kFactoryResetConfirmButton = 'Erase everything';

/// The dialog's text; [hasAutoBackups] is checked when it opens.
String factoryResetConfirmText({required bool hasAutoBackups}) =>
    '$kFactoryResetBody\n\n'
    '${hasAutoBackups ? kFactoryResetBackupsKept : kFactoryResetNoBackups}';

/// Settings keys a factory reset keeps: automatic-backup bookkeeping. The
/// backups kept on the device are how a regretted reset is undone, so the
/// reset must not bring the next automatic backup (of empty data) forward.
const kSettingsKeptByReset = [kAutoBackupLastAt];

/// Shown on the reset's splash while the data is erased.
const kFactoryResetProgress = 'Resetting…';

/// Shown when the database could not be erased (nothing was changed).
const kFactoryResetFailedNotice =
    "Reset didn't work. Your data was not changed.";

/// The error screen when the reset erased the database but could not
/// clear everything else. Nothing of the app opens on the half-erased
/// stores: "Try again" (and any later launch) finishes the reset, because
/// [kFactoryResetPendingKey] is still set.
const kFactoryResetIncompleteTitle = "Reset didn't finish";
const kFactoryResetIncompleteNotice =
    "Open POS couldn't finish erasing this device. Try again to finish it.";

/// Shown on the next launch after a reset interrupted part-way (app killed,
/// phone switched off) was finished.
const kFactoryResetFinishedNotice = 'The factory reset was finished.';

/// Settings key set — and flushed — before a factory reset erases
/// anything, and removed in the very last write of the reset. While it is
/// set the reset is unfinished, and [finishPendingFactoryReset] completes
/// it on launch: so a kill at any point leaves either the old shop (killed
/// before the flag) or, after the next launch, a clean fresh shop — never
/// a mix of erased data and old settings.
const kFactoryResetPendingKey = 'factory_reset_pending';

/// The reset's steps, in order (for the kill-point tests).
enum FactoryResetStep {
  flagWritten,
  databaseErased,
  heldTicketsCleared,
  usageCleared,
  receiptsDeleted,
  settingsCleared,
}

/// Test hook run after each step; a throw there models a kill.
typedef FactoryResetStepHook = void Function(FactoryResetStep step);

/// Writes [kFactoryResetPendingKey] durably, before anything is erased.
Future<void> markFactoryResetPending(Box<dynamic> settings) async {
  await settings.put(kFactoryResetPendingKey, true);
  await settings.flush();
}

/// Whether a factory reset was started and not finished.
bool isFactoryResetPending(Box<dynamic> settings) =>
    settings.get(kFactoryResetPendingKey) == true;

/// Clears the pending flag (only when the database erase was refused, so
/// nothing changed).
Future<void> clearFactoryResetPending(Box<dynamic> settings) async {
  await settings.delete(kFactoryResetPendingKey);
  await settings.flush();
}

/// The Hive and file half of a factory reset (the database half is
/// `AppDatabase.eraseAllData`, which runs first). In this order:
/// 1. every held ticket in [heldOrders], keeping its ticket counter so
///    numbers never repeat;
/// 2. [usage] — counts and flags, so the first-run usage notice shows again;
/// 3. the receipt photos folder [receipts];
/// 4. LAST, [settings] (so onboarding shows again), except
///    [kSettingsKeptByReset], in one write whose final key is
///    [kFactoryResetPendingKey] — so the reset counts as done only once
///    everything else is gone, and the kept keys are never deleted (no
///    clear-then-put window that could lose them).
///
/// Every step is idempotent, so [finishPendingFactoryReset] can rerun the
/// whole thing. Automatic backups (`backups/auto`) are not touched. Run
/// with the app's widget tree and providers torn down, so nothing writes
/// back stale state.
Future<void> eraseLocalStores({
  required Box<dynamic> settings,
  required Box<dynamic> heldOrders,
  required Box<dynamic> usage,
  required Directory receipts,
  FactoryResetStepHook? afterStep,
}) async {
  await clearHeldTicketsKeepingCounter(heldOrders);
  await heldOrders.flush();
  afterStep?.call(FactoryResetStep.heldTicketsCleared);
  await usage.clear();
  await usage.flush();
  afterStep?.call(FactoryResetStep.usageCleared);
  if (receipts.existsSync()) await receipts.delete(recursive: true);
  afterStep?.call(FactoryResetStep.receiptsDeleted);
  final doomed = [
    for (final k in settings.keys)
      if (!kSettingsKeptByReset.contains(k) && k != kFactoryResetPendingKey) k,
    kFactoryResetPendingKey,
  ];
  await settings.deleteAll(doomed);
  await settings.flush();
  afterStep?.call(FactoryResetStep.settingsCleared);
}

/// Finishes a factory reset that a kill interrupted: reruns the database
/// erase (idempotent: empty tables stay empty, the defaults are seeded
/// only once) and then [eraseLocalStores]. Returns false at once — one
/// key read — when no reset is pending. Run at launch before any screen
/// builds (see `startUp`) and by `AppRoot`'s "Try again".
Future<bool> finishPendingFactoryReset({
  required Box<dynamic> settings,
  required Future<void> Function() eraseDatabase,
  required Box<dynamic> heldOrders,
  required Future<Box<dynamic>> Function() usage,
  required Future<Directory> Function() receipts,
}) async {
  if (!isFactoryResetPending(settings)) return false;
  await eraseDatabase();
  await eraseLocalStores(
    settings: settings,
    heldOrders: heldOrders,
    usage: await usage(),
    receipts: await receipts(),
  );
  return true;
}

/// [finishPendingFactoryReset] on the app's open Hive boxes, for launch and
/// "Try again". [eraseDatabase] erases the database the app is about to
/// use.
Future<bool> finishPendingFactoryResetOnLaunch(
        Future<void> Function() eraseDatabase) =>
    finishPendingFactoryReset(
      settings: Hive.box<dynamic>('settings'),
      eraseDatabase: eraseDatabase,
      heldOrders: Hive.box<dynamic>('held_orders'),
      usage: usageBoxForReset,
      receipts: receiptsDir,
    );

/// How [runFactoryReset] ended.
enum FactoryResetOutcome {
  /// Everything erased; the app comes up like a first run.
  done,

  /// The database erase was refused (rolled back): nothing changed.
  refused,

  /// The database is erased but the local stores are not all cleared; the
  /// pending flag is still set, so it must be finished before the app opens.
  incomplete,
}

/// The whole factory reset, in its durable order:
/// [markFactoryResetPending] (flushed) → [eraseDatabase] (one transaction)
/// → [releaseDatabase] (flush usage counts, close the DB, drop the old
/// providers) → [eraseLocalStores] (held tickets, usage, receipt photos,
/// settings last, which also removes the flag).
///
/// A kill anywhere leaves either the old shop (before the flag, or before
/// the DB commit, which [finishPendingFactoryReset] then completes) or a
/// fresh one. A [releaseDatabase] failure (the old connection would not
/// close) is caught: the erase has committed, so the reset carries on
/// rather than stopping half-way. [afterStep] is a test hook.
Future<FactoryResetOutcome> runFactoryReset({
  required Box<dynamic> settings,
  required Future<void> Function() eraseDatabase,
  required Future<void> Function() releaseDatabase,
  required Box<dynamic> heldOrders,
  required Future<Box<dynamic>> Function() usage,
  required Future<Directory> Function() receipts,
  FactoryResetStepHook? afterStep,
}) async {
  try {
    await markFactoryResetPending(settings);
  } catch (_) {
    return FactoryResetOutcome.refused;
  }
  afterStep?.call(FactoryResetStep.flagWritten);
  try {
    await eraseDatabase();
  } catch (_) {
    // Rolled back: the shop is unchanged, so it is not a pending reset.
    try {
      await clearFactoryResetPending(settings);
    } catch (_) {/* the next launch then finishes the reset */}
    return FactoryResetOutcome.refused;
  }
  afterStep?.call(FactoryResetStep.databaseErased);
  try {
    await releaseDatabase();
  } catch (e) {
    debugPrint('Factory reset: closing the old database failed: $e');
  }
  try {
    await eraseLocalStores(
      settings: settings,
      heldOrders: heldOrders,
      usage: await usage(),
      receipts: await receipts(),
      afterStep: afterStep,
    );
  } catch (_) {
    return FactoryResetOutcome.incomplete;
  }
  return FactoryResetOutcome.done;
}

/// The usage box, opened beside the settings box when the usage counter
/// never opened it (it opens lazily).
Future<Box<dynamic>> usageBoxForReset() async {
  if (Hive.isBoxOpen(kUsageBoxName)) return Hive.box<dynamic>(kUsageBoxName);
  final settingsPath = Hive.box<dynamic>('settings').path;
  return Hive.openBox<dynamic>(kUsageBoxName,
      path: settingsPath == null ? null : p.dirname(settingsPath));
}
