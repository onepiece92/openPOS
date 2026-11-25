import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// One file a restore's swap will replace, decided before any file moves.
///
/// * [bak] non-null: [target] existed and will be renamed to [bak] before
///   the staged file takes its place. Rollback: if [bak] exists, it is put
///   back over whatever is at [target]; if not, the original never moved
///   (or is already back) and [target] is left alone.
/// * [bak] null: [target] did not exist, so anything there was placed by
///   the restore and rollback removes it.
/// * [cleanup]: suffixes of files beside [target] the plan does not own
///   (e.g. a `-wal` the restored DB grew); rollback always deletes them.
///
/// Rollback therefore needs only the plan and the state of the disk — no
/// per-step records that a power cut could lose. Plain data — safe to send
/// between isolates.
class PlannedMove {
  const PlannedMove(this.target, {this.bak, this.cleanup = const []});
  final String target;
  final String? bak;
  final List<String> cleanup;
}

/// Thrown by [RestoreJournal.read] for a journal it cannot trust.
class RestoreJournalFormatException implements Exception {
  const RestoreJournalFormatException(this.message);
  final String message;
  @override
  String toString() => 'Unreadable restore journal: $message';
}

/// What a journal file says about the restore that wrote it.
class RestoreJournalContents {
  const RestoreJournalContents({
    required this.plan,
    required this.staged,
    required this.photoBakDir,
    required this.committed,
  });

  final List<PlannedMove> plan;

  /// Staged files / dirs the swap would consume; leftovers are deleted.
  final List<String> staged;
  final String? photoBakDir;

  /// The restored data opened and was accepted; only cleanup remains.
  final bool committed;
}

/// Restore journal: at most two JSON lines, each flushed to storage.
///
/// ```
/// {"op":"begin","v":1,"plan":[{"target":"pos_database.db","bak":"pos_database.db.bak","cleanup":["-shm"]},…],"staged":[…],"photoBakDir":"receipts.bak"}
/// {"op":"commit"}
/// ```
///
/// `begin` is durable before the first file moves, so whatever the swap
/// managed to do before a crash or power cut, recovery knows every file it
/// may have touched. Paths inside the journal's directory are stored
/// relative to it, so a journal still resolves after iOS moves the app
/// container.
class RestoreJournal {
  const RestoreJournal._();

  /// Journal format version.
  ///
  /// IF YOU BUMP THIS: [read] rejects any other version, and the caller
  /// then treats the journal as corrupt and falls back to
  /// prefer-every-`.bak` recovery (`SnapshotService._recoverFromBaks`),
  /// which ignores the plan. A new version must NOT end up there — teach
  /// [read] to parse every version still in the field (older ones at
  /// least; a downgrade can meet a newer one) and keep that fallback for
  /// genuinely unreadable files only.
  static const version = 1;

  /// Writes (truncating) [file] with the `begin` record and flushes it.
  static void begin(
    File file, {
    required List<PlannedMove> plan,
    required List<String> staged,
    String? photoBakDir,
  }) {
    final dir = file.parent.path;
    String rel(String s) => _rel(dir, s);
    final record = {
      'op': 'begin',
      'v': version,
      'plan': [
        for (final m in plan)
          {
            'target': rel(m.target),
            'bak': m.bak == null ? null : rel(m.bak!),
            'cleanup': m.cleanup,
          },
      ],
      'staged': [for (final s in staged) rel(s)],
      'photoBakDir': photoBakDir == null ? null : rel(photoBakDir),
    };
    final raf = file.openSync(mode: FileMode.write);
    try {
      raf.writeStringSync('${jsonEncode(record)}\n');
      raf.flushSync();
    } finally {
      raf.closeSync();
    }
  }

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

  /// Parses [file]. A torn `commit` line (power cut mid-write) reads as
  /// not committed. Anything else unexpected — bad UTF-8, a corrupt or
  /// missing `begin`, an unknown version — throws
  /// [RestoreJournalFormatException]; the caller then falls back to
  /// state-based recovery.
  static RestoreJournalContents read(File file) {
    final List<String> lines;
    try {
      lines = file
          .readAsLinesSync() // strict UTF-8
          .where((l) => l.trim().isNotEmpty)
          .toList();
    } on FileSystemException catch (e) {
      throw RestoreJournalFormatException('${e.message} (${e.osError})');
    }
    if (lines.isEmpty) {
      throw const RestoreJournalFormatException('empty');
    }
    final dir = file.parent.path;
    String abs(Object? s) => _abs(dir, s! as String);
    try {
      final begin = jsonDecode(lines.first) as Map<String, dynamic>;
      if (begin['op'] != 'begin') {
        throw const RestoreJournalFormatException('no begin record');
      }
      // See [version]: a future bump must parse old versions here instead
      // of sending them to the corrupt-journal fallback.
      if (begin['v'] != version) {
        throw RestoreJournalFormatException(
            'unsupported version ${begin['v']}');
      }
      final plan = [
        for (final m in begin['plan'] as List)
          PlannedMove(
            abs((m as Map<String, dynamic>)['target']),
            bak: m['bak'] == null ? null : abs(m['bak']),
            cleanup: (m['cleanup'] as List).cast<String>(),
          ),
      ];
      final staged = [for (final s in begin['staged'] as List) abs(s)];
      final bakDir = begin['photoBakDir'];

      var committed = false;
      for (var i = 1; i < lines.length; i++) {
        Object? r;
        try {
          r = jsonDecode(lines[i]);
        } on FormatException {
          if (i == lines.length - 1) break; // torn tail
          rethrow;
        }
        if (r is Map && r['op'] == 'commit') {
          committed = true;
        } else {
          throw RestoreJournalFormatException('unexpected record ${i + 1}');
        }
      }
      return RestoreJournalContents(
        plan: plan,
        staged: staged,
        photoBakDir: bakDir == null ? null : abs(bakDir),
        committed: committed,
      );
    } on RestoreJournalFormatException {
      rethrow;
    } catch (e) {
      throw RestoreJournalFormatException('$e');
    }
  }

  static String _rel(String dir, String path) =>
      p.isWithin(dir, path) ? p.relative(path, from: dir) : path;

  static String _abs(String dir, String path) =>
      p.isAbsolute(path) ? path : p.join(dir, path);
}
