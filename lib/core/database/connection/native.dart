import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const kDatabaseFileName = 'pos_database.db';

/// On-disk location of the SQLite database. Shared with the backup feature
/// so snapshot/restore operate on exactly the file Drift opens.
Future<File> databaseFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File(p.join(dir.path, kDatabaseFileName));
}

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final file = await databaseFile();
    return NativeDatabase.createInBackground(file);
  });
}
