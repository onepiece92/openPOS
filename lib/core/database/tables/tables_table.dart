import 'package:drift/drift.dart';

/// Restaurant / front-of-house tables.
///
/// `name` is free-form ("T1", "Window 4", "Patio 2") so the staff can label
/// however the venue is laid out. `capacity` is the seat count for that
/// table — informational only; the app does not enforce it against headcount.
///
/// Row class is `PosTable` to avoid clashing with Drift's own `Table` base.
@DataClassName('PosTable')
class Tables extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get capacity => integer().withDefault(const Constant(4))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
