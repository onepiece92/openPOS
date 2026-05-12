import 'package:drift/drift.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/tables/tables_table.dart';

part 'tables_dao.g.dart';

@DriftAccessor(tables: [Tables])
class TablesDao extends DatabaseAccessor<AppDatabase> with _$TablesDaoMixin {
  TablesDao(super.db);

  Stream<List<PosTable>> watchAll() =>
      (select(tables)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Future<List<PosTable>> getAll() =>
      (select(tables)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<PosTable?> getById(int id) =>
      (select(tables)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> upsert(TablesCompanion entry) =>
      into(tables).insertOnConflictUpdate(entry);

  Future<int> deleteById(int id) =>
      (delete(tables)..where((t) => t.id.equals(id))).go();
}
