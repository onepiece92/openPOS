import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Full-database snapshot: one `.zip` holding the SQLite file, the Hive
/// preference boxes and a manifest. Pure Dart — no Flutter, no Riverpod —
/// so it is unit-testable against temp directories.
///
/// The caller owns lifecycle: [create] expects a self-contained, quiescent
/// DB file (the app produces one with `VACUUM INTO`), and before [restore]
/// both Drift and Hive must be closed. See `snapshot_providers.dart` and
/// `AppRoot.restoreFrom` for the app-side choreography.
class SnapshotService {
  const SnapshotService();

  static const formatVersion = 1;
  static const manifestName = 'manifest.json';
  static const dbEntryName = 'pos_database.db';
  static const hiveDirName = 'hive';
  static const filePrefix = 'pos_backup_';
  static const fileSuffix = '.zip';

  // ── Create ────────────────────────────────────────────────────────────────

  /// Zips [dbFile] + [hiveBoxFiles] (`box name → path`) into
  /// `outDir/pos_backup_<timestamp>.zip` and returns it.
  ///
  /// The zip is written under a temp name and renamed into place, so a
  /// failed write never leaves a truncated file that looks like a snapshot.
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
    final tmp = File('${out.path}.part');
    try {
      await tmp.writeAsBytes(ZipEncoder().encodeBytes(archive), flush: true);
      return await tmp.rename(out.path);
    } catch (_) {
      await _deleteIfExists(tmp);
      rethrow;
    }
  }

  static String fileNameFor(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '$filePrefix${t.year}${two(t.month)}${two(t.day)}_'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}$fileSuffix';
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
  /// contents.
  ///
  /// Nothing live is touched until the incoming database has been written to
  /// a temp file and verified with [verifyDatabaseFile] (SQLite header,
  /// `PRAGMA integrity_check`, `PRAGMA user_version` in
  /// `1..currentSchemaVersion` — the manifest alone is not trusted). The
  /// current files are then moved aside as `*.bak` and the new ones renamed
  /// into place. If any step of the swap fails, the `.bak` files are put
  /// back and temp files removed before the error is rethrown.
  ///
  /// The returned [RestoreBackup] lets the caller undo a restore that
  /// succeeded on disk but then failed to open (see [rollback]).
  Future<RestoreBackup> restore({
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

    // 1. Stage every incoming file next to its target and verify the DB.
    //    A failure here leaves the live data untouched.
    final staged = <File>[];
    Future<void> discardStaged() async {
      for (final f in staged) {
        await _deleteIfExists(f);
      }
    }

    final dbTmp = File('${dbFile.path}$_tmpSuffix');
    final hiveTmps = <String, File>{}; // target path → staged file
    try {
      staged.add(dbTmp);
      await _writeFresh(dbTmp, dbEntry.readBytes()!);
      verifyDatabaseFile(dbTmp, currentSchemaVersion: currentSchemaVersion);

      for (final entry in hiveBoxFiles.entries) {
        final f = archive.find('$hiveDirName/${entry.key}.hive');
        if (f == null) continue; // not in the archive — leave the box as-is
        final tmp = File('${entry.value}$_tmpSuffix');
        staged.add(tmp);
        await _writeFresh(tmp, f.readBytes()!);
        hiveTmps[entry.value] = tmp;
      }
    } catch (_) {
      await discardStaged();
      rethrow;
    }

    // 2. Swap: move current files to `.bak`, rename staged files into place.
    final backup = RestoreBackup(
      manifest: manifest,
      dbPath: dbFile.path,
      hivePaths: hiveTmps.keys.toList(),
    );
    try {
      await _backupDb(dbFile);
      // Stale sidecars must go *before* the new file lands, or SQLite could
      // replay an old WAL on top of it.
      for (final suffix in _sidecars) {
        await _deleteIfExists(File('${dbFile.path}$suffix'));
      }
      await dbTmp.rename(dbFile.path);

      for (final e in hiveTmps.entries) {
        await _moveAside(File(e.key));
        await e.value.rename(e.key);
        // Hive keeps a `.lock` beside the box; harmless, but drop it.
        await _deleteIfExists(File('${e.key}.lock'));
      }
    } catch (_) {
      await discardStaged();
      await rollback(backup);
      rethrow;
    }
    return backup;
  }

  /// Puts back the files [restore] moved aside. Safe after a partial swap:
  /// a target without a `.bak` / `.bak.absent` marker is left alone.
  Future<void> rollback(RestoreBackup backup) async {
    final db = File(backup.dbPath);
    final dbBak = File('${backup.dbPath}$_bakSuffix');
    final dbAbsent = File('${backup.dbPath}$_absentSuffix');
    if (await dbBak.exists() || await dbAbsent.exists()) {
      await _deleteIfExists(db);
      for (final suffix in _sidecars) {
        await _deleteIfExists(File('${backup.dbPath}$suffix'));
      }
      if (await dbBak.exists()) {
        await dbBak.rename(db.path);
        final walBak = File('${dbBak.path}-wal');
        if (await walBak.exists()) await walBak.rename('${db.path}-wal');
      }
      await _deleteIfExists(dbAbsent);
    }
    for (final path in backup.hivePaths) {
      await _restoreAside(File(path));
    }
  }

  /// Full restore choreography with automatic rollback, independent of
  /// Flutter so it can be unit-tested. Assumes both stores are already
  /// closed.
  ///
  /// * [swap] performs the on-disk restore (normally [restore], possibly
  ///   in an isolate). If it throws, nothing changed: [reopen] brings the
  ///   app back on the old data and the swap error is rethrown.
  /// * [reopen] opens the stores and runs a first query. If it throws after
  ///   a successful swap, [release] closes whatever it half-opened, the
  ///   `.bak` files are put back via [rollback], and [reopen] runs again;
  ///   then [RestoreRolledBackException] is thrown.
  /// * If reopening the old data fails too, [RestoreFatalException] is
  ///   thrown — the caller must show it, not spin forever.
  Future<SnapshotManifest> restoreWithRollback({
    required Future<RestoreBackup> Function() swap,
    required Future<void> Function() reopen,
    required Future<void> Function() release,
  }) async {
    final RestoreBackup backup;
    try {
      backup = await swap();
    } catch (e) {
      try {
        await reopen();
      } catch (e2) {
        throw RestoreFatalException(cause: e, reopenError: e2);
      }
      rethrow;
    }

    try {
      await reopen();
      return backup.manifest;
    } catch (e) {
      try {
        await release();
      } catch (_) {/* best effort — we are already failing */}
      try {
        await rollback(backup);
        await reopen();
      } catch (e2) {
        throw RestoreFatalException(cause: e, reopenError: e2);
      }
      throw RestoreRolledBackException(e);
    }
  }

  /// Throws [SnapshotFormatException] unless [f] is an intact SQLite
  /// database whose `user_version` is in `1..currentSchemaVersion`.
  /// Opens the file read-only; never trusts the manifest.
  static void verifyDatabaseFile(File f, {required int currentSchemaVersion}) {
    final raf = f.openSync();
    final List<int> head;
    try {
      head = raf.readSync(_sqliteHeader.length);
    } finally {
      raf.closeSync();
    }
    if (!_startsWith(head, _sqliteHeader)) {
      throw const SnapshotFormatException(
          'Backup database is not a SQLite file');
    }

    final Database db;
    try {
      // `immutable=1`: the staged file has no -wal/-shm and nothing else
      // writes it, so SQLite can skip locking and the shared-memory index —
      // a read-only open of a WAL-mode file would otherwise fail (code 14).
      final uri = Uri.file(f.absolute.path).replace(query: 'immutable=1');
      db = sqlite3.open(uri.toString(), mode: OpenMode.readOnly, uri: true);
    } catch (e) {
      throw SnapshotFormatException('Backup database cannot be opened: $e');
    }
    try {
      final String integrity;
      final int userVersion;
      try {
        integrity = db
            .select('PRAGMA integrity_check')
            .map((r) => '${r.columnAt(0)}')
            .join('; ');
        userVersion =
            (db.select('PRAGMA user_version').first.columnAt(0) as int?) ?? 0;
      } catch (e) {
        throw SnapshotFormatException('Backup database is corrupt: $e');
      }
      if (integrity != 'ok') {
        throw SnapshotFormatException(
            'Backup database failed integrity check: $integrity');
      }
      if (userVersion <= 0) {
        throw const SnapshotFormatException(
            'Backup database has no schema version — not a POS database');
      }
      if (userVersion > currentSchemaVersion) {
        throw SnapshotFormatException(
          'Backup database was made by a newer app version '
          '(schema $userVersion > $currentSchemaVersion). '
          'Update the app, then restore.',
        );
      }
    } finally {
      db.dispose();
    }
  }

  // ── Local snapshot housekeeping ───────────────────────────────────────────

  /// Snapshots in [dir], newest first by modification time (file name as a
  /// tie-break). mtime rather than the name's timestamp so a clock that was
  /// set back can't make a fresh snapshot look old.
  Future<List<File>> listLocal(Directory dir) async {
    if (!await dir.exists()) return const [];
    final files = await dir
        .list()
        .where((e) {
          final name = p.basename(e.path);
          return e is File &&
              name.startsWith(filePrefix) &&
              name.endsWith(fileSuffix);
        })
        .cast<File>()
        .toList();
    final mtimes = {for (final f in files) f.path: await f.lastModified()};
    files.sort((a, b) {
      final byTime = mtimes[b.path]!.compareTo(mtimes[a.path]!);
      return byTime != 0 ? byTime : b.path.compareTo(a.path);
    });
    return files;
  }

  /// Deletes all but the newest [keep] snapshots in [dir]. [protect] (the
  /// snapshot just written) is never deleted, whatever its position.
  Future<int> prune(Directory dir, {required int keep, File? protect}) async {
    var files = await listLocal(dir);
    if (protect != null) {
      final keepPath = p.canonicalize(protect.path);
      final idx = files.indexWhere((f) => p.canonicalize(f.path) == keepPath);
      if (idx > 0) {
        files = [files[idx], ...files.take(idx), ...files.skip(idx + 1)];
      }
    }
    var removed = 0;
    for (final f in files.skip(keep < 1 ? 1 : keep)) {
      await f.delete();
      removed++;
    }
    return removed;
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  static const _tmpSuffix = '.restore.tmp';
  static const _bakSuffix = '.bak';
  static const _absentSuffix = '.bak.absent';
  static const _sidecars = ['-wal', '-shm', '-journal'];
  static const _sqliteHeader = [
    0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, // "SQLite f"
    0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00, // "ormat 3\0"
  ];

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
    final SnapshotManifest manifest;
    try {
      final json = jsonDecode(utf8.decode(entry.readBytes()!));
      manifest = SnapshotManifest.fromJson(json as Map<String, dynamic>);
    } on SnapshotFormatException {
      rethrow;
    } catch (e) {
      throw SnapshotFormatException('Corrupt manifest: $e');
    }
    if (manifest.formatVersion < 1 || manifest.formatVersion > formatVersion) {
      throw SnapshotFormatException(
        'Unsupported backup format ${manifest.formatVersion} '
        '(this app reads format $formatVersion). Update the app, then restore.',
      );
    }
    return manifest;
  }

  static bool _startsWith(List<int> a, List<int> prefix) {
    if (a.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (a[i] != prefix[i]) return false;
    }
    return true;
  }

  /// Moves the live DB (and its WAL, which may hold committed pages) to
  /// `<db>.bak` / `<db>.bak-wal`. The `-shm` index is rebuildable and is
  /// deleted by the caller. A missing DB is recorded with a `.bak.absent`
  /// marker so [rollback] knows to remove the restored file instead.
  static Future<void> _backupDb(File db) async {
    final bak = File('${db.path}$_bakSuffix');
    await _deleteIfExists(bak);
    await _deleteIfExists(File('${bak.path}-wal'));
    await _deleteIfExists(File('${bak.path}-shm'));
    await _deleteIfExists(File('${db.path}$_absentSuffix'));
    if (await db.exists()) {
      await db.rename(bak.path);
      final wal = File('${db.path}-wal');
      if (await wal.exists()) await wal.rename('${bak.path}-wal');
    } else {
      await File('${db.path}$_absentSuffix').create(recursive: true);
    }
  }

  static Future<void> _moveAside(File target) async {
    final bak = File('${target.path}$_bakSuffix');
    final absent = File('${target.path}$_absentSuffix');
    await _deleteIfExists(bak);
    await _deleteIfExists(absent);
    if (await target.exists()) {
      await target.rename(bak.path);
    } else {
      await absent.create(recursive: true);
    }
  }

  static Future<void> _restoreAside(File target) async {
    final bak = File('${target.path}$_bakSuffix');
    final absent = File('${target.path}$_absentSuffix');
    if (await bak.exists()) {
      await _deleteIfExists(target);
      await bak.rename(target.path);
    } else if (await absent.exists()) {
      await _deleteIfExists(target);
    }
    await _deleteIfExists(absent);
    await _deleteIfExists(File('${target.path}.lock'));
  }

  static Future<void> _writeFresh(File f, List<int> bytes) async {
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes, flush: true);
  }

  static Future<void> _deleteIfExists(File f) async {
    if (await f.exists()) await f.delete();
  }
}

/// What [SnapshotService.restore] moved aside, so it can be undone.
/// Plain data — safe to return from an isolate.
class RestoreBackup {
  const RestoreBackup({
    required this.manifest,
    required this.dbPath,
    required this.hivePaths,
  });
  final SnapshotManifest manifest;
  final String dbPath;
  final List<String> hivePaths;
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

/// The backup was written but the app could not open it; the previous data
/// was put back and is running again.
class RestoreRolledBackException implements Exception {
  const RestoreRolledBackException(this.cause);
  final Object cause;
  @override
  String toString() =>
      'The backup could not be opened ($cause). Your previous data was '
      'restored.';
}

/// Neither the backup nor the previous data could be opened. The `.bak`
/// files are still on disk; the app must surface this instead of spinning.
class RestoreFatalException implements Exception {
  const RestoreFatalException({required this.cause, required this.reopenError});
  final Object cause;
  final Object reopenError;
  @override
  String toString() =>
      'Restore failed ($cause) and the app could not reopen its data '
      '($reopenError). Restart the app; if this persists, contact support.';
}
