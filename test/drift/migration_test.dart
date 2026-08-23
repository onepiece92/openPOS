import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_common.dart' show ValidationOptions;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';

import 'generated/schema.dart';

/// Upgrades a database created at every schema version that has shipped
/// (v4 · v6 · v7 · v8 · v9) through our hand-written `onUpgrade` steps and
/// asserts the result is byte-for-byte what Drift expects for the current
/// version — tables, columns, types, defaults, indexes.
///
/// To add a version: bump `AppDatabase.currentSchemaVersion`, then
///   dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
///   dart run drift_dev schema generate drift_schemas/ test/drift/generated/
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  const shipped = [4, 6, 7, 8, 9, 10];

  for (final from in shipped) {
    test('upgrade v$from → v${AppDatabase.currentSchemaVersion} yields the expected schema',
        () async {
      final connection = await verifier.startAt(from);
      final db = AppDatabase(connection);
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);
    });
  }

  test('a fresh install (onCreate → createAll) matches what the code expects',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    // Runs createAll, then compares the live SQLite schema against the
    // generated table definitions (with dropped-table checking on).
    await db.validateDatabaseSchema(
      options: const ValidationOptions(validateDropped: true),
    );
  });

  test('data survives v8 → current (invoice numbers back-filled)', () async {
    final schema = await verifier.schemaAt(8);
    // Seed two v8-era orders straight into the raw sqlite3 database.
    schema.rawDatabase.execute(
      "INSERT INTO orders (status, subtotal, total, payment_method, created_at, updated_at) "
      "VALUES ('completed', 5, 5, 'cash', 100, 100), ('completed', 7, 7, 'cash', 200, 200)",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);

    final rows = await db.customSelect(
      'SELECT invoice_no, total FROM orders ORDER BY created_at',
    ).get();
    expect(rows.map((r) => r.read<int?>('invoice_no')), [1, 2]);
    expect(rows.map((r) => r.read<double>('total')), [5, 7]);
  });
}
