import 'package:drift/drift.dart';

import 'tax_rates_table.dart';

/// Hierarchical product categories.
/// parent_id is a self-reference; enforced at the app level, not via FK
/// (Drift self-referencing FKs require careful migration ordering).
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get parentId => integer().nullable()(); // self-ref, app-enforced
  IntColumn get taxRateId =>
      integer().nullable().references(TaxRates, #id)(); // category-level default
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
