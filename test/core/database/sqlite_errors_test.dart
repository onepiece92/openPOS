import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import 'package:pos_app/core/database/sqlite_errors.dart';

void main() {
  Object violation(String statement) {
    final db = sql.sqlite3.openInMemory()
      ..execute('PRAGMA foreign_keys = ON')
      ..execute('CREATE TABLE p (id INTEGER PRIMARY KEY)')
      ..execute('CREATE TABLE c (id INTEGER PRIMARY KEY, '
          'p INTEGER NOT NULL REFERENCES p (id))');
    try {
      db.execute(statement);
      fail('no error');
    } catch (e) {
      return e;
    } finally {
      db.dispose();
    }
  }

  test('a real foreign-key failure is recognised (787)', () {
    final e = violation('INSERT INTO c (id, p) VALUES (1, 99)');
    expect(e, isA<sql.SqliteException>());
    expect((e as sql.SqliteException).extendedResultCode,
        kSqliteForeignKeyFailure);
    expect(isForeignKeyFailure(e), isTrue);
    expect(saleFailureMessage(e), kSaleForeignKeyMessage);
  });

  test('other constraint failures are not', () {
    final e = violation('INSERT INTO c (id, p) VALUES (1, NULL)');
    expect(isForeignKeyFailure(e), isFalse);
    expect(saleFailureMessage(e), kSaleFailedMessage);
  });
}
