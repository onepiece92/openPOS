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

  test('eraseAllDataAndCompact() erases the shop and shrinks the file',
      () async {
    final dir = Directory.systemTemp.createTempSync('pos_erase_compact_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    var db = AppDatabase(NativeDatabase(file));
    // A big customer table stands in for a shop that has been trading.
    await db.customStatement('WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL '
        'SELECT i + 1 FROM n WHERE i < 4000) '
        "INSERT INTO customers (name, address) SELECT 'c' || i, "
        "hex(zeroblob(400)) FROM n");
    await db.close();
    final before = file.lengthSync();
    expect(before, greaterThan(1000000), reason: 'the file grew');

    db = AppDatabase(NativeDatabase(file));
    await db.eraseAllDataAndCompact();
    final left = await db.customSelect('SELECT COUNT(*) AS n FROM customers')
        .getSingle();
    await db.close();

    expect(left.read<int>('n'), 0);
    expect(file.lengthSync(), lessThan(before ~/ 2));
  });
}
