import 'dart:io';

import 'package:intl/intl.dart';

import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';

/// Self-service ways off the "Open POS couldn't open its data." screen
/// (a missing, empty, corrupt or unopenable database), so a shopkeeper
/// never has to clear the app's data — which on Android also deletes the
/// automatic backups. Nothing here runs without the user choosing it.

const kRestoreLatestBackupButton = 'Restore latest automatic backup';
const kPickBackupTitle = 'Restore which backup?';
const kNoAutoBackups = 'There are no automatic backups on this device.';
const kNewestBackupTag = ' (newest)';

/// A backup picked on that screen could not be restored.
const kBackupRestoreFailedTryAnother =
    "That backup couldn't be restored. Try another one.";

const kStartFreshButton = 'Start fresh';
const kStartFreshTitle = 'Start fresh?';
const kStartFreshMessage = 'This creates a new, empty database. The sales '
    'data on this device is gone unless you restore a backup. The damaged '
    'file is kept on this device for support.';
const kStartFreshProgress = 'Starting fresh…';

/// Start fresh refused: a restore's journal is still on disk.
const kStartFreshRestorePending =
    'A restore is still being finished. Tap Try again first.';

/// Start fresh refused: a pending factory reset could not be cleared first.
const kStartFreshCannotSave = "Open POS couldn't save a change. Free up some "
    'space on this device, then try again.';

/// Start fresh refused: the stores it needs are not open (nothing touched).
const kStartFreshNeedsStores =
    "Open POS can't start fresh right now. Tap Try again first.";
const kStartFreshDoneNotice = 'Started with an empty database. Earlier '
    'sales are gone unless you restore a backup.';

/// The automatic backups in `backups/auto`, newest first, with their
/// dates. Empty when there are none or the folder cannot be read.
Future<List<(File, DateTime)>> listAutoBackups() async {
  try {
    final files =
        await const SnapshotService().listLocal(await autoBackupDir());
    return [for (final f in files) (f, await f.lastModified())];
  } catch (_) {
    return const [];
  }
}

/// How a backup is named in the picker.
String autoBackupLabel(DateTime when, {required bool newest}) =>
    '${DateFormat.yMMMd().add_jm().format(when)}'
    '${newest ? kNewestBackupTag : ''}';

/// "Start fresh": moves the database that would not open — and its `-wal`,
/// `-shm` and `-journal` files, so SQLite never applies a stale journal to
/// the new database — aside as `<name>.broken-<time>`, kept for support.
/// The name is unique: a set-aside in the same second gets `-2`, `-3`…
/// rather than replacing the earlier one. Only the newest set is kept:
/// older `.broken-*` sets are deleted once a real (non-empty) one is in
/// place, never a larger one (and a factory reset deletes them all, see
/// [deleteBrokenDatabaseCopies]). Returns the moved main file, or null if
/// there was none.
Future<File?> setAsideDatabaseFile(File db, DateTime now) async {
  final base = DateFormat('yyyyMMdd-HHmmss').format(now);
  Future<bool> taken(String stamp) async {
    for (final suffix in kBrokenCopySuffixes) {
      if (await File('${db.path}$kBrokenCopyInfix$stamp$suffix').exists()) {
        return true;
      }
    }
    return false;
  }

  var stamp = base;
  for (var n = 2; await taken(stamp); n++) {
    stamp = '$base-$n';
  }
  final prefix = '${db.path}$kBrokenCopyInfix$stamp';
  File? moved;
  for (final suffix in kBrokenCopySuffixes) {
    final f = File('${db.path}$suffix');
    if (!await f.exists()) continue;
    final to = await f.rename('$prefix$suffix');
    if (suffix.isEmpty) moved = to;
  }
  // Older copies go only when this call kept something real: a missing or
  // empty main file (e.g. a second Start fresh after the first one's new
  // database never got written) must never cost the only real copy — and
  // no older copy bigger than the one just kept is ever deleted.
  if (moved != null && await moved.length() > 0) {
    var keptSize = 0;
    for (final suffix in kBrokenCopySuffixes) {
      final f = File('$prefix$suffix');
      if (await f.exists()) keptSize += await f.length();
    }
    await deleteBrokenDatabaseCopies(db,
        keepStamp: stamp, keepLargerThan: keptSize);
  }
  return moved;
}

/// What a set-aside copy's name carries after the database file's name.
const kBrokenCopyInfix = '.broken-';

/// The files of one database set: main, then its journals.
const kBrokenCopySuffixes = ['', '-wal', '-shm', '-journal'];

/// `<yyyyMMdd-HHmmss>[-n][-wal|-shm|-journal]` after [kBrokenCopyInfix].
final _brokenName = RegExp(r'^(\d{8}-\d{6}(?:-\d+)?)(-wal|-shm|-journal)?$');

/// Deletes the set-aside copies of [db] (`<name>.broken-<stamp>` plus its
/// `-wal`/`-shm`/`-journal`), except the set [keepStamp] and any set larger
/// in total (main + journals: a hot WAL can hold most of the data) than
/// [keepLargerThan] bytes. Returns how many files were deleted.
///
/// A journal whose own main copy is missing (a kill split the set while
/// it was being moved) is never deleted: it counts toward the newest set's
/// size, so it can only make that set more likely to be kept.
Future<int> deleteBrokenDatabaseCopies(
  File db, {
  String? keepStamp,
  int? keepLargerThan,
}) async {
  final dir = db.parent;
  if (!await dir.exists()) return 0;
  final start = '${db.path}$kBrokenCopyInfix';
  final sets = <String, List<File>>{};
  final withMain = <String>{};
  await for (final e in dir.list()) {
    if (e is! File || !e.path.startsWith(start)) continue;
    final m = _brokenName.firstMatch(e.path.substring(start.length));
    if (m == null) continue; // not ours: leave it
    final stamp = m.group(1)!;
    (sets[stamp] ??= []).add(e);
    if (m.group(2) == null) withMain.add(stamp);
  }
  Future<int> sizeOf(Iterable<File> files) async {
    var size = 0;
    for (final f in files) {
      size += await f.length();
    }
    return size;
  }

  // Orphan journals join the newest set that still has its main copy.
  final newest =
      withMain.isEmpty ? null : (withMain.toList()..sort(_compareStamps)).last;
  var orphanSize = 0;
  for (final entry in sets.entries) {
    if (!withMain.contains(entry.key)) orphanSize += await sizeOf(entry.value);
  }
  var deleted = 0;
  for (final entry in sets.entries) {
    final stamp = entry.key;
    if (!withMain.contains(stamp) || stamp == keepStamp) continue;
    if (keepLargerThan != null) {
      final size =
          await sizeOf(entry.value) + (stamp == newest ? orphanSize : 0);
      if (size > keepLargerThan) continue;
    }
    for (final f in entry.value) {
      await f.delete();
      deleted++;
    }
  }
  return deleted;
}

/// Orders `yyyyMMdd-HHmmss[-n]` stamps by time, then by n.
int _compareStamps(String a, String b) {
  final ta = a.substring(0, 15), tb = b.substring(0, 15);
  final byTime = ta.compareTo(tb);
  if (byTime != 0) return byTime;
  int n(String s) => s.length > 15 ? int.parse(s.substring(16)) : 1;
  return n(a).compareTo(n(b));
}
