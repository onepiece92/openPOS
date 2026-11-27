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
/// Only the newest set is kept: older `.broken-*` files are deleted once
/// the new set is in place (and a factory reset deletes them all, see
/// [deleteBrokenDatabaseCopies]). Returns the moved main file, or null if
/// there was none.
Future<File?> setAsideDatabaseFile(File db, DateTime now) async {
  final stamp = DateFormat('yyyyMMdd-HHmmss').format(now);
  final prefix = '${db.path}$kBrokenCopyInfix$stamp';
  File? moved;
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    final f = File('${db.path}$suffix');
    if (!await f.exists()) continue;
    final to = await f.rename('$prefix$suffix');
    if (suffix.isEmpty) moved = to;
  }
  // Older copies go only when this call kept something real: a missing or
  // empty main file (e.g. a second Start fresh after the first one's new
  // database never got written) must never cost the only real copy — and
  // no older copy bigger than the one just kept is ever deleted.
  final keptSize = moved == null ? 0 : await moved.length();
  if (keptSize > 0) {
    await deleteBrokenDatabaseCopies(db,
        keepPrefix: prefix, keepLargerThan: keptSize);
  }
  return moved;
}

/// What a set-aside copy's name carries after the database file's name.
const kBrokenCopyInfix = '.broken-';

/// Deletes the set-aside copies of [db] (`<name>.broken-<time>` plus its
/// `-wal`/`-shm`/`-journal`), except the set starting with [keepPrefix] and
/// any set whose main copy is larger than [keepLargerThan] bytes. Returns
/// how many files were deleted.
Future<int> deleteBrokenDatabaseCopies(
  File db, {
  String? keepPrefix,
  int? keepLargerThan,
}) async {
  final dir = db.parent;
  if (!await dir.exists()) return 0;
  final start = '${db.path}$kBrokenCopyInfix';
  // Group each set by its stamp: `<start><yyyyMMdd-HHmmss>[suffix]`.
  final sets = <String, List<File>>{};
  await for (final e in dir.list()) {
    if (e is! File || !e.path.startsWith(start)) continue;
    if (keepPrefix != null && e.path.startsWith(keepPrefix)) continue;
    final rest = e.path.substring(start.length);
    final stamp = rest.length >= 15 ? rest.substring(0, 15) : rest;
    (sets[stamp] ??= []).add(e);
  }
  var deleted = 0;
  for (final entry in sets.entries) {
    if (keepLargerThan != null) {
      final main = File('$start${entry.key}');
      if (await main.exists() && await main.length() > keepLargerThan) {
        continue;
      }
    }
    for (final f in entry.value) {
      await f.delete();
      deleted++;
    }
  }
  return deleted;
}
