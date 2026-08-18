import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

/// Full-database snapshot: one `.zip` holding the SQLite file, the Hive
/// preference boxes and a manifest. Pure Dart — no Flutter, no Riverpod —
/// so it is unit-testable against temp directories.
///
/// The caller owns lifecycle: before [create] the DB must be checkpointed
/// (WAL → main file), and before [restore] both Drift and Hive must be
/// closed. See `snapshot_providers.dart` for the app-side choreography.
class SnapshotService {
  const SnapshotService();

  static const formatVersion = 1;
  static const manifestName = 'manifest.json';
  static const dbEntryName = 'pos_database.db';
  static const hiveDirName = 'hive';
  static const filePrefix = 'pos_backup_';

  // ── Create ────────────────────────────────────────────────────────────────

  /// Zips [dbFile] + [hiveBoxFiles] (`box name → path`) into
  /// `outDir/pos_backup_<timestamp>.zip` and returns it.
  Future<File> create({
    required File dbFile,
    required Map<String, String> hiveBoxFiles,
    required Directory outDir,
    required int schemaVersion,
    DateTime? now,
  }) async {
    if (!await dbFile.exists()) {
      throw StateError('Database file not found: ${dbFile.path}');
    }
    final createdAt = now ?? DateTime.now();
    final archive = Archive();

    final dbBytes = await dbFile.readAsBytes();
    archive.addFile(ArchiveFile.bytes(dbEntryName, dbBytes));

    final boxes = <String>[];
    for (final entry in hiveBoxFiles.entries) {
      final f = File(entry.value);
      if (!await f.exists()) continue; // box never written — nothing to save
      archive.addFile(
        ArchiveFile.bytes('$hiveDirName/${entry.key}.hive', await f.readAsBytes()),
      );
      boxes.add(entry.key);
    }

    final manifest = SnapshotManifest(
      formatVersion: formatVersion,
      schemaVersion: schemaVersion,
      createdAt: createdAt,
      dbBytes: dbBytes.length,
      hiveBoxes: boxes,
    );
    archive.addFile(
      ArchiveFile.string(manifestName, jsonEncode(manifest.toJson())),
    );

    await outDir.create(recursive: true);
    final out = File(p.join(outDir.path, fileNameFor(createdAt)));
    await out.writeAsBytes(ZipEncoder().encodeBytes(archive), flush: true);
    return out;
  }

  static String fileNameFor(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '$filePrefix${t.year}${two(t.month)}${two(t.day)}_'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}.zip';
  }

  // ── Inspect ───────────────────────────────────────────────────────────────

  /// Reads and validates the manifest without touching the live data.
  /// Throws [SnapshotFormatException] on anything that isn't a POS snapshot.
  Future<SnapshotManifest> inspect(File zip) async {
    final archive = _decode(await zip.readAsBytes());
    final manifest = _manifestOf(archive);
    if (archive.find(dbEntryName) == null) {
      throw const SnapshotFormatException('Snapshot has no database file');
    }
    return manifest;
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  /// Replaces [dbFile] and the listed Hive box files with the snapshot's
  /// contents. Writes go to `*.tmp` first and are renamed into place so a
  /// crash mid-way leaves either the old or the new file, never a torn one.
  ///
  /// [currentSchemaVersion] guards against restoring a *newer* schema than
  /// this build understands (older is fine — Drift migrates on open).
  Future<SnapshotManifest> restore({
    required File zip,
    required File dbFile,
    required Map<String, String> hiveBoxFiles,
    required int currentSchemaVersion,
  }) async {
    final archive = _decode(await zip.readAsBytes());
    final manifest = _manifestOf(archive);
    if (manifest.schemaVersion > currentSchemaVersion) {
      throw SnapshotFormatException(
        'Backup was made by a newer app version '
        '(schema ${manifest.schemaVersion} > $currentSchemaVersion). '
        'Update the app, then restore.',
      );
    }
    final dbEntry = archive.find(dbEntryName);
    if (dbEntry == null) {
      throw const SnapshotFormatException('Snapshot has no database file');
    }

    // Database — plus stale WAL/SHM sidecars, which would otherwise be
    // replayed on top of the restored file.
    await _replace(dbFile, dbEntry.readBytes()!);
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final side = File('${dbFile.path}$suffix');
      if (await side.exists()) await side.delete();
    }

    // Hive boxes — only those present in the archive; others are left as-is.
    for (final entry in hiveBoxFiles.entries) {
      final f = archive.find('$hiveDirName/${entry.key}.hive');
      if (f == null) continue;
      await _replace(File(entry.value), f.readBytes()!);
      // Hive keeps a `.lock` beside the box; harmless, but drop it for hygiene.
      final lock = File('${entry.value}.lock');
      if (await lock.exists()) await lock.delete();
    }
    return manifest;
  }

  // ── Local snapshot housekeeping ───────────────────────────────────────────

  /// Snapshots in [dir], newest first (by file name → timestamp).
  Future<List<File>> listLocal(Directory dir) async {
    if (!await dir.exists()) return const [];
    final files = await dir
        .list()
        .where((e) => e is File && p.basename(e.path).startsWith(filePrefix))
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// Deletes all but the newest [keep] snapshots in [dir].
  Future<int> prune(Directory dir, {required int keep}) async {
    final files = await listLocal(dir);
    var removed = 0;
    for (final f in files.skip(keep)) {
      await f.delete();
      removed++;
    }
    return removed;
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Archive _decode(List<int> bytes) {
    try {
      return ZipDecoder().decodeBytes(bytes, verify: true);
    } catch (e) {
      throw SnapshotFormatException('Not a valid zip file: $e');
    }
  }

  SnapshotManifest _manifestOf(Archive archive) {
    final entry = archive.find(manifestName);
    if (entry == null) {
      throw const SnapshotFormatException(
          'Not a POS backup (manifest.json missing)');
    }
    try {
      final json = jsonDecode(utf8.decode(entry.readBytes()!));
      return SnapshotManifest.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      throw SnapshotFormatException('Corrupt manifest: $e');
    }
  }

  static Future<void> _replace(File target, List<int> bytes) async {
    await target.parent.create(recursive: true);
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(target.path);
  }
}

// ─── Manifest ────────────────────────────────────────────────────────────────

class SnapshotManifest {
  const SnapshotManifest({
    required this.formatVersion,
    required this.schemaVersion,
    required this.createdAt,
    required this.dbBytes,
    required this.hiveBoxes,
  });

  final int formatVersion;
  final int schemaVersion;
  final DateTime createdAt;
  final int dbBytes;
  final List<String> hiveBoxes;

  Map<String, dynamic> toJson() => {
        'app': 'pos_app',
        'formatVersion': formatVersion,
        'schemaVersion': schemaVersion,
        'createdAt': createdAt.toIso8601String(),
        'dbBytes': dbBytes,
        'hiveBoxes': hiveBoxes,
      };

  factory SnapshotManifest.fromJson(Map<String, dynamic> j) {
    if (j['app'] != 'pos_app') {
      throw const SnapshotFormatException('Manifest is not from this app');
    }
    return SnapshotManifest(
      formatVersion: j['formatVersion'] as int,
      schemaVersion: j['schemaVersion'] as int,
      createdAt: DateTime.parse(j['createdAt'] as String),
      dbBytes: j['dbBytes'] as int,
      hiveBoxes: (j['hiveBoxes'] as List).cast<String>(),
    );
  }
}

class SnapshotFormatException implements Exception {
  const SnapshotFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}
