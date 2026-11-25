import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// One file move made by a restore's swap, recorded *before* it happens.
///
/// * [RestoreStep.aside]: the live [target] is about to be renamed to [bak].
/// * [RestoreStep.placed]: a staged file is about to be renamed onto
///   [target]. [cleanupSuffixes] name files beside it (`-wal`, `.lock`…)
///   that the restored file may grow and an undo must remove.
///
/// Plain data — safe to send between isolates.
class RestoreStep {
  const RestoreStep.aside(this.target, String this.bak)
      : placed = false,
        cleanupSuffixes = const [];
  const RestoreStep.placed(this.target, {this.cleanupSuffixes = const []})
      : placed = true,
        bak = null;

  final bool placed;
  final String target;
  final String? bak;
  final List<String> cleanupSuffixes;
}

/// What a journal file says about the restore that wrote it.
class RestoreJournalContents {
  const RestoreJournalContents({
    required this.staged,
    required this.photoBakDir,
    required this.steps,
    required this.committed,
  });

  /// Staged files / dirs the swap would consume; leftovers are deleted.
  final List<String> staged;
  final String? photoBakDir;
  final List<RestoreStep> steps;

  /// The restored data opened and was accepted; only cleanup remains.
  final bool committed;
}

/// Append-only restore journal: one JSON object per line.
///
/// ```
/// {"op":"begin","v":1,"staged":[…],"photoBakDir":"receipts.bak"}
/// {"op":"aside","target":"pos_database.db","bak":"pos_database.db.bak"}
/// {"op":"placed","target":"pos_database.db","cleanup":["-wal","-shm","-journal"]}
/// …
/// {"op":"commit"}
/// ```
///
/// Paths inside the journal's directory are stored relative to it, so a
/// journal still resolves after iOS moves the app container.
///
/// `begin` and `commit` are flushed to storage; step records are plain
/// writes, which survive the process being killed (the case this guards
/// against) because they are already in the OS page cache.
class RestoreJournal {
  RestoreJournal._(this.file, this._raf);

  static const version = 1;

  final File file;
  final RandomAccessFile _raf;

  String get _dir => file.parent.path;

  /// Creates (truncating) [file] and durably writes the `begin` record.
  static RestoreJournal begin(
    File file, {
    required List<String> staged,
    String? photoBakDir,
  }) {
    final raf = file.openSync(mode: FileMode.write);
    final j = RestoreJournal._(file, raf);
    try {
      j._write({
        'op': 'begin',
        'v': version,
        'staged': [for (final s in staged) _rel(j._dir, s)],
        'photoBakDir':
            photoBakDir == null ? null : _rel(j._dir, photoBakDir),
      });
      raf.flushSync();
    } catch (_) {
      raf.closeSync();
      rethrow;
    }
    return j;
  }

  void add(RestoreStep s) => _write(s.placed
      ? {
          'op': 'placed',
          'target': _rel(_dir, s.target),
          'cleanup': s.cleanupSuffixes,
        }
      : {
          'op': 'aside',
          'target': _rel(_dir, s.target),
          'bak': _rel(_dir, s.bak!),
        });

  void close() => _raf.closeSync();

  void _write(Map<String, Object?> record) =>
      _raf.writeStringSync('${jsonEncode(record)}\n');

  /// Durably appends the `commit` record.
  static void markCommitted(File file) {
    final raf = file.openSync(mode: FileMode.append);
    try {
      raf.writeStringSync('${jsonEncode({'op': 'commit'})}\n');
      raf.flushSync();
    } finally {
      raf.closeSync();
    }
  }

  /// Parses [file]. A torn last line (killed mid-write) is ignored: that
  /// step's move never started. A journal whose `begin` is missing or torn
  /// has no steps — the swap starts only after `begin` is on disk.
  static RestoreJournalContents read(File file) {
    final dir = file.parent.path;
    final lines = file
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty)
        .toList();
    var staged = <String>[];
    String? photoBakDir;
    final steps = <RestoreStep>[];
    var committed = false;
    for (var i = 0; i < lines.length; i++) {
      final Map<String, dynamic> r;
      try {
        r = jsonDecode(lines[i]) as Map<String, dynamic>;
      } catch (e) {
        if (i == lines.length - 1) break; // torn tail
        throw FormatException('Corrupt restore journal line ${i + 1}: $e');
      }
      String abs(Object? s) => _abs(dir, s as String);
      switch (r['op']) {
        case 'begin':
          staged = [for (final s in r['staged'] as List) abs(s)];
          final bak = r['photoBakDir'];
          photoBakDir = bak == null ? null : abs(bak);
        case 'aside':
          steps.add(RestoreStep.aside(abs(r['target']), abs(r['bak'])));
        case 'placed':
          steps.add(RestoreStep.placed(abs(r['target']),
              cleanupSuffixes: (r['cleanup'] as List).cast<String>()));
        case 'commit':
          committed = true;
      }
    }
    return RestoreJournalContents(
      staged: staged,
      photoBakDir: photoBakDir,
      steps: steps,
      committed: committed,
    );
  }

  static String _rel(String dir, String path) =>
      p.isWithin(dir, path) ? p.relative(path, from: dir) : path;

  static String _abs(String dir, String path) =>
      p.isAbsolute(path) ? path : p.join(dir, path);
}
