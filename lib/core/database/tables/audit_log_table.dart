import 'package:drift/drift.dart';

/// Immutable append-only audit trail.
/// NEVER issue UPDATE or DELETE on this table.
///
/// entity_type: 'order' | 'product' | 'setting' | 'tax_rate' |
///              'expense' | 'stock' | 'customer' | 'tax_override'
/// action:      'create' | 'update' | 'delete' | 'void' | 'refund' | 'override'
/// old_value / new_value: JSON snapshots of the changed record.
/// metadata: JSON bag for extra context (reason, pin_verified, override_amount).
class AuditLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get entityType => text()();
  IntColumn get entityId => integer().nullable()();
  TextColumn get action => text()();
  TextColumn get oldValue => text().nullable()(); // JSON
  TextColumn get newValue => text().nullable()(); // JSON
  TextColumn get metadata => text().nullable()(); // JSON
}
