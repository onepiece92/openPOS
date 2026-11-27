import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Folder inside the TEMPORARY directory (not documents) that holds every file the app
/// hands to the share sheet (full backups, CSV exports, summaries). Each
/// file is deleted once the share returns, and the whole folder is swept
/// at launch and by a factory reset, so no copy of the shop's data lingers
/// in temp.
const kShareTempFolder = 'openpos_share';

/// share_plus's own copies of shared files on Android (inside the
/// temporary directory). Cleared by a factory reset only — at other times
/// an app the file went to may still be reading it.
const kSharePlusTempFolder = 'share_plus';

/// Prefixes of the working files a backup writes straight into the
/// temporary directory (the `VACUUM INTO` copy and the settings copy); a
/// kill can leave them behind.
const kSnapshotTempPrefixes = ['pos_snapshot_', 'settings_snapshot_'];

/// `<temp>/openpos_share`, created if needed.
Future<Directory> shareTempDir({Directory? temp}) async {
  final base = temp ?? await getTemporaryDirectory();
  final dir = Directory(p.join(base.path, kShareTempFolder));
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

/// Deletes [file] after it was shared; never throws.
Future<void> deleteShared(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } on FileSystemException {/* swept at the next launch */}
}

/// Deletes the share folder and the backup working files left in [temp]
/// (only those: nothing else in temp, and never the backups folder, which
/// is not in temp). [sharePlusCache] also deletes share_plus's copies (a
/// factory reset). Never throws.
Future<void> sweepTempLeftovers(Directory temp,
    {bool sharePlusCache = false}) async {
  final dirs = [
    kShareTempFolder,
    if (sharePlusCache) kSharePlusTempFolder,
  ];
  for (final name in dirs) {
    try {
      final d = Directory(p.join(temp.path, name));
      if (await d.exists()) await d.delete(recursive: true);
    } on FileSystemException {/* tried again next time */}
  }
  try {
    if (!await temp.exists()) return;
    await for (final e in temp.list(followLinks: false)) {
      final name = p.basename(e.path);
      if (e is! File) continue;
      if (!kSnapshotTempPrefixes.any(name.startsWith)) continue;
      try {
        await e.delete();
      } on FileSystemException {/* tried again next time */}
    }
  } on FileSystemException {/* no temp folder: nothing to do */}
}

/// [sweepTempLeftovers] on the app's temporary directory; never throws.
Future<void> sweepAppTempLeftovers({bool sharePlusCache = false}) async {
  try {
    await sweepTempLeftovers(await getTemporaryDirectory(),
        sharePlusCache: sharePlusCache);
  } catch (_) {/* no temp folder (tests, desktop quirks) */}
}
