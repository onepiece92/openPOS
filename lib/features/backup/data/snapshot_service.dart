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

import 'package:pos_app/features/backup/data/restore_journal.dart';

export 'package:pos_app/features/backup/data/restore_journal.dart'
    show PlannedMove;

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
  /// can't be found is skipped, never fatal. With [includePhotos] false
  /// (automatic backups) no photo is read or zipped, and the manifest says
  /// so ([SnapshotManifest.photosIncluded]).
  ///
  /// The zip is written under a temp name and renamed into place, so a
  /// failed write never leaves a truncated file that looks like a snapshot.
  Future<File> create({
    required File dbFile,
    required Map<String, String> hiveBoxFiles,
    required Directory outDir,
    required int schemaVersion,
    Directory? receiptsDir,
    bool includePhotos = true,
    DateTime? now,
    int maxBackupBytes = defaultMaxStagedBytes,
  }) async {
    if (!await dbFile.exists()) {
      throw StateError('Database file not found: ${dbFile.path}');
    }
    final createdAt = now ?? DateTime.now();
    final photos = includePhotos
        ? referencedPhotos(dbFile, receiptsDir: receiptsDir)
        : const <File>[];

    // Refuse what restore would reject, rather than write a dud backup.
    final seen = <String, String>{};
    for (final f in photos) {
      final name = p.basename(f.path);
      final other = seen[name.toLowerCase()];
      if (other != null) {
        throw StateError('Cannot back up receipt photos "$other" and "$name": '
            'their names differ only by letter case.');
      }
      seen[name.toLowerCase()] = name;
    }
    var total = dbFile.lengthSync();
    for (final path in hiveBoxFiles.values) {
      final f = File(path);
      if (f.existsSync()) total += f.lengthSync();
    }
    for (final f in photos) {
      total += f.lengthSync();
    }
    if (total > maxBackupBytes) {
      throw StateError('Data is too large to back up '
          '(${formatBytes(total)}; the limit is '
          '${formatBytes(maxBackupBytes)}).');
    }

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
        photosIncluded: includePhotos,
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

  /// Ceiling on the bytes a restore may stage (and so a backup may hold):
  /// 4 GiB. That is the largest a single (non-zip64) entry can declare, far
  /// above any real POS database plus photos, and bounds the disk a hostile
  /// or broken zip can make us fill.
  static const defaultMaxStagedBytes = 4 * 1024 * 1024 * 1024;

  /// The journal [restore] keeps beside [dbFile] while it swaps files.
  static File journalFileFor(File dbFile) =>
      File('${dbFile.path}$journalSuffix');
  static const journalSuffix = '.restore.journal';

  /// Where an unreadable journal is moved by [recoverInterruptedRestore].
  static const corruptJournalSuffix = '.corrupt';

  /// Replaces [dbFile], the listed Hive box files and (when [receiptsDir]
  /// is given) the backed-up receipt photos with the snapshot's contents.
  ///
  /// Every entry is streamed from the zip to a staged file and its CRC-32
  /// and size checked against the zip directory; the declared sizes must
  /// total at most [maxStagedBytes]. Nothing live is touched until the
  /// incoming database has been verified with [verifyDatabaseFile] (SQLite
  /// header, `PRAGMA integrity_check`, `PRAGMA user_version` in
  /// `1..currentSchemaVersion` — the manifest alone is not trusted). The
  /// staged database's receipt paths are then re-pointed at this device's
  /// [receiptsDir] ([repointReceiptPaths]).
  ///
  /// The swap moves the current DB (with its sidecars) and boxes aside as
  /// `*.bak`, and any photo with the same name into `<receiptsDir>.bak/`,
  /// before renaming the staged files into place. The full plan of moves is
  /// flushed to a [RestoreJournal] first, so [recoverInterruptedRestore]
  /// can undo a swap interrupted by a kill or a power cut. Photos already
  /// on the device that the backup doesn't contain are left alone (a
  /// format-1 backup carries none, and its rows still point at them). If
  /// any step of the swap fails, it is undone before the error is rethrown.
  ///
  /// The returned [RestoreBackup] lets the caller [commit] the restore once
  /// it has opened, or [rollback] one that then failed to open.
  ///
  /// [debugPause] is a test hook awaited at named points of the swap; a
  /// future that never completes freezes the disk as a killed process
  /// would leave it.
  Future<RestoreBackup> restore({
    required File zip,
    required File dbFile,
    required Map<String, String> hiveBoxFiles,
    required int currentSchemaVersion,
    Directory? receiptsDir,
    int maxStagedBytes = defaultMaxStagedBytes,
    Future<void> Function(String point)? debugPause,
  }) async {
    // A journal here means an earlier swap never finished (recovery at
    // startup failed or was skipped); finish undoing it before staging.
    await recoverInterruptedRestore(
      dbFile: dbFile,
      hivePaths: hiveBoxFiles.values.toList(),
      receiptsDir: receiptsDir,
    );
    final input = InputFileStream(zip.path);
    try {
      return await _restore(
        input: input,
        dbFile: dbFile,
        hiveBoxFiles: hiveBoxFiles,
        currentSchemaVersion: currentSchemaVersion,
        receiptsDir: receiptsDir,
        maxStagedBytes: maxStagedBytes,
        pause: debugPause ?? (_) async {},
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
    required int maxStagedBytes,
    required Future<void> Function(String point) pause,
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

    // 0. Decide what will be staged and check it fits, before writing.
    final hiveEntries = <String, ArchiveFile>{}; // target path → entry
    for (final e in hiveBoxFiles.entries) {
      final f = archive.find('$hiveDirName/${e.key}.hive');
      if (f != null) hiveEntries[e.value] = f; // absent → leave box as-is
    }
    final photoEntries = <String, ArchiveFile>{}; // file name → entry
    // A backup without photos (format 1, or an automatic one) never
    // touches the receipts folder: the device's own photos stay as they are.
    if (receiptsDir != null && manifest.photosIncluded) {
      const prefix = '$photosDirName/';
      final seen = <String>{};
      for (final e in archive) {
        if (!e.isFile || !e.name.startsWith(prefix)) continue;
        final name = e.name.substring(prefix.length);
        if (!_isSafeName(name)) {
          throw SnapshotFormatException(
              'Backup contains an unsafe file name: ${e.name}');
        }
        // Would overwrite each other on case-insensitive file systems
        // (iOS, macOS, Android shared storage).
        if (!seen.add(name.toLowerCase())) {
          throw SnapshotFormatException(
              'Backup contains clashing photo names: ${e.name}');
        }
        photoEntries[name] = e;
      }
    }
    final declared = [dbEntry, ...hiveEntries.values, ...photoEntries.values]
        .fold<int>(0, (sum, e) => sum + e.size);
    if (declared > maxStagedBytes) {
      throw SnapshotFormatException(
          'Backup is too large to restore (${formatBytes(declared)}; '
          'the limit is ${formatBytes(maxStagedBytes)})');
    }
    final budget = _Budget(maxStagedBytes);

    // 1. Stage every incoming file next to its target and verify the DB.
    //    A failure here leaves the live data untouched.
    final dbTmp = File('${dbFile.path}$_tmpSuffix');
    final photoStage = receiptsDir == null
        ? null
        : Directory('${receiptsDir.path}$_tmpSuffix');
    final staged = <String>[
      dbTmp.path,
      for (final s in _sidecars) '${dbTmp.path}$s',
    ];
    final hiveTmps = <String, File>{}; // target path → staged file
    try {
      _extractTo(dbEntry, dbTmp, budget);
      verifyDatabaseFile(dbTmp, currentSchemaVersion: currentSchemaVersion);

      for (final e in hiveEntries.entries) {
        final tmp = File('${e.key}$_tmpSuffix');
        staged.add(tmp.path);
        _extractTo(e.value, tmp, budget);
        hiveTmps[e.key] = tmp;
      }

      if (receiptsDir != null) {
        if (photoEntries.isNotEmpty) {
          staged.add(photoStage!.path);
          if (photoStage.existsSync()) photoStage.deleteSync(recursive: true);
          photoStage.createSync(recursive: true);
          for (final e in photoEntries.entries) {
            _extractTo(e.value, File(p.join(photoStage.path, e.key)), budget);
          }
        }
        repointReceiptPaths(dbTmp, receiptsDir,
            restoredNames: photoEntries.keys.toSet());
      }
    } catch (_) {
      await _deleteAll(staged);
      rethrow;
    }

    // 2. No journal exists, so nothing an earlier restore moved aside is
    //    still needed: clear it so a stale `.bak` can't pass for this run's.
    //    Except: a `.bak` whose live file is missing may be the only copy
    //    of that data (e.g. a pre-journal restore killed mid-swap) — keep.
    final db = dbFile.path;
    await _deleteAll([
      if (File(db).existsSync()) ...[
        '$db$_bakSuffix',
        for (final s in _sidecars) '$db$_bakSuffix$s',
      ],
      for (final t in [db, ...hiveBoxFiles.values]) '$t$_absentSuffix',
      for (final t in hiveBoxFiles.values)
        if (File(t).existsSync()) '$t$_bakSuffix',
    ]);
    final photoBakDir = receiptsDir == null
        ? null
        : Directory('${receiptsDir.path}$_bakSuffix');
    if (photoBakDir != null && photoBakDir.existsSync()) {
      photoBakDir.deleteSync(recursive: true);
    }

    // 3. Plan every move, from the disk as it is now, and make the plan
    //    durable before the first rename.
    PlannedMove planFor(String target, String bak, List<String> cleanup) =>
        PlannedMove(target,
            bak: File(target).existsSync() ? bak : null, cleanup: cleanup);
    final dbMove = planFor(db, '$db$_bakSuffix', [
      for (final s in _sidecars)
        if (!File('$db$s').existsSync()) s, // grown later = not ours to keep
    ]);
    final sidecarMoves = [
      for (final s in _sidecars)
        if (File('$db$s').existsSync())
          PlannedMove('$db$s', bak: '$db$_bakSuffix$s'),
    ];
    final hiveMoves = {
      for (final t in hiveTmps.keys)
        t: planFor(t, '$t$_bakSuffix', const ['.lock']),
    };
    final photoMoves = {
      for (final name in photoEntries.keys)
        name: planFor(p.join(receiptsDir!.path, name),
            p.join(photoBakDir!.path, name), const []),
    };
    final plan = [
      dbMove,
      ...sidecarMoves,
      ...hiveMoves.values,
      ...photoMoves.values,
    ];
    final journalFile = journalFileFor(dbFile);
    final backup = RestoreBackup(
      manifest: manifest,
      dbPath: db,
      journalPath: journalFile.path,
      staged: List.of(staged),
      plan: plan,
      photoBakDir: photoMoves.isEmpty ? null : photoBakDir!.path,
    );
    try {
      if (photoMoves.isNotEmpty) {
        await photoBakDir!.create(recursive: true);
        await receiptsDir!.create(recursive: true);
      }
      RestoreJournal.begin(journalFile,
          plan: plan, staged: staged, photoBakDir: backup.photoBakDir);
    } catch (_) {
      await _deleteAll([
        ...staged,
        if (backup.photoBakDir != null) backup.photoBakDir!,
        journalFile.path,
      ]);
      rethrow;
    }
    // 4. Swap, in plan order.
    Future<void> aside(PlannedMove m) async {
      if (m.bak != null) await File(m.target).rename(m.bak!);
    }

    try {
      await pause('begun');
      await aside(dbMove);
      await pause('db-moved'); // DB aside, its sidecars not yet
      for (final m in sidecarMoves) {
        await aside(m);
      }
      await pause('db-aside');
      await dbTmp.rename(db);
      await pause('db-placed');

      for (final e in hiveMoves.entries) {
        await aside(e.value);
        await pause('hive-aside');
        await hiveTmps[e.key]!.rename(e.key);
        // Hive keeps a `.lock` beside the box; harmless, but drop it.
        await _deleteIfExists(File('${e.key}.lock'));
        await pause('hive-placed');
      }

      for (final e in photoMoves.entries) {
        await aside(e.value);
        await pause('photo-aside');
        await File(p.join(photoStage!.path, e.key)).rename(e.value.target);
        await pause('photo-placed');
      }
      if (photoMoves.isNotEmpty) await photoStage!.delete(recursive: true);
      await pause('swapped');
    } catch (_) {
      await rollback(backup);
      rethrow;
    }
    return backup;
  }

  /// Undoes [backup]'s swap from its plan and the state of the disk, then
  /// removes its staged files, photo backup and journal. Idempotent; if it
  /// throws, the journal stays for [recoverInterruptedRestore].
  ///
  /// A journal that already reads as committed (a commit line written but
  /// its flush failed, so [commit] threw) or that can't be read is first
  /// rewritten as begin-only. Otherwise a kill during this rollback would
  /// make the next launch "finish the commit" and delete the `.bak` files
  /// this rollback still needs.
  Future<void> rollback(RestoreBackup backup) async {
    final journal = File(backup.journalPath);
    if (journal.existsSync()) {
      bool committed;
      try {
        committed = RestoreJournal.read(journal).committed;
      } on RestoreJournalFormatException {
        committed = true; // can't tell: make it say "roll back" for sure
      }
      if (committed) {
        RestoreJournal.rewriteUncommitted(journal,
            plan: backup.plan,
            staged: backup.staged,
            photoBakDir: backup.photoBakDir);
      }
    }
    await _rollback(
      plan: backup.plan,
      staged: backup.staged,
      photoBakDir: backup.photoBakDir,
      journal: journal,
    );
  }

  /// Accepts a restore whose data has opened: durably marks the journal
  /// committed (throws if it can't — the caller should then [rollback]),
  /// then deletes the `.bak` files and `receipts.bak` this run made.
  /// Cleanup after the mark is best effort; [recoverInterruptedRestore]
  /// finishes it on the next launch.
  Future<void> commit(RestoreBackup backup) async {
    RestoreJournal.markCommitted(File(backup.journalPath));
    await _finishCommitted(
      plan: backup.plan,
      staged: backup.staged,
      photoBakDir: backup.photoBakDir,
      journal: File(backup.journalPath),
    );
  }

  /// Run before the DB or Hive opens; [hivePaths] and [receiptsDir] are the
  /// stores' usual locations.
  ///
  /// * No journal: removes staged leftovers of a restore killed before its
  ///   swap began, and puts back a DB or box that is missing while its
  ///   `.bak` exists (a kill in a pre-journal build, or a power cut that
  ///   lost the journal's directory entry) →
  ///   [RestoreRecovery.missingFilesPutBack] if anything was put back,
  ///   else [RestoreRecovery.none]. A few `exists` checks when there is
  ///   nothing to do.
  /// * Committed journal: finishes the cleanup → `completed`.
  /// * Otherwise every planned move is undone from the disk's state, so
  ///   the app comes back on the data it had before → `rolledBack`.
  /// * Unreadable journal: state-based recovery that prefers each `.bak`
  ///   ([_recoverFromBaks]), journal moved to `*.corrupt` →
  ///   [RestoreRecovery.recoveredWithoutJournal] when a `.bak` was put
  ///   back, [RestoreRecovery.recoveredWithoutJournalUncertain] when there
  ///   was none to put back (the disk may hold either data set).
  ///
  /// Leftovers removed in every case: staged `*.restore.tmp` files and the
  /// journal's own `*.tmp` from an interrupted [RestoreJournal]
  /// rewrite.
  ///
  /// Throws if the disk can't be put right; the journal then stays, so a
  /// retry picks up where this left off.
  static Future<RestoreRecovery> recoverInterruptedRestore({
    required File dbFile,
    List<String> hivePaths = const [],
    Directory? receiptsDir,
  }) async {
    final journal = journalFileFor(dbFile);
    final leftovers = [
      '${dbFile.path}$_tmpSuffix',
      for (final s in _sidecars) '${dbFile.path}$_tmpSuffix$s',
      for (final h in hivePaths) '$h$_tmpSuffix',
      if (receiptsDir != null) '${receiptsDir.path}$_tmpSuffix',
      // RestoreJournal.rewriteUncommitted writes beside the journal first.
      '${journal.path}.tmp',
    ];
    if (!journal.existsSync()) {
      // Only missing files: a live file beside a `.bak` is normal after a
      // pre-journal build's restore (it never deleted its `.bak`s), and
      // the live one holds everything since.
      final changed = await _recoverFromBaks(
          dbFile: dbFile,
          hivePaths: hivePaths,
          receiptsDir: null,
          overLive: false);
      await _deleteAll(leftovers);
      return changed
          ? RestoreRecovery.missingFilesPutBack
          : RestoreRecovery.none;
    }
    final RestoreJournalContents c;
    try {
      c = RestoreJournal.read(journal);
    } on RestoreJournalFormatException {
      // Corrupt or unknown-version journal. A future journal version must
      // never land here: see RestoreJournal.version.
      final changed = await _recoverFromBaks(
          dbFile: dbFile,
          hivePaths: hivePaths,
          receiptsDir: receiptsDir,
          overLive: true);
      await _deleteAll(leftovers);
      await journal.rename('${journal.path}$corruptJournalSuffix');
      return changed
          ? RestoreRecovery.recoveredWithoutJournal
          : RestoreRecovery.recoveredWithoutJournalUncertain;
    }
    // A rewrite killed before its rename: the journal above is the real
    // one, the temp copy is garbage.
    await _deleteIfExists(File('${journal.path}.tmp'));
    if (c.committed) {
      await _finishCommitted(
          plan: c.plan,
          staged: c.staged,
          photoBakDir: c.photoBakDir,
          journal: journal);
      return RestoreRecovery.completed;
    }
    await _rollback(
        plan: c.plan,
        staged: c.staged,
        photoBakDir: c.photoBakDir,
        journal: journal);
    return RestoreRecovery.rolledBack;
  }

  static Future<void> _rollback({
    required List<PlannedMove> plan,
    required List<String> staged,
    required String? photoBakDir,
    required File journal,
  }) async {
    for (final m in plan.reversed) {
      final bak = m.bak;
      if (bak == null) {
        await _deleteIfExists(File(m.target)); // only we could have put it
      } else if (await File(bak).exists()) {
        await _deleteIfExists(File(m.target));
        await File(bak).rename(m.target);
      } // else: the original never moved, or is already back
      // Not ours to keep: e.g. a WAL the restored DB grew must never be
      // replayed onto the original.
      for (final suffix in m.cleanup) {
        await _deleteIfExists(File('${m.target}$suffix'));
      }
    }
    await _deleteAll([...staged, if (photoBakDir != null) photoBakDir]);
    await _deleteIfExists(journal);
  }

  static Future<void> _finishCommitted({
    required List<PlannedMove> plan,
    required List<String> staged,
    required String? photoBakDir,
    required File journal,
  }) async {
    try {
      await _deleteAll([
        for (final m in plan)
          if (m.bak != null) m.bak!,
        ...staged,
        if (photoBakDir != null) photoBakDir,
      ]);
      await _deleteIfExists(journal);
    } catch (_) {/* journal stays committed; next launch retries */}
  }

  /// State-based recovery without a usable journal. Returns whether
  /// anything was put back.
  ///
  /// * The DB and each box get their `.bak` back when the live file is
  ///   missing — and, with [overLive], also when both exist. That is the
  ///   corrupt-journal case: a swap clears stale `.bak`s before writing its
  ///   journal and a commit deletes them before the journal, so a `.bak`
  ///   beside a journal is the pre-restore original of an uncommitted
  ///   restore, and the app never ran on the restored data (the stores
  ///   stay closed while a journal is pending). Preferring it undoes the
  ///   restore whole instead of leaving a mix.
  /// * Sidecars: a `.bak-wal` etc. comes back with its file. A live
  ///   sidecar is deleted only when it belongs to the live file being
  ///   replaced; if the live file is missing, a live sidecar is the
  ///   original's own one that hadn't been moved yet, and is kept.
  /// * Photos in `receipts.bak` (only ever replaced originals) are put
  ///   back when [receiptsDir] is given; photos a restore added beside them
  ///   can't be told apart from the device's own, and stay.
  static Future<bool> _recoverFromBaks({
    required File dbFile,
    required List<String> hivePaths,
    required Directory? receiptsDir,
    required bool overLive,
  }) async {
    var changed = await _putBack(dbFile.path, _sidecars, overLive: overLive);
    for (final h in hivePaths) {
      changed = await _putBack(h, const ['.lock'], overLive: overLive) ||
          changed;
    }
    if (receiptsDir != null) {
      final bakDir = Directory('${receiptsDir.path}$_bakSuffix');
      if (await bakDir.exists()) {
        await receiptsDir.create(recursive: true);
        await for (final f in bakDir.list()) {
          if (f is File) {
            await f.rename(p.join(receiptsDir.path, p.basename(f.path)));
            changed = true;
          }
        }
        await bakDir.delete(recursive: true);
      }
    }
    return changed;
  }

  /// Puts `<target>.bak` (and its `.bak<suffix>` sidecars) back over
  /// [target]; see [_recoverFromBaks] for the sidecar rule.
  static Future<bool> _putBack(String target, List<String> sidecars,
      {required bool overLive}) async {
    final bak = File('$target$_bakSuffix');
    if (!await bak.exists()) return false;
    final liveExists = await File(target).exists();
    if (liveExists && !overLive) return false;
    for (final s in sidecars) {
      final bakSide = File('$target$_bakSuffix$s');
      if (await bakSide.exists() || liveExists) {
        await _deleteIfExists(File('$target$s'));
      }
    }
    await _deleteIfExists(File(target));
    await bak.rename(target);
    for (final s in sidecars) {
      final bakSide = File('$target$_bakSuffix$s');
      if (await bakSide.exists()) await bakSide.rename('$target$s');
    }
    return true;
  }

  /// `4.0 GB`-style size for messages.
  static String formatBytes(int bytes) {
    const units = ['bytes', 'KB', 'MB', 'GB', 'TB'];
    var v = bytes.toDouble();
    var i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    return i == 0 ? '$bytes bytes' : '${v.toStringAsFixed(1)} ${units[i]}';
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
  /// * After a verified reopen the restore is [commit]ted, which removes
  ///   this run's `.bak` files. Failing to mark the commit is treated like a
  ///   failed reopen.
  /// * If reopening the old data fails too, [RestoreFatalException] is
  ///   thrown — the caller must show it, not spin forever.
  /// * The old data is only reopened once [journal] (the swap's journal,
  ///   [journalFileFor]) is gone. If a failed swap or rollback left it
  ///   behind, the disk may hold the backup's data or a mix, and the next
  ///   launch would roll back anything recorded meanwhile — so
  ///   [RestoreFatalException] is thrown instead, and the caller's retry
  ///   must run [recoverInterruptedRestore] before opening anything.
  Future<SnapshotManifest> restoreWithRollback({
    required Future<RestoreBackup> Function() swap,
    required Future<void> Function() reopen,
    required Future<void> Function() release,
    required File journal,
  }) async {
    Future<void> reopenOld(Object cause) async {
      try {
        assertNoPendingRestore(journal);
        await reopen();
      } catch (e2) {
        throw RestoreFatalException(cause: cause, reopenError: e2);
      }
    }

    final RestoreBackup backup;
    try {
      backup = await swap();
    } catch (e) {
      await reopenOld(e);
      rethrow;
    }

    try {
      await reopen(); // the restored data, journal still uncommitted
      await commit(backup);
      return backup.manifest;
    } catch (e) {
      try {
        await release();
      } catch (_) {/* best effort — we are already failing */}
      try {
        await rollback(backup);
      } catch (e2) {
        throw RestoreFatalException(cause: e, reopenError: e2);
      }
      await reopenOld(e);
      throw RestoreRolledBackException(e);
    }
  }

  /// Throws [PendingRestoreException] if [journal] holds a restore that
  /// was neither committed nor undone (an unreadable journal counts).
  /// The stores must not open then: the disk may hold the backup's data
  /// or a mix, and recovery would later discard anything written to it.
  static void assertNoPendingRestore(File journal) {
    if (!journal.existsSync()) return;
    try {
      if (RestoreJournal.read(journal).committed) return;
    } on RestoreJournalFormatException {/* unreadable → pending */}
    throw PendingRestoreException(journal.path);
  }

  /// Re-points `expenses.receipt_image_path` values in [dbFile] at this
  /// device. Stored paths are absolute, so they break on another device —
  /// and on iOS even on the same one, whose container path changes between
  /// installs. Per row:
  /// * no usable file name → cleared (NULL);
  /// * a name in [restoredNames] (photos this restore is placing) →
  ///   `receiptsDir/<name>`;
  /// * a path that still names an existing file here → kept as is;
  /// * otherwise → `receiptsDir/<name>`.
  /// Returns the number of rows changed. Leaves no `-wal` / `-shm` beside
  /// [dbFile].
  static int repointReceiptPaths(File dbFile, Directory receiptsDir,
      {Set<String> restoredNames = const {}}) {
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
          final String? next;
          if (!_isSafeName(name)) {
            next = null; // can never name a photo
          } else if (restoredNames.contains(name)) {
            next = p.join(receiptsDir.path, name); // the copy just restored
          } else if (File(old).existsSync()) {
            next = old; // still resolves on this device: leave it be
          } else {
            next = p.join(receiptsDir.path, name);
          }
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
  static void _extractTo(ArchiveFile entry, File dst, _Budget budget) {
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
      final sink =
          _FileSink(out, limit: zf.uncompressedSize, budget: budget);
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

  static Future<void> _deleteIfExists(File f) async {
    if (await f.exists()) await f.delete();
  }

  /// Deletes each path that exists, file or directory.
  static Future<void> _deleteAll(Iterable<String> paths) async {
    for (final path in paths) {
      final type = await FileSystemEntity.type(path, followLinks: false);
      if (type == FileSystemEntityType.directory) {
        await Directory(path).delete(recursive: true);
      } else if (type != FileSystemEntityType.notFound) {
        await File(path).delete();
      }
    }
  }
}

/// Writes chunks straight to a file, counting bytes and the CRC-32. With a
/// [limit], throws as soon as more than [limit] bytes arrive (an entry
/// inflating past its declared size); with a [budget], as soon as the
/// restore as a whole exceeds it.
class _FileSink implements Sink<List<int>> {
  _FileSink(this._raf, {this.limit, this.budget});
  final RandomAccessFile _raf;
  final int? limit;
  final _Budget? budget;
  int length = 0;
  int crc = 0;

  @override
  void add(List<int> chunk) {
    length += chunk.length;
    if (limit != null && length > limit!) {
      throw const SnapshotFormatException(
          'Backup entry is larger than its declared size');
    }
    budget?.take(chunk.length);
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

/// Shared byte allowance for one restore's staged files.
class _Budget {
  _Budget(this.limit) : remaining = limit;
  final int limit;
  int remaining;

  void take(int n) {
    remaining -= n;
    if (remaining < 0) {
      throw SnapshotFormatException(
          'Backup expands past the '
          '${SnapshotService.formatBytes(limit)} restore limit');
    }
  }
}

/// What [SnapshotService.restore] planned and did, so it can be committed
/// or undone. Mirrors the on-disk journal. Plain data — safe to return
/// from an isolate.
class RestoreBackup {
  const RestoreBackup({
    required this.manifest,
    required this.dbPath,
    required this.journalPath,
    required this.staged,
    required this.plan,
    this.photoBakDir,
  });
  final SnapshotManifest manifest;
  final String dbPath;
  final String journalPath;

  /// Staged files / dirs, deleted on commit or rollback if still there.
  final List<String> staged;

  /// Every file the swap may replace (see [PlannedMove]).
  final List<PlannedMove> plan;

  /// Holds originals of photos the restore replaced.
  final String? photoBakDir;
}

/// What [SnapshotService.recoverInterruptedRestore] found at startup.
enum RestoreRecovery {
  /// No interrupted restore.
  none,

  /// An unfinished restore was undone; the previous data is back.
  rolledBack,

  /// A restore had been accepted; only its cleanup was left to do.
  completed,

  /// The journal was unreadable (or of an unknown version); each `.bak`
  /// was put back over its live file, which normally restores the
  /// previous data. Receipt photos the restore added may remain.
  recoveredWithoutJournal,

  /// The journal was unreadable and there was no `.bak` to put back, so
  /// it is not certain which data the disk holds.
  recoveredWithoutJournalUncertain,

  /// No journal, but the DB or a box was missing while its `.bak` existed
  /// (a kill in a pre-journal build, or a lost journal); the `.bak` was
  /// put back.
  missingFilesPutBack,
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
    bool? photosIncluded,
  }) : photosIncluded = photosIncluded ?? formatVersion >= 2;

  final int formatVersion;
  final int schemaVersion;
  final DateTime createdAt;
  final int dbBytes;
  final List<String> hiveBoxes;

  /// Receipt photo file names under `receipts/` (format 2+; empty before).
  final List<String> photos;

  /// Whether the backup set out to carry receipt photos: false for an
  /// automatic backup (and format 1), so an empty [photos] there means
  /// "not saved", not "there were none". Absent in format-2 manifests
  /// written before this field existed, which always included photos.
  final bool photosIncluded;

  Map<String, dynamic> toJson() => {
        'app': 'pos_app',
        'formatVersion': formatVersion,
        'schemaVersion': schemaVersion,
        'createdAt': createdAt.toIso8601String(),
        'dbBytes': dbBytes,
        'hiveBoxes': hiveBoxes,
        'photos': photos,
        'photosIncluded': photosIncluded,
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
      photosIncluded: j['photosIncluded'] as bool?,
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

/// A restore's journal is still on disk, uncommitted: the stores must stay
/// closed until [SnapshotService.recoverInterruptedRestore] has run.
class PendingRestoreException implements Exception {
  const PendingRestoreException(this.journalPath);
  final String journalPath;
  @override
  String toString() => 'an interrupted restore has not been undone yet';
}
