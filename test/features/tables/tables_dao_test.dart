import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';

import '../../_support/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = openInMemoryDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  test('upsert + watchAll returns rows ordered by name', () async {
    await db.tablesDao.upsert(
      TablesCompanion.insert(name: 'T2', capacity: const Value(2)),
    );
    await db.tablesDao.upsert(
      TablesCompanion.insert(name: 'T1', capacity: const Value(4)),
    );
    final rows = await db.tablesDao.getAll();
    expect(rows.map((t) => t.name), ['T1', 'T2']);
    expect(rows.first.capacity, 4);
  });

  test('getById returns the row, deleteById removes it', () async {
    final id = await db.tablesDao.upsert(
      TablesCompanion.insert(name: 'Patio', capacity: const Value(6)),
    );
    final got = await db.tablesDao.getById(id);
    expect(got, isNotNull);
    expect(got!.name, 'Patio');

    final deleted = await db.tablesDao.deleteById(id);
    expect(deleted, 1);
    expect(await db.tablesDao.getById(id), isNull);
  });

  test('upsert with explicit id updates existing row', () async {
    final id = await db.tablesDao.upsert(
      TablesCompanion.insert(name: 'T1', capacity: const Value(2)),
    );
    await db.tablesDao.upsert(
      TablesCompanion(
        id: Value(id),
        name: const Value('T1'),
        capacity: const Value(8),
        updatedAt: Value(DateTime.now()),
      ),
    );
    final updated = await db.tablesDao.getById(id);
    expect(updated!.capacity, 8);
    expect(await db.tablesDao.getAll(), hasLength(1));
  });
}
