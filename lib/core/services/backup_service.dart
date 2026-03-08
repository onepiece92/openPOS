import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Handles local and cloud backup of the SQLite database file.
/// Cloud upload (Supabase Storage) is triggered when online.
class BackupService {
  const BackupService();

  static const _dbFileName = 'pos_database.sqlite';

  /// Returns the path to the live SQLite database file.
  Future<String> get _dbPath async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _dbFileName);
  }

  /// Copy the DB file to the downloads/documents folder and share it.
  Future<void> exportLocal() async {
    final src = await _dbPath;
    final exportDir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final dest = p.join(exportDir.path, 'pos_backup_$ts.sqlite');
    await File(src).copy(dest);
    await Share.shareXFiles([XFile(dest)], text: 'POS Backup');
  }

  /// Upload the DB snapshot to Supabase Storage.
  /// Caller must check connectivity before calling.
  Future<void> uploadToCloud() async {
    // TODO: implement Supabase Storage upload
    // final file = File(await _dbPath);
    // await supabase.storage.from('backups').upload('pos_backup_${DateTime.now().toIso8601String()}.sqlite', file);
    throw UnimplementedError('Cloud backup not yet implemented');
  }

  /// Download the latest backup from Supabase Storage and replace the local DB.
  /// Shows a confirmation dialog before calling this.
  Future<void> restoreFromCloud() async {
    // TODO: implement Supabase Storage download + restore
    throw UnimplementedError('Cloud restore not yet implemented');
  }
}
