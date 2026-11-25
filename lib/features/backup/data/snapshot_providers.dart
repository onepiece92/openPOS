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

/// Names of the Hive boxes that travel with a snapshot. Must match main().
const kSnapshotHiveBoxes = ['settings', 'held_orders'];

/// How many automatic snapshots to keep on-device.
const kAutoBackupKeep = 7;
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
      RestoreRecovery.missingFilesPutBack =>
        'Data left from an interrupted restore was missing and has been '
            'put back. Please check your recent records.',
      RestoreRecovery.none || RestoreRecovery.completed || null => null,
    };

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
    for (final name in kSnapshotHiveBoxes) {
      if (Hive.isBoxOpen(name)) await Hive.box<dynamic>(name).flush();
    }
    final now = DateTime.now();
    // `VACUUM INTO` writes a consistent, self-contained copy through the
    // open connection — unlike copying the live file, it can't catch a
    // half-applied write or miss pages still in the WAL.
    final tmpDir = await getTemporaryDirectory();
    final copy = File(p.join(
        tmpDir.path, 'pos_snapshot_${now.microsecondsSinceEpoch}.db'));
    if (await copy.exists()) await copy.delete();
    final quoted = copy.path.replaceAll("'", "''");
    try {
      await db.customStatement("VACUUM INTO '$quoted'");
      final dbPath = copy.path;
      final hiveFiles = snapshotHiveBoxFiles();
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

      final dir = await autoBackupDir();
      // Owner decision: automatic backups never carry receipt photos.
      final zip = await create(dir, includePhotos: false);
      await _svc.prune(dir, keep: kAutoBackupKeep, protect: zip);
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

/// Last auto-backup failure, or null after a success. Top-level (not a
/// provider) so it survives the container swap done by a restore.
final autoBackupLastError = ValueNotifier<String?>(null);
