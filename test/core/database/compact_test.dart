import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';

void main() {
  test('compact() shrinks the file after a big delete', () async {
    final dir = Directory.systemTemp.createTempSync('pos_compact_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    var db = AppDatabase(NativeDatabase(file));
    await db.customStatement('CREATE TABLE bulk (x BLOB)');
    await db.customStatement('WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL '
        'SELECT i + 1 FROM n WHERE i < 3000) '
        'INSERT INTO bulk SELECT zeroblob(2000) FROM n');
    await db.customStatement('DELETE FROM bulk');
    await db.close();
    final before = file.lengthSync();
    expect(before, greaterThan(1000000), reason: 'the file grew');

    db = AppDatabase(NativeDatabase(file));
    await db.compact();
    await db.close();
    final after = file.lengthSync();

    expect(after, lessThan(before ~/ 4));
  });
}
