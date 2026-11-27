import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;

import 'package:pos_app/core/providers/hive_provider.dart'
    show kAutoBackupLastAt;
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/connection/native.dart' show databaseFile;
import 'package:pos_app/features/backup/data/open_failure_recovery.dart'
    show deleteBrokenDatabaseCopies;
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/temp_files.dart';
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

/// Second sentence when a backup will be taken just before the erase (the
/// shop has data, see [preResetBackupNeededProvider]): it replaces the two
/// variants above, which would otherwise promise less than happens.
const kFactoryResetWillBackUp =
    "A backup will be saved first; it doesn't include receipt photos.";

/// Second sentence when there is none.
const kFactoryResetNoBackups =
    'There are no automatic backups on this device, so this cannot be '
    'undone.';

const kFactoryResetConfirmButton = 'Erase everything';

/// The dialog's last line: the newest automatic backup's date.
const kLatestBackupLabel = 'Latest automatic backup: ';
String latestBackupLine(DateTime? latest) => '$kLatestBackupLabel'
    '${latest == null ? 'none' : DateFormat.yMMMd().add_jm().format(latest)}';

/// The dialog's text, read when it opens: [latestBackup] is the newest file
/// in `backups/auto` (null when there is none), [willBackUp] whether a
/// backup is taken before the erase.
String factoryResetConfirmText({
  required DateTime? latestBackup,
  bool willBackUp = false,
}) {
  final second = willBackUp
      ? kFactoryResetWillBackUp
      : latestBackup != null
          ? kFactoryResetBackupsKept
          : kFactoryResetNoBackups;
  return '$kFactoryResetBody\n\n$second\n\n${latestBackupLine(latestBackup)}';
}

/// Shown while the one backup taken just before the erase is written.
const kSavingBackupFirst = 'Saving a backup first…';

/// Asked when that backup failed; the user may still cancel.
const kBackupFirstFailed = "Couldn't save a backup first. Erase anyway?";

/// Whether the shop has anything a pre-reset backup would keep:
/// [hasShopData] (one query) or a held ticket (Hive keys).
final preResetBackupNeededProvider = Provider<Future<bool> Function()>(
  (ref) => () async =>
      hasHeldTickets(ref.read(heldOrdersBoxProvider)) ||
      await hasShopData(ref.read(databaseProvider)),
);

/// Takes ONE automatic backup (no receipt photos, like every automatic
/// backup) just before a factory reset, so the erased shop can be restored
/// from Settings › Backup & Restore. Returns null without writing anything
/// when [preResetBackupNeededProvider] says there is nothing to keep;
/// throws when the backup could not be saved. The cost is paid only at
/// reset.
final preResetBackupProvider = Provider<Future<File?> Function()>(
  (ref) => () async {
    if (!await ref.read(preResetBackupNeededProvider)()) return null;
    final dir = await autoBackupDir();
    final zip = await ref
        .read(snapshotCoordinatorProvider)
        .create(dir, includePhotos: false);
    await pruneAutoBackups(dir, protect: zip);
    return zip;
  },
);

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

/// Settings key written with [kFactoryResetPendingKey] (same write, same
/// flush) when the user chose "Delete my backups too": `true`. Missing
/// means keep them, the safe default. A reset finished at launch or by
/// "Try again" reads it, so it honours the same choice; it goes in the
/// reset's last settings write, with the flag.
const kFactoryResetDeleteBackupsKey = 'factory_reset_delete_backups';

/// The backups question in the confirm dialog.
const kResetBackupsQuestion = 'What about the backups on this device?';
const kResetKeepBackups = 'Keep my backups on this device';
const kResetKeepBackupsMeans =
    'Automatic backups stay on this device, so you can restore later.';
const kResetDeleteBackups = 'Delete my backups too';
const kResetDeleteBackupsMeans =
    "All backups on this device are deleted too. This can't be undone. "
    'Copies you saved elsewhere are not affected.';

/// The extra step when "Delete my backups too" is chosen.
const kResetDeleteBackupsConfirmTitle = 'Delete your backups too?';
const kResetDeleteBackupsConfirmButton = 'Delete backups and erase';

/// Whether the pending reset deletes the backups ([kFactoryResetDeleteBackupsKey]).
bool resetDeletesBackups(Box<dynamic> settings) =>
    settings.get(kFactoryResetDeleteBackupsKey) == true;

/// The reset's steps, in order (for the kill-point tests).
enum FactoryResetStep {
  flagWritten,
  databaseErased,
  heldTicketsCleared,
  usageCleared,
  receiptsDeleted,
  brokenCopiesDeleted,
  tempFilesDeleted,
  backupsDeleted,
  settingsCleared,
}

/// Test hook run after each step; a throw there models a kill.
typedef FactoryResetStepHook = void Function(FactoryResetStep step);

/// Writes [kFactoryResetPendingKey] durably, before anything is erased,
/// together with the backups choice ([kFactoryResetDeleteBackupsKey]: set
/// when [deleteBackups], absent otherwise), in one write. Throws unless a
/// re-read confirms both.
Future<void> markFactoryResetPending(Box<dynamic> settings,
    {bool deleteBackups = false}) async {
  if (!deleteBackups && settings.containsKey(kFactoryResetDeleteBackupsKey)) {
    await settings.delete(kFactoryResetDeleteBackupsKey);
  }
  await settings.putAll({
    if (deleteBackups) kFactoryResetDeleteBackupsKey: true,
    kFactoryResetPendingKey: true,
  });
  await settings.flush();
  if (!isFactoryResetPending(settings) ||
      resetDeletesBackups(settings) != deleteBackups) {
    throw StateError('the factory reset choice was not saved');
  }
}

/// Whether a factory reset was started and not finished.
bool isFactoryResetPending(Box<dynamic> settings) =>
    settings.get(kFactoryResetPendingKey) == true;

/// Clears the pending flag and confirms it is gone: the delete and the
/// flush must both succeed and a re-read must no longer find the key.
/// Tried [attempts] times with a short, growing pause (a full disk may
/// free up). True only when confirmed — a caller must never tell the user
/// "nothing changed" while the flag may still be set, because the next
/// launch would act on it.
Future<bool> clearFactoryResetPendingConfirmed(
  Box<dynamic> settings, {
  int attempts = 3,
  Duration pause = const Duration(milliseconds: 50),
}) async {
  for (var i = 0; i < attempts; i++) {
    try {
      // The backups choice belongs to the flag: it goes with it, first (a
      // kill in between leaves the flag with no choice: keep, the safe
      // side).
      if (settings.containsKey(kFactoryResetDeleteBackupsKey)) {
        await settings.delete(kFactoryResetDeleteBackupsKey);
      }
      await settings.delete(kFactoryResetPendingKey);
      await settings.flush();
      if (!settings.containsKey(kFactoryResetPendingKey)) return true;
    } catch (e) {
      debugPrint('Factory reset: clearing the pending flag failed: $e');
    }
    if (i < attempts - 1) await Future<void>.delayed(pause * (i + 1));
  }
  return false;
}

/// The blocking question shown when a reset is pending but the data is
/// still there (see [PendingFactoryReset.askUser] and
/// [FactoryResetOutcome.undecided]). Nothing is erased until the user
/// chooses.
const kResetChoiceTitle = 'Finish the factory reset?';
const kResetChoiceMessage = "A factory reset on this device didn't finish, "
    'and your data is still here. Erase everything now, or keep your data?';
const kResetChoiceFinish = 'Finish erasing';

/// Added to [kResetChoiceMessage] when that reset deletes the backups.
const kResetChoiceDeletesBackups =
    'Finishing it also deletes the backups on this device.';

/// The question's text for the pending reset in [settings].
String resetChoiceMessage(Box<dynamic> settings) =>
    resetDeletesBackups(settings)
        ? '$kResetChoiceMessage $kResetChoiceDeletesBackups'
        : kResetChoiceMessage;

/// Told after a reset that could not delete every backup it was asked to:
/// the reset itself is finished.
const kResetBackupsLeftNotice = "Some backups couldn't be deleted.";

/// Set by [eraseLocalStores] when "Delete my backups too" could not delete
/// them all; read (and cleared) by whoever reports the finished reset.
bool factoryResetLeftBackups = false;

/// The notice after a factory reset was finished at launch: says so, and
/// that some backups could not be deleted when that happened.
String finishedResetNotice() {
  if (!factoryResetLeftBackups) return kFactoryResetFinishedNotice;
  factoryResetLeftBackups = false;
  return '$kFactoryResetFinishedNotice $kResetBackupsLeftNotice';
}
const kResetChoiceKeep = 'Keep my data';

/// "Keep my data" could not be saved (the flag would not clear).
const kResetKeepFailed = "Couldn't save your choice. Free up some space on "
    'this device, then tap Keep my data again.';

/// "Finish erasing" could not write (a full disk): the question stays.
const kResetFinishFailed = "Couldn't finish erasing. Free up some space on "
    'this device, then try again.';

/// After "Keep my data".
const kResetKeptNotice = 'Your data was kept. Nothing was erased.';

/// The Hive and file half of a factory reset (the database half is
/// `AppDatabase.eraseAllData`, which runs first). In this order:
/// 1. every held ticket in [heldOrders], keeping its ticket counter so
///    numbers never repeat;
/// 2. [usage] — counts and flags, so the first-run usage notice shows again;
/// 3. the receipt photos folder [receipts];
/// 4. when [temp] is given, the shared-file leftovers in it: the share
///    folder, share_plus's copies and backup working files
///    ([sweepTempLeftovers]) — copies of the shop's data;
/// 5. only when the user chose "Delete my backups too"
///    ([resetDeletesBackups], read from [settings]) and [backups] is given:
///    the whole backups folder (automatic backups and any other backup the
///    app made there);
/// 6. LAST, [settings] (so onboarding shows again), except
///    [kSettingsKeptByReset], in one write whose final key is
///    [kFactoryResetPendingKey] — so the reset counts as done only once
///    everything else is gone, and the kept keys are never deleted (no
///    clear-then-put window that could lose them).
///
/// Each box is compacted after its deletes, so the erased values are gone
/// from the .hive files, not only hidden. Every step is idempotent, so [finishPendingFactoryReset] can rerun the
/// whole thing. Automatic backups (`backups/auto`) are not touched. Run
/// with the app's widget tree and providers torn down, so nothing writes
/// back stale state.
Future<void> eraseLocalStores({
  required Box<dynamic> settings,
  required Box<dynamic> heldOrders,
  required Box<dynamic> usage,
  required Directory receipts,
  File? database,
  Directory? temp,
  Directory? backups,
  FactoryResetStepHook? afterStep,
}) async {
  await clearHeldTicketsKeepingCounter(heldOrders);
  await heldOrders.flush();
  afterStep?.call(FactoryResetStep.heldTicketsCleared);
  await usage.clear();
  await compactBox(usage);
  afterStep?.call(FactoryResetStep.usageCleared);
  if (receipts.existsSync()) await receipts.delete(recursive: true);
  afterStep?.call(FactoryResetStep.receiptsDeleted);
  // Copies of a damaged database set aside by "Start fresh" hold the
  // shop's old sales: they go too.
  if (database != null) {
    await deleteBrokenDatabaseCopies(database, everything: true);
  }
  afterStep?.call(FactoryResetStep.brokenCopiesDeleted);
  // Exports and full backups handed to the share sheet, and backup working
  // files a kill left behind. Never anything in the backups folder.
  if (temp != null) await sweepTempLeftovers(temp, sharePlusCache: true);
  afterStep?.call(FactoryResetStep.tempFilesDeleted);
  // Kept unless the user asked for them to go (the default keeps them).
  // A backup that will not go does not stop the reset (it would loop on
  // the error screen): the rest is finished and the user is told.
  if (backups != null &&
      resetDeletesBackups(settings) &&
      !await _deleteAllIn(backups)) {
    factoryResetLeftBackups = true;
  }
  afterStep?.call(FactoryResetStep.backupsDeleted);
  final doomed = [
    for (final k in settings.keys)
      if (!kSettingsKeptByReset.contains(k) && k != kFactoryResetPendingKey) k,
    kFactoryResetPendingKey,
  ];
  await settings.deleteAll(doomed);
  // Compacted: Hive only appends, so the deleted settings (shop name,
  // address, PIN…) would otherwise stay readable in settings.hive.
  try {
    await compactBox(settings);
  } catch (e) {
    // The reset itself is done (the flag is gone); Hive compacts on its
    // own later.
    debugPrint('Factory reset: compacting settings failed: $e');
  }
  afterStep?.call(FactoryResetStep.settingsCleared);
}

/// Deletes [dir] and everything in it, one entry at a time when the folder
/// will not go at once. True when nothing is left; never throws.
Future<bool> _deleteAllIn(Directory dir) async {
  try {
    if (!await dir.exists()) return true;
    await dir.delete(recursive: true);
    return true;
  } catch (e) {
    debugPrint('Factory reset: deleting the backups failed: $e');
  }
  try {
    await for (final e in dir.list(recursive: true, followLinks: false)) {
      if (e is File || e is Link) {
        try {
          await e.delete();
        } catch (_) {}
      }
    }
    return !(await dir
        .list(recursive: true, followLinks: false)
        .any((e) => e is File || e is Link));
  } catch (_) {
    return false;
  }
}

/// What the launch found about a pending factory reset.
enum PendingFactoryReset {
  /// No reset pending (one key read).
  none,

  /// A reset was pending and the database was already erased (the kill
  /// came after its commit): it was finished.
  finished,

  /// A reset is pending but the database still holds the user's data — a
  /// stale flag (e.g. a disk too full to clear it) or a kill before the
  /// erase committed. Nothing was erased: the user must choose
  /// ([kResetChoiceTitle]).
  askUser,
}

/// Finishes a factory reset that a kill interrupted — but only when the
/// database erase had already committed ([databaseHasUserData] is false):
/// then it reruns the erase (idempotent) and [eraseLocalStores]. A pending
/// flag on a database that still holds data is never acted on silently:
/// [PendingFactoryReset.askUser]. Run at launch before any screen builds
/// (see `startUp`) and by `AppRoot`'s "Try again".
Future<PendingFactoryReset> finishPendingFactoryReset({
  required Box<dynamic> settings,
  required Future<bool> Function() databaseHasUserData,
  required Future<void> Function() eraseDatabase,
  required Box<dynamic> heldOrders,
  required Future<Box<dynamic>> Function() usage,
  required Future<Directory> Function() receipts,
  Future<File> Function()? database,
  Future<Directory> Function()? temp,
  Future<Directory> Function()? backups,
}) async {
  if (!isFactoryResetPending(settings)) return PendingFactoryReset.none;
  if (await databaseHasUserData()) return PendingFactoryReset.askUser;
  await eraseDatabase();
  await eraseLocalStores(
    settings: settings,
    heldOrders: heldOrders,
    usage: await usage(),
    receipts: await receipts(),
    database: database == null ? null : await database(),
    temp: await _tempOrNull(temp),
    backups: backups == null ? null : await backups(),
  );
  return PendingFactoryReset.finished;
}

/// [finishPendingFactoryReset] on the app's open Hive boxes and [db], for
/// launch and "Try again".
Future<PendingFactoryReset> finishPendingFactoryResetOnLaunch(
        AppDatabase Function() db) =>
    finishPendingFactoryReset(
      settings: Hive.box<dynamic>('settings'),
      databaseHasUserData: () => hasShopData(db()),
      eraseDatabase: () => db().eraseAllDataAndCompact(),
      heldOrders: Hive.box<dynamic>('held_orders'),
      usage: usageBoxForReset,
      receipts: receiptsDir,
      // The pending flag only ever belongs to a reset the user confirmed
      // (Start fresh clears it before setting a database aside), so an
      // interrupted reset finishes the job: the old shop's set-aside copies
      // go too.
      database: databaseFile,
      temp: getTemporaryDirectory,
      // The stored choice decides: a missing key keeps them.
      backups: backupsDir,
    );

/// [temp]'s folder, or null when there is none or it cannot be found
/// (the temp sweep is then skipped, never the reset).
Future<Directory?> _tempOrNull(Future<Directory> Function()? temp) async {
  if (temp == null) return null;
  try {
    return await temp();
  } catch (_) {
    return null;
  }
}

/// How [runFactoryReset] ended.
enum FactoryResetOutcome {
  /// Everything erased; the app comes up like a first run.
  done,

  /// The database erase was refused (rolled back), or the flag could not
  /// be written: nothing changed, and the flag is confirmed cleared.
  refused,

  /// Nothing was erased, but the pending flag may still be set (it could
  /// not be confirmed cleared — typically a full disk). The user is asked
  /// [kResetChoiceTitle] before anything else; never "not changed".
  undecided,

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
  Future<File> Function()? database,
  Future<Directory> Function()? temp,
  Future<Directory> Function()? backups,
  bool deleteBackups = false,
  FactoryResetStepHook? afterStep,
}) async {
  // Nothing erased yet: "not changed" only once the flag is confirmed
  // gone, or the next launch would act on a stale flag.
  Future<FactoryResetOutcome> unchanged() async =>
      await clearFactoryResetPendingConfirmed(settings)
          ? FactoryResetOutcome.refused
          : FactoryResetOutcome.undecided;
  // Already set ("Finish erasing" on a pending reset): writing it again
  // could only fail on a full disk; go straight to the erase.
  // [deleteBackups] is saved with the flag; a reset already pending keeps
  // the choice it was started with.
  if (!isFactoryResetPending(settings)) {
    try {
      await markFactoryResetPending(settings, deleteBackups: deleteBackups);
    } catch (_) {
      // The put may have reached the box even though the flush failed.
      return unchanged();
    }
  }
  afterStep?.call(FactoryResetStep.flagWritten);
  try {
    await eraseDatabase();
  } catch (_) {
    // Rolled back: the shop is unchanged, so it is not a pending reset.
    return unchanged();
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
      database: database == null ? null : await database(),
      temp: await _tempOrNull(temp),
      backups: backups == null ? null : await backups(),
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
