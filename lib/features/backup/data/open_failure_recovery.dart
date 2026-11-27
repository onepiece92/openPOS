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

const kStartFreshButton = 'Start fresh';
const kStartFreshTitle = 'Start fresh?';
const kStartFreshMessage = 'This creates a new, empty database. The sales '
    'data on this device is gone unless you restore a backup.';
const kStartFreshProgress = 'Starting fresh…';

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
/// the new database — aside as `<name>.broken-<time>` (kept for support,
/// never deleted). Returns the moved main file, or null if there was none.
Future<File?> setAsideDatabaseFile(File db, DateTime now) async {
  final stamp = DateFormat('yyyyMMdd-HHmmss').format(now);
  File? moved;
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    final f = File('${db.path}$suffix');
    if (!await f.exists()) continue;
    final to = await f.rename('${db.path}.broken-$stamp$suffix');
    if (suffix.isEmpty) moved = to;
  }
  return moved;
}
