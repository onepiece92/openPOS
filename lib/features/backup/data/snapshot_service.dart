import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
import 'dart:typed_data';

// archive's ZLib classes would shadow dart:io's; we use dart:io's chunked
// ZLibCodec directly because archive's own (de)compression buffers whole
// entries in memory.
import 'package:archive/archive.dart' hide ZLibDecoder, ZLibEncoder;
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Full-database snapshot: one `.zip` holding the SQLite file, the Hive
/// preference boxes, the expense receipt photos and a manifest. Pure Dart —
/// no Flutter, no Riverpod — so it is unit-testable against temp
/// directories.
///
/// Zip layout (format 2):
/// * `pos_database.db` — deflated SQLite file
/// * `hive/<box>.hive` — deflated Hive box files
/// * `receipts/<file name>` — stored (JPEG, already compressed) photos
/// * `manifest.json`
/// Format 1 is the same without `receipts/`; it still restores.
///
/// Both directions stream through disk in [chunkSize] pieces, so memory use
/// does not grow with the database size.
///
/// The caller owns lifecycle: [create] expects a self-contained, quiescent
/// DB file (the app produces one with `VACUUM INTO`), and before [restore]
/// both Drift and Hive must be closed. See `snapshot_providers.dart` and
/// `AppRoot.restoreFrom` for the app-side choreography.
class SnapshotService {
  const SnapshotService();

  static const formatVersion = 2;
  static const manifestName = 'manifest.json';
  static const dbEntryName = 'pos_database.db';
  static const hiveDirName = 'hive';
  static const photosDirName = 'receipts';
  static const filePrefix = 'pos_backup_';
  static const fileSuffix = '.zip';

  /// Largest piece of any file held in memory while zipping / unzipping.
  static const chunkSize = 256 * 1024;

  // ── Create ────────────────────────────────────────────────────────────────

  /// Zips [dbFile] + [hiveBoxFiles] (`box name → path`) + every receipt
  /// photo the database references into `outDir/pos_backup_<timestamp>.zip`
  /// and returns it.
  ///
  /// Each deflated entry is compressed chunk by chunk into a scratch file
  /// beside the output, then copied into the zip in chunks.
  ///
  /// Photos come from `expenses.receipt_image_path` in [dbFile] itself (the
  /// consistent `VACUUM INTO` copy) — see [referencedPhotos]. A photo that
  /// can't be found is skipped, never fatal.
  ///
  /// The zip is written under a temp name and renamed into place, so a
  /// failed write never leaves a truncated file that looks like a snapshot.
  Future<File> create({
    required File dbFile,
    required Map<String, String> hiveBoxFiles,
    required Directory outDir,
    required int schemaVersion,
    Directory? receiptsDir,
    DateTime? now,
  }) async {
    if (!await dbFile.exists()) {
      throw StateError('Database file not found: ${dbFile.path}');
    }
    final createdAt = now ?? DateTime.now();
    final photos = referencedPhotos(dbFile, receiptsDir: receiptsDir);

    await outDir.create(recursive: true);
    final out = File(p.join(outDir.path, fileNameFor(createdAt)));
    final tmp = File('${out.path}.part');
    final scratch = File('${out.path}.deflate.part');
    final output = OutputFileStream(tmp.path);
    var closed = false;
    try {
      final encoder = ZipEncoder()..startEncode(output, modified: createdAt);
      _addDeflated(encoder, dbEntryName, dbFile, scratch);

      final boxes = <String>[];
      for (final entry in hiveBoxFiles.entries) {
        final f = File(entry.value);
        if (!f.existsSync()) continue; // box never written — nothing to save
        _addDeflated(encoder, '$hiveDirName/${entry.key}.hive', f, scratch);
        boxes.add(entry.key);
      }

      final photoNames = <String>[];
      for (final photo in photos) {
        final name = p.basename(photo.path);
        if (_addStored(encoder, '$photosDirName/$name', photo)) {
          photoNames.add(name);
        }
      }

      final manifest = SnapshotManifest(
        formatVersion: formatVersion,
        schemaVersion: schemaVersion,
        createdAt: createdAt,
        dbBytes: dbFile.lengthSync(),
        hiveBoxes: boxes,
        photos: photoNames,
      );
      encoder
        ..add(ArchiveFile.string(manifestName, jsonEncode(manifest.toJson())))
        ..endEncode();
      output.closeSync();
      closed = true;
      return await tmp.rename(out.path);
    } catch (_) {
      if (!closed) {
        try {
          output.closeSync();
        } catch (_) {/* already failing */}
      }
      await _deleteIfExists(tmp);
      rethrow;
    } finally {
      await _deleteIfExists(scratch);
    }
  }

  static String fileNameFor(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '$filePrefix${t.year}${two(t.month)}${two(t.day)}_'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}$fileSuffix';
  }

  /// Existing receipt photos referenced by `expenses` in [dbFile], one per
  /// file name. The stored path is absolute and may belong to another
  /// device or an old iOS container, so when it doesn't exist the photo is
  /// looked for as `receiptsDir/<file name>`. Rows whose photo is found
  /// nowhere are skipped.
  static List<File> referencedPhotos(File dbFile, {Directory? receiptsDir}) {
    final db = _openReadOnly(dbFile);
    final List<String> stored;
    try {
      if (!_hasColumn(db, 'expenses', _receiptColumn)) return const [];
      stored = db
          .select('SELECT $_receiptColumn FROM expenses '
              "WHERE $_receiptColumn IS NOT NULL AND $_receiptColumn != ''")
          .map((r) => r.columnAt(0) as String)
          .toList();
    } finally {
      db.dispose();
    }
    final byName = <String, File>{};
    for (final path in stored) {
      final name = _baseName(path);
      if (!_isSafeName(name) || byName.containsKey(name)) continue;
      for (final f in [
        File(path),
        if (receiptsDir != null) File(p.join(receiptsDir.path, name)),
      ]) {
        if (f.existsSync()) {
          byName[name] = f;
          break;
        }
      }
    }
    return byName.values.toList();
  }

  // ── Inspect ───────────────────────────────────────────────────────────────

  /// Reads and validates the manifest without touching the live data.
  /// Throws [SnapshotFormatException] on anything that isn't a POS snapshot.
  ///
  /// Cheap by design: the zip is read through a file stream, only its
  /// central directory is parsed and only `manifest.json` is inflated — the
  /// database entry is never read or CRC-checked here. [restore] does the
  /// full validation. Synchronous file IO: callers on the UI isolate should
  /// wrap it in `Isolate.run` (see `SnapshotCoordinator.inspect`).
  Future<SnapshotManifest> inspect(File zip) async => inspectSync(zip.path);

  /// Synchronous body of [inspect], so it can run inside `Isolate.run`
  /// with only a path captured.
  static SnapshotManifest inspectSync(String zipPath) {
    final input = InputFileStream(zipPath);
    try {
      final archive = _decodeStream(input);
      final manifest = _manifestOf(archive);
      if (archive.find(dbEntryName) == null) {
        throw const SnapshotFormatException('Snapshot has no database file');
      }
      return manifest;
    } finally {
      input.closeSync();
    }
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  /// Replaces [dbFile], the listed Hive box files and (when [receiptsDir]
  /// is given) the backed-up receipt photos with the snapshot's contents.
  ///
  /// Every entry is streamed from the zip to a staged file and its CRC-32
  /// and size checked against the zip directory. Nothing live is touched
  /// until the incoming database has been verified with
  /// [verifyDatabaseFile] (SQLite header, `PRAGMA integrity_check`,
  /// `PRAGMA user_version` in `1..currentSchemaVersion` — the manifest
  /// alone is not trusted). The staged database's receipt paths are then
  /// re-pointed at this device's [receiptsDir] ([repointReceiptPaths]).
  ///
  /// The swap moves the current DB and boxes aside as `*.bak`, and any
  /// photo with the same name into `<receiptsDir>.bak/`, before renaming the
  /// staged files into place. Photos already on the device that the backup
  /// doesn't contain are left alone (a format-1 backup carries none, and
  /// its rows still point at them). If any step of the swap fails, the
  /// moved-aside files are put back and staged files removed before the
  /// error is rethrown.
  ///
  /// The returned [RestoreBackup] lets the caller undo a restore that
  /// succeeded on disk but then failed to open (see [rollback]).
  Future<RestoreBackup> restore({
    required File zip,
    required File dbFile,
    required Map<String, String> hiveBoxFiles,
    required int currentSchemaVersion,
    Directory? receiptsDir,
  }) async {
    final input = InputFileStream(zip.path);
    try {
      return await _restore(
        input: input,
        dbFile: dbFile,
        hiveBoxFiles: hiveBoxFiles,
        currentSchemaVersion: currentSchemaVersion,
        receiptsDir: receiptsDir,
      );
    } finally {
      input.closeSync();
    }
  }

  Future<RestoreBackup> _restore({
    required InputFileStream input,
    required File dbFile,
    required Map<String, String> hiveBoxFiles,
    required int currentSchemaVersion,
    required Directory? receiptsDir,
  }) async {
    final archive = _decodeStream(input);
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
    final dbTmp = File('${dbFile.path}$_tmpSuffix');
    final photoStage = receiptsDir == null
        ? null
        : Directory('${receiptsDir.path}$_tmpSuffix');
    final staged = <FileSystemEntity>[
      dbTmp,
      for (final s in _sidecars) File('${dbTmp.path}$s'),
    ];
    Future<void> discardStaged() async {
      for (final f in staged) {
        if (await f.exists()) await f.delete(recursive: true);
      }
    }

    final hiveTmps = <String, File>{}; // target path → staged file
    final photoNames = <String>[];
    try {
      _extractTo(dbEntry, dbTmp);
      verifyDatabaseFile(dbTmp, currentSchemaVersion: currentSchemaVersion);

      for (final entry in hiveBoxFiles.entries) {
        final f = archive.find('$hiveDirName/${entry.key}.hive');
        if (f == null) continue; // not in the archive — leave the box as-is
        final tmp = File('${entry.value}$_tmpSuffix');
        staged.add(tmp);
        _extractTo(f, tmp);
        hiveTmps[entry.value] = tmp;
      }

      if (receiptsDir != null && photoStage != null) {
        const prefix = '$photosDirName/';
        final photos =
            archive.where((e) => e.isFile && e.name.startsWith(prefix));
        if (photos.isNotEmpty) {
          staged.add(photoStage);
          if (photoStage.existsSync()) photoStage.deleteSync(recursive: true);
          photoStage.createSync(recursive: true);
          for (final e in photos) {
            final name = e.name.substring(prefix.length);
            if (!_isSafeName(name)) {
              throw SnapshotFormatException(
                  'Backup contains an unsafe file name: ${e.name}');
            }
            _extractTo(e, File(p.join(photoStage.path, name)));
            photoNames.add(name);
          }
        }
        repointReceiptPaths(dbTmp, receiptsDir);
      }
    } catch (_) {
      await discardStaged();
      rethrow;
    }

    // 2. Swap: move current files aside, rename staged files into place.
    final backup = RestoreBackup(
      manifest: manifest,
      dbPath: dbFile.path,
      hivePaths: hiveTmps.keys.toList(),
      photoPaths: <String>[], // filled as photos land, for a partial undo
      photoBakDir: photoNames.isEmpty ? null : '${receiptsDir!.path}$_bakSuffix',
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

      if (photoNames.isNotEmpty) {
        final bakDir = Directory(backup.photoBakDir!);
        // The previous restore's photo backup is superseded.
        if (await bakDir.exists()) await bakDir.delete(recursive: true);
        await bakDir.create(recursive: true);
        await receiptsDir!.create(recursive: true);
        for (final name in photoNames) {
          final target = File(p.join(receiptsDir.path, name));
          // Order matters for [rollback]: a listed target either has its
          // original in bakDir or had none.
          if (await target.exists()) {
            await target.rename(p.join(bakDir.path, name));
          }
          backup.photoPaths.add(target.path);
          await File(p.join(photoStage!.path, name)).rename(target.path);
        }
        await photoStage!.delete(recursive: true);
        if (await bakDir.list().isEmpty) await bakDir.delete();
      }
    } catch (_) {
      await discardStaged();
      await rollback(backup);
      rethrow;
    }
    return backup;
  }

  /// Puts back the files [restore] moved aside. Safe after a partial swap:
  /// a target without a `.bak` / `.bak.absent` marker is left alone, and
  /// only photos [restore] actually placed are removed or put back.
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

    final bakDir =
        backup.photoBakDir == null ? null : Directory(backup.photoBakDir!);
    for (final path in backup.photoPaths) {
      await _deleteIfExists(File(path));
      if (bakDir != null) {
        final original = File(p.join(bakDir.path, p.basename(path)));
        if (await original.exists()) await original.rename(path);
      }
    }
    if (bakDir != null && await bakDir.exists()) {
      await bakDir.delete(recursive: true);
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

  /// Rewrites every `expenses.receipt_image_path` in [dbFile] to
  /// `receiptsDir/<file name>`. Stored paths are absolute, so they break
  /// on another device — and on iOS even on the same one, whose container
  /// path changes between installs. Unusable names are cleared. Returns the
  /// number of rows changed. Leaves no `-wal` / `-shm` beside [dbFile].
  static int repointReceiptPaths(File dbFile, Directory receiptsDir) {
    final db = sqlite3.open(dbFile.path);
    var changed = 0;
    try {
      if (!_hasColumn(db, 'expenses', _receiptColumn)) return 0;
      final rows = db.select('SELECT id, $_receiptColumn FROM expenses '
          'WHERE $_receiptColumn IS NOT NULL');
      final update = db.prepare(
          'UPDATE expenses SET $_receiptColumn = ? WHERE id = ?');
      try {
        db.execute('BEGIN');
        for (final r in rows) {
          final old = r.columnAt(1) as String;
          final name = _baseName(old);
          final next =
              _isSafeName(name) ? p.join(receiptsDir.path, name) : null;
          if (next == old) continue;
          update.execute([next, r.columnAt(0)]);
          changed++;
        }
        db.execute('COMMIT');
      } catch (_) {
        if (!db.autocommit) db.execute('ROLLBACK');
        rethrow;
      } finally {
        update.dispose();
      }
      db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
    } finally {
      db.dispose();
    }
    for (final s in _sidecars) {
      final f = File('${dbFile.path}$s');
      if (f.existsSync()) f.deleteSync();
    }
    return changed;
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
      db = _openReadOnly(f);
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

  static const _receiptColumn = 'receipt_image_path';
  static const _tmpSuffix = '.restore.tmp';
  static const _bakSuffix = '.bak';
  static const _absentSuffix = '.bak.absent';
  static const _sidecars = ['-wal', '-shm', '-journal'];
  static const _sqliteHeader = [
    0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, // "SQLite f"
    0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00, // "ormat 3\0"
  ];

  /// Parses only the zip's central directory; entry data stays on disk.
  static Archive _decodeStream(InputStream input) {
    try {
      return ZipDecoder().decodeStream(input);
    } catch (e) {
      throw SnapshotFormatException('Not a valid zip file: $e');
    }
  }

  static SnapshotManifest _manifestOf(Archive archive) {
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

  /// Deflates [src] into [scratch] chunk by chunk, then adds it to the zip
  /// as an already-compressed entry, which the encoder copies in chunks.
  static void _addDeflated(
      ZipEncoder encoder, String name, File src, File scratch) {
    final input = src.openSync();
    final out = scratch.openSync(mode: FileMode.write);
    var crc = 0;
    var size = 0;
    try {
      final deflater = ZLibCodec(raw: true, level: 6)
          .encoder
          .startChunkedConversion(_FileSink(out));
      final buf = Uint8List(chunkSize);
      while (true) {
        final n = input.readIntoSync(buf);
        if (n <= 0) break;
        final chunk = buf.sublist(0, n);
        crc = getCrc32(chunk, crc);
        size += n;
        deflater.add(chunk);
      }
      deflater.close();
      out.flushSync();
    } finally {
      input.closeSync();
      out.closeSync();
    }
    // `add` closes the entry (and so the scratch stream) once written.
    encoder.add(ArchiveFile.file(name, size, _DeflatedFile(scratch.path))
      ..crc32 = crc
      ..compression = CompressionType.deflate);
  }

  /// Adds [src] uncompressed, streamed. False if it can't be opened (e.g.
  /// deleted since it was listed).
  static bool _addStored(ZipEncoder encoder, String name, File src) {
    final InputFileStream stream;
    try {
      stream = InputFileStream(src.path);
    } catch (_) {
      return false;
    }
    encoder.add(
        ArchiveFile.stream(name, stream)..compression = CompressionType.none);
    return true;
  }

  /// Streams [entry] out of the zip into [dst], inflating chunk by chunk,
  /// and checks its CRC-32 and size against the zip directory (archive's
  /// `verify` flag is a no-op in 4.0.x).
  static void _extractTo(ArchiveFile entry, File dst) {
    final zf = entry.rawContent;
    if (zf is! ZipFile) {
      throw SnapshotFormatException('Unreadable backup entry ${entry.name}');
    }
    if (zf.flags & 0x1 != 0) {
      throw const SnapshotFormatException(
          'Encrypted backups are not supported');
    }
    dst.parent.createSync(recursive: true);
    final out = dst.openSync(mode: FileMode.write);
    try {
      final sink = _FileSink(out, limit: zf.uncompressedSize);
      final Sink<List<int>> target = switch (zf.compressionMethod) {
        CompressionType.none => sink,
        CompressionType.deflate =>
          ZLibCodec(raw: true).decoder.startChunkedConversion(sink),
        CompressionType.bzip2 => throw SnapshotFormatException(
            'Unsupported compression in backup entry ${entry.name}'),
      };
      final raw = zf.getStream(decompress: false);
      while (!raw.isEOS) {
        target.add(raw.readBytes(min(chunkSize, raw.length)).toUint8List());
      }
      target.close();
      out.flushSync();
      if (sink.length != zf.uncompressedSize || sink.crc != zf.crc32) {
        throw SnapshotFormatException(
            'Backup entry ${entry.name} is corrupt (checksum mismatch)');
      }
    } on SnapshotFormatException {
      rethrow;
    } catch (e) {
      throw SnapshotFormatException('Backup entry ${entry.name} is corrupt: $e');
    } finally {
      out.closeSync();
    }
  }

  static Database _openReadOnly(File f) {
    // `immutable=1`: the file has no -wal/-shm and nothing else writes it,
    // so SQLite can skip locking and the shared-memory index — a read-only
    // open of a WAL-mode file would otherwise fail (code 14).
    final uri = Uri.file(f.absolute.path).replace(query: 'immutable=1');
    return sqlite3.open(uri.toString(), mode: OpenMode.readOnly, uri: true);
  }

  static bool _hasColumn(Database db, String table, String column) => db
      .select('PRAGMA table_info($table)')
      .any((r) => r['name'] == column);

  /// File name of a stored path from any platform.
  static String _baseName(String path) => path.split(RegExp(r'[/\\]')).last;

  static bool _isSafeName(String name) =>
      name.isNotEmpty &&
      name != '.' &&
      name != '..' &&
      !name.contains('/') &&
      !name.contains(r'\') &&
      !name.contains('\u0000');

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

  static Future<void> _deleteIfExists(File f) async {
    if (await f.exists()) await f.delete();
  }
}

/// Writes chunks straight to a file, counting bytes and the CRC-32. With a
/// [limit], throws as soon as more than [limit] bytes arrive (an entry
/// inflating past its declared size).
class _FileSink implements Sink<List<int>> {
  _FileSink(this._raf, {this.limit});
  final RandomAccessFile _raf;
  final int? limit;
  int length = 0;
  int crc = 0;

  @override
  void add(List<int> chunk) {
    length += chunk.length;
    if (limit != null && length > limit!) {
      throw const SnapshotFormatException(
          'Backup entry is larger than its declared size');
    }
    if (limit != null) crc = getCrc32(chunk, crc);
    _raf.writeFromSync(chunk);
  }

  @override
  void close() {}
}

/// Raw-deflate data in a scratch file, handed to [ZipEncoder] as an entry
/// that is already compressed so it is copied, not re-encoded in memory.
class _DeflatedFile extends FileContent {
  _DeflatedFile(String path) : _stream = InputFileStream(path);
  final InputFileStream _stream;

  @override
  bool get isCompressed => true;

  @override
  int get length => _stream.length;

  @override
  InputStream getStream({bool decompress = true}) {
    if (decompress) throw UnsupportedError('raw deflate data only');
    return _stream;
  }

  @override
  void write(OutputStream output) => output.writeStream(_stream);

  @override
  Future<void> close() => _stream.close();

  @override
  void closeSync() => _stream.closeSync();
}

/// What [SnapshotService.restore] moved aside, so it can be undone.
/// Plain data — safe to return from an isolate.
class RestoreBackup {
  const RestoreBackup({
    required this.manifest,
    required this.dbPath,
    required this.hivePaths,
    this.photoPaths = const [],
    this.photoBakDir,
  });
  final SnapshotManifest manifest;
  final String dbPath;
  final List<String> hivePaths;

  /// Receipt photos the restore placed; [photoBakDir] holds any same-named
  /// originals they replaced.
  final List<String> photoPaths;
  final String? photoBakDir;
}

// ─── Manifest ────────────────────────────────────────────────────────────────

class SnapshotManifest {
  const SnapshotManifest({
    required this.formatVersion,
    required this.schemaVersion,
    required this.createdAt,
    required this.dbBytes,
    required this.hiveBoxes,
    this.photos = const [],
  });

  final int formatVersion;
  final int schemaVersion;
  final DateTime createdAt;
  final int dbBytes;
  final List<String> hiveBoxes;

  /// Receipt photo file names under `receipts/` (format 2+; empty before).
  final List<String> photos;

  Map<String, dynamic> toJson() => {
        'app': 'pos_app',
        'formatVersion': formatVersion,
        'schemaVersion': schemaVersion,
        'createdAt': createdAt.toIso8601String(),
        'dbBytes': dbBytes,
        'hiveBoxes': hiveBoxes,
        'photos': photos,
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
      photos: (j['photos'] as List?)?.cast<String>() ?? const [],
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
