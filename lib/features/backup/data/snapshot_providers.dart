import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/connection/native.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
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

Future<Directory> autoBackupDir() async {
  final docs = await getApplicationDocumentsDirectory();
  return Directory(p.join(docs.path, 'backups', 'auto'));
}

final snapshotCoordinatorProvider =
    Provider<SnapshotCoordinator>((ref) => SnapshotCoordinator(ref));

/// App-side choreography around [SnapshotService]: checkpoints the live DB,
/// resolves on-device paths, and runs the (CPU-bound) zip off the UI isolate.
/// Restore lives in `AppRoot` because it must tear the container down.
class SnapshotCoordinator {
  SnapshotCoordinator(this._ref);
  final Ref _ref;
  static const _svc = SnapshotService();

  /// Creates a snapshot in [outDir] and returns the zip file.
  Future<File> create(Directory outDir) async {
    final db = _ref.read(databaseProvider);
    // Fold the WAL into the main file so the copy is self-contained.
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    for (final name in kSnapshotHiveBoxes) {
      if (Hive.isBoxOpen(name)) await Hive.box<dynamic>(name).flush();
    }
    final dbPath = (await databaseFile()).path;
    final hiveFiles = snapshotHiveBoxFiles();
    final outPath = outDir.path;
    final now = DateTime.now();
    // Pure-Dart work with only paths captured → safe to run in an isolate.
    return Isolate.run(() => _svc.create(
          dbFile: File(dbPath),
          hiveBoxFiles: hiveFiles,
          outDir: Directory(outPath),
          schemaVersion: AppDatabase.currentSchemaVersion,
          now: now,
        ));
  }

  /// User-initiated "Back up everything": zip to the temp dir and hand the
  /// file to the OS share sheet (Files / Drive / AirDrop / mail…).
  Future<File> createAndShare() async {
    final zip = await create(await getTemporaryDirectory());
    await Share.shareXFiles(
      [XFile(zip.path, mimeType: 'application/zip')],
      subject: p.basename(zip.path),
      text: 'POS full backup',
    );
    return zip;
  }

  Future<SnapshotManifest> inspect(File zip) => _svc.inspect(zip);

  Future<List<File>> localSnapshots() async =>
      _svc.listLocal(await autoBackupDir());

  /// Called once per launch. No-op when disabled or the last snapshot is
  /// younger than [kAutoBackupInterval]. Never throws — backup must not be
  /// able to break app start.
  Future<File?> runAutoBackupIfDue({DateTime? now}) async {
    try {
      final settings = _ref.read(settingsProvider);
      if (!settings.autoBackupEnabled) return null;
      final t = now ?? DateTime.now();
      final last = settings.autoBackupLastAt;
      if (last != null && t.difference(last) < kAutoBackupInterval) return null;

      final dir = await autoBackupDir();
      final zip = await create(dir);
      await _svc.prune(dir, keep: kAutoBackupKeep);
      await _ref.read(settingsProvider.notifier).markAutoBackupRun(t);
      return zip;
    } catch (_) {
      return null;
    }
  }
}
