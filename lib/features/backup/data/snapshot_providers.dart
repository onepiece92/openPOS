import 'dart:io';
import 'dart:isolate';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/connection/native.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/backup/data/share_files.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/features/cart/data/ticket_sequence.dart'
    show kTicketSeqKey;
import 'package:pos_app/features/settings/data/factory_reset.dart'
    show kFactoryResetPendingKey;
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/usage_providers.dart';

/// Hive boxes opened before the first frame (`openStartupStores`).
const kStartupHiveBoxes = ['settings', 'held_orders'];

/// Names of the Hive boxes that travel with a snapshot: the startup boxes
/// plus `usage`, which the usage counter opens lazily after the first frame
/// (backup and restore make sure it is open before they list the files;
/// restore recovery and the post-restore reopen use this whole list).
const kSnapshotHiveBoxes = [...kStartupHiveBoxes, kUsageBoxName];

/// How many automatic snapshots to keep on-device.
const kAutoBackupKeep = 7;

/// Settings key: the NAMES of the automatic backups that existed when
/// "Start fresh" ran — the only copies of the shop that was set aside.
/// While set, those files are never pruned; pruning carries on as usual
/// (newest [kAutoBackupKeep]) among all the others. Names, not times, so a
/// clock set back cannot stop pruning for good. Restoring any backup, the
/// Backup & Restore screen's "Dismiss", or a factory reset ends it.
const kStartFreshKeptBackupsKey = 'start_fresh_kept_backups';

/// The Backup & Restore line while those backups are kept.
const kPrunePausedNotice = 'Backups from before Start fresh are kept. '
    'Restore one, or dismiss to let new backups replace them.';

/// The backups kept by "Start fresh", or null when none are (one key read).
Set<String>? autoBackupsKeptByStartFresh() {
  if (!Hive.isBoxOpen('settings')) return null;
  return autoBackupsKeptIn(Hive.box<dynamic>('settings'));
}

/// Records [names] as kept (Start fresh), added to any list a previous
/// Start fresh left. Runs BEFORE anything is set aside: true only when the
/// write and flush succeeded and a re-read finds every name, so the caller
/// can refuse rather than leave the old shop's backups unprotected. True
/// at once when there is nothing to protect. Never throws.
Future<bool> keepAutoBackupsForStartFresh(
  Iterable<String> names, {
  Box<dynamic>? settings,
}) async {
  final add = names.toSet();
  if (add.isEmpty) return true; // nothing from before to protect
  try {
    final s = settings ?? Hive.box<dynamic>('settings');
    final list = {...?autoBackupsKeptIn(s), ...add}.toList();
    await s.put(kStartFreshKeptBackupsKey, list);
    await s.flush();
    final back = autoBackupsKeptIn(s);
    return back != null && back.containsAll(add);
  } catch (e) {
    debugPrint('Start fresh: could not record the kept backups: $e');
    return false;
  }
}

/// The names kept in [settings], or null.
Set<String>? autoBackupsKeptIn(Box<dynamic> settings) {
  final v = settings.get(kStartFreshKeptBackupsKey);
  if (v is! List || v.isEmpty) return null;
  return {for (final n in v) '$n'};
}

/// Ends the pause (restore, Dismiss). Never throws.
Future<void> endAutoBackupPrunePause() async {
  try {
    if (!Hive.isBoxOpen('settings')) return;
    final s = Hive.box<dynamic>('settings');
    if (!s.containsKey(kStartFreshKeptBackupsKey)) return;
    await s.delete(kStartFreshKeptBackupsKey);
    await s.flush();
  } catch (_) {/* best effort; the next restore or Dismiss tries again */}
}

/// Prunes `backups/auto` to the newest [kAutoBackupKeep], never deleting
/// [protect] nor any backup [autoBackupsKeptByStartFresh] names (those do
/// not count toward the seven). Returns how many were deleted.
Future<int> pruneAutoBackups(Directory dir, {required File protect}) async {
  const svc = SnapshotService();
  final kept = autoBackupsKeptByStartFresh();
  if (kept == null) {
    return svc.prune(dir, keep: kAutoBackupKeep, protect: protect);
  }
  final keepPath = p.canonicalize(protect.path);
  var kept7 = 1; // protect
  var deleted = 0;
  for (final f in await svc.listLocal(dir)) {
    if (kept.contains(p.basename(f.path))) continue;
    if (p.canonicalize(f.path) == keepPath) continue;
    if (kept7 < kAutoBackupKeep) {
      kept7++;
      continue;
    }
    await f.delete();
    deleted++;
  }
  return deleted;
}

const kAutoBackupInterval = Duration(hours: 24);

/// `box name → file path` for every open snapshot box. Resolved from the
/// live Box objects so it's always the path Hive is actually using.
Map<String, String> snapshotHiveBoxFiles() => {
      for (final name in kSnapshotHiveBoxes)
        if (Hive.isBoxOpen(name) && Hive.box<dynamic>(name).path != null)
          name: Hive.box<dynamic>(name).path!,
    };

/// Box files where `Hive.initFlutter()` keeps them (the documents folder),
/// resolvable before any box is open.
List<String> defaultHiveBoxPaths(Directory docs) =>
    [for (final name in kSnapshotHiveBoxes) p.join(docs.path, '$name.hive')];

/// Undoes (or finishes) a restore the app was killed in the middle of.
/// Must run before Hive boxes or the DB open; when no restore was
/// interrupted it costs a few file-exists checks. [docsDir] overrides the
/// documents folder (tests).
///
/// Never throws. Returns null when the disk could not be put right: the
/// caller must then NOT open the stores (Drift would create an empty DB
/// while the real one is still in `.bak`). The journal stays, so a retry
/// picks up where this left off.
Future<RestoreRecovery?> recoverInterruptedRestoreAtStartup(
    {Directory? docsDir}) async {
  try {
    final docs = docsDir ?? await getApplicationDocumentsDirectory();
    return await SnapshotService.recoverInterruptedRestore(
      dbFile: File(p.join(docs.path, kDatabaseFileName)),
      hivePaths: defaultHiveBoxPaths(docs),
      receiptsDir: Directory(p.join(docs.path, kReceiptsDirName)),
    );
  } catch (e, st) {
    debugPrint('Restore recovery failed: $e\n$st');
    return null;
  }
}

/// Shown instead of the app when [recoverInterruptedRestoreAtStartup]
/// returns null.
const kRecoveryFailedMessage =
    "A restore was interrupted and the app couldn't finish undoing it, so "
    "it hasn't opened your data yet. Your previous data is still saved on "
    'this device. Tap "Try again". If this keeps happening, contact support.';

/// Toast for the first frame after [recoverInterruptedRestoreAtStartup].
String? restoreRecoveryNotice(RestoreRecovery? r) => switch (r) {
      RestoreRecovery.rolledBack =>
        'A restore was interrupted. Your previous data was put back.',
      RestoreRecovery.recoveredWithoutJournal =>
        "A restore was interrupted and its progress record couldn't be "
            'read. Your previous data was put back, but some receipt photos '
            'from the backup may remain. Please check your recent records.',
      RestoreRecovery.recoveredWithoutJournalUncertain =>
        "A restore was interrupted and its progress record couldn't be "
            'read. Your previous data may have been put back. Please check '
            'your recent records.',
      RestoreRecovery.missingFilesPutBack =>
        'A restore was interrupted and some data was missing. The saved '
            'copy was put back. Please check your recent records.',
      RestoreRecovery.none || RestoreRecovery.completed || null => null,
    };

/// Shown after "Try again" finds that the restore had in fact been
/// accepted (its commit was recorded but the app could not confirm it).
const kRestoreCompletedOnRetryNotice = 'The backup was restored.';

/// How long a restart notice stays up: long ones (the recovery notices
/// that ask the shopkeeper to check their records) get twice as long.
Duration restartNoticeDuration(String message) => message.length > 60
    ? const Duration(seconds: 8)
    : const Duration(seconds: 4);

const kReceiptsDirName = 'receipts';

/// Where expense receipt photos live (the expense form copies them here).
/// Snapshots carry these photos; restore re-points the DB at this folder.
Future<Directory> receiptsDir() async {
  final docs = await getApplicationDocumentsDirectory();
  return Directory(p.join(docs.path, kReceiptsDirName));
}

Future<Directory> autoBackupDir() async {
  final docs = await getApplicationDocumentsDirectory();
  return Directory(p.join(docs.path, 'backups', 'auto'));
}

final snapshotCoordinatorProvider =
    Provider<SnapshotCoordinator>((ref) => SnapshotCoordinator(ref));

/// App-side choreography around [SnapshotService]: copies the live DB,
/// resolves on-device paths, and runs the (CPU-bound) zip off the UI isolate.
/// Restore lives in `AppRoot` because it must tear the container down.
class SnapshotCoordinator {
  SnapshotCoordinator(this._ref);
  final Ref _ref;
  static const _svc = SnapshotService();

  /// Creates a snapshot in [outDir] and returns the zip file. Receipt
  /// photos are included only when [includePhotos] (manual backups);
  /// automatic backups carry just the DB and Hive.
  Future<File> create(Directory outDir, {bool includePhotos = true}) async {
    final db = _ref.read(databaseProvider);
    // The usage box opens lazily: open it and write pending counts so the
    // snapshot carries them.
    final usage = _ref.read(usageCounterProvider);
    await usage.ensureLoaded();
    await usage.flush();
    for (final name in kSnapshotHiveBoxes) {
      if (Hive.isBoxOpen(name)) await Hive.box<dynamic>(name).flush();
    }
    final now = DateTime.now();
    // `VACUUM INTO` writes a consistent, self-contained copy through the
    // open connection — unlike copying the live file, it can't catch a
    // half-applied write or miss pages still in the WAL.
    final tmpDir = await getTemporaryDirectory();
    final copy = File(
        p.join(tmpDir.path, 'pos_snapshot_${now.microsecondsSinceEpoch}.db'));
    if (await copy.exists()) await copy.delete();
    final quoted = copy.path.replaceAll("'", "''");
    File? strippedSettings;
    try {
      await db.customStatement("VACUUM INTO '$quoted'");
      final dbPath = copy.path;
      final hiveFiles = snapshotHiveBoxFiles();
      strippedSettings = await settingsCopyWithoutResetFlag(tmpDir, now);
      if (strippedSettings != null) {
        hiveFiles['settings'] = strippedSettings.path;
      }
      final outPath = outDir.path;
      final photosPath = (await receiptsDir()).path;
      // Pure-Dart work with only paths captured → safe to run in an isolate.
      return await Isolate.run(() => _svc.create(
            dbFile: File(dbPath),
            hiveBoxFiles: hiveFiles,
            outDir: Directory(outPath),
            receiptsDir: Directory(photosPath),
            includePhotos: includePhotos,
            schemaVersion: AppDatabase.currentSchemaVersion,
            now: now,
          ));
    } finally {
      if (await copy.exists()) await copy.delete();
      if (strippedSettings != null && await strippedSettings.exists()) {
        await strippedSettings.delete();
      }
    }
  }

  /// User-initiated "Back up everything": zip to the temp dir and hand the
  /// file to the OS share sheet (Files / Drive / AirDrop / mail…).
  ///
  /// [shareOrigin] is the on-screen rectangle of the button that was tapped;
  /// iPad anchors the share sheet to it and refuses to share without one.
  Future<File> createAndShare({required Rect shareOrigin}) async {
    final zip = await create(await getTemporaryDirectory());
    await _ref.read(shareFilesProvider)(
      [XFile(zip.path, mimeType: 'application/zip')],
      subject: p.basename(zip.path),
      text: 'POS full backup',
      sharePositionOrigin: shareOrigin,
    );
    return zip;
  }

  /// Reads only the manifest, off the UI isolate — even parsing the zip
  /// directory of a large backup must not freeze the backup screen.
  Future<SnapshotManifest> inspect(File zip) {
    final path = zip.path;
    return Isolate.run(() => SnapshotService.inspectSync(path));
  }

  Future<List<File>> localSnapshots() async =>
      _svc.listLocal(await autoBackupDir());

  /// Called once per launch. No-op when disabled or the last snapshot is
  /// younger than [kAutoBackupInterval]; a last-run time in the future
  /// (clock set back) counts as due. Never throws — backup must not be able
  /// to break app start — but failures are logged and kept in
  /// [autoBackupLastError] for the backup screen.
  Future<File?> runAutoBackupIfDue({DateTime? now}) async {
    try {
      final settings = _ref.read(settingsProvider);
      if (!settings.autoBackupEnabled) return null;
      final t = now ?? DateTime.now();
      final last = settings.autoBackupLastAt;
      if (last != null &&
          !last.isAfter(t) &&
          t.difference(last) < kAutoBackupInterval) {
        return null;
      }
      // Nothing of the user's to keep (a fresh install, or just after a
      // factory reset): an empty backup would only push older ones out of
      // the kept set. One query, only when a backup is due; it stays due,
      // so it runs once there is data. "Back up everything" is unaffected.
      if (!await hasUserData(_ref.read(databaseProvider))) return null;

      final dir = await autoBackupDir();
      // Owner decision: automatic backups never carry receipt photos.
      final zip = await create(dir, includePhotos: false);
      await pruneAutoBackups(dir, protect: zip);
      await _ref.read(settingsProvider.notifier).markAutoBackupRun(t);
      autoBackupLastError.value = null;
      return zip;
    } catch (e, st) {
      debugPrint('Auto-backup failed: $e\n$st');
      autoBackupLastError.value = '$e';
      return null;
    }
  }
}

/// A backup never carries [kFactoryResetPendingKey]: restoring one must not
/// re-arm an erase. Only when the open settings box has the flag (rare: a
/// reset that could not clear it) is a copy of the box written without it
/// into [tmpDir]; returns that file (the caller deletes it), else null at
/// the cost of one key lookup.
Future<File?> settingsCopyWithoutResetFlag(
    Directory tmpDir, DateTime now) async {
  if (!Hive.isBoxOpen('settings')) return null;
  final settings = Hive.box<dynamic>('settings');
  if (!settings.containsKey(kFactoryResetPendingKey)) return null;
  final name = 'settings_snapshot_${now.microsecondsSinceEpoch}';
  final copy = await Hive.openBox<dynamic>(name, path: tmpDir.path);
  try {
    await copy.putAll({
      for (final k in settings.keys)
        if (k != kFactoryResetPendingKey) k: settings.get(k),
    });
    await copy.flush();
    return File(copy.path!);
  } finally {
    await copy.close();
  }
}

/// Whether the database holds anything of the user's: a product, order,
/// customer or expense. One query of four EXISTS probes.
Future<bool> hasUserData(AppDatabase db) async {
  final row = await db
      .customSelect('SELECT EXISTS(SELECT 1 FROM products) '
          'OR EXISTS(SELECT 1 FROM orders) '
          'OR EXISTS(SELECT 1 FROM customers) '
          'OR EXISTS(SELECT 1 FROM expenses) AS has_data')
      .getSingle();
  return row.read<int>('has_data') != 0;
}

/// Wider than [hasUserData], for a factory reset: anything the user set up
/// or recorded — products, orders, customers, expenses, restaurant tables,
/// tax rates, product categories, custom expense categories or day closes
/// (shifts); the reseeded default expense categories do not count. Decides the pre-reset backup and whether a
/// pending reset may finish on its own (it may not while this is true).
/// One query. Held tickets live in Hive: see [hasHeldTickets].
///
/// [hasUserData] stays narrower on purpose: it gates the daily automatic
/// backup, which must not start pushing the pre-reset backups out just
/// because onboarding created a tax rate.
Future<bool> hasShopData(AppDatabase db) async {
  final row = await db
      .customSelect('SELECT EXISTS(SELECT 1 FROM products) '
          'OR EXISTS(SELECT 1 FROM orders) '
          'OR EXISTS(SELECT 1 FROM customers) '
          'OR EXISTS(SELECT 1 FROM expenses) '
          'OR EXISTS(SELECT 1 FROM tables) '
          'OR EXISTS(SELECT 1 FROM tax_rates) '
          'OR EXISTS(SELECT 1 FROM categories) '
          'OR EXISTS(SELECT 1 FROM expense_categories WHERE is_default = 0) '
          'OR EXISTS(SELECT 1 FROM shifts) AS has_data')
      .getSingle();
  return row.read<int>('has_data') != 0;
}

/// Whether [heldOrders] holds a held ticket (its ticket counter is not
/// one). Reads keys only.
bool hasHeldTickets(Box<dynamic> heldOrders) =>
    heldOrders.keys.any((k) => k != kTicketSeqKey);

/// Last auto-backup failure, or null after a success. Top-level (not a
/// provider) so it survives the container swap done by a restore.
final autoBackupLastError = ValueNotifier<String?>(null);
