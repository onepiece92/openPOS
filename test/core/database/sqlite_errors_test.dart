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

  test("placeOrder's own refusals keep their plain message", () {
    expect(
        saleFailureMessage(ArgumentError.value(
            900, 'tipAmount', 'Tip is too large for this sale (at most 50.00)')),
        'Tip is too large for this sale (at most 50.00)');
  });

  test('other constraint failures are not', () {
    final e = violation('INSERT INTO c (id, p) VALUES (1, NULL)');
    expect(isForeignKeyFailure(e), isFalse);
    expect(saleFailureMessage(e), kSaleFailedMessage);
  });

  test('release sale log: type and short message, no SQL or parameters', () {
    final e = violation("INSERT INTO c (id, p) VALUES (1, 4242)");
    final st = StackTrace.current;

    final release = saleFailureLog(e, st, release: true);
    expect(release, startsWith('Sale failed: SqliteException'));
    expect(release, contains('FOREIGN KEY'));
    expect(release, isNot(contains('INSERT')));
    expect(release, isNot(contains('4242')));
    expect(release, isNot(contains('#0')), reason: 'no stack in release');

    // Any other error: the type only, its text may hold values.
    expect(saleFailureLog(StateError('amount 99.50'), st, release: true),
        'Sale failed: StateError');

    final debug = saleFailureLog(e, st, release: false);
    expect(debug, contains('Sale failed: '));
    expect(debug, contains('#0'));
  });
}
