import 'package:drift/drift.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/tables/audit_log_table.dart';

part 'audit_dao.g.dart';

@DriftAccessor(tables: [AuditLog])
class AuditDao extends DatabaseAccessor<AppDatabase> with _$AuditDaoMixin {
  AuditDao(super.db);

  // Append-only — no update/delete methods exposed here by design.

  Future<int> log(AuditLogCompanion entry) => into(auditLog).insert(entry);

  /// Whether the till placed order [orderId]: `placeOrder` writes an
  /// `order` / `place` entry in the sale's own transaction; a CSV import
  /// writes none. audit_log has no entity index (no schema change for one),
  /// so this seeks idx_audit_log_created_at within a day either side of the
  /// order's [createdAt] — the entry is written seconds after the order row
  /// — and filters there. The window also keeps an entry of an unrelated
  /// order with the same id from counting.
  Future<bool> hasOrderPlaced(int orderId, DateTime createdAt) async {
    const slack = Duration(days: 1);
    final row = await (select(auditLog)
          ..where((a) =>
              a.createdAt.isBetweenValues(
                  createdAt.subtract(slack), createdAt.add(slack)) &
              a.entityType.equals('order') &
              a.entityId.equals(orderId) &
              a.action.equals('place'))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// Whether an order was placed with held-ticket sale key [saleKey] (see
  /// `AuditService.orderPlaced`), written no earlier than a day before
  /// [since] — the window lets idx_audit_log_created_at do the seeking; the
  /// key itself is random and unique.
  Future<bool> hasSaleKey(String saleKey, DateTime since) async {
    final row = await (select(auditLog)
          ..where((a) =>
              a.createdAt.isBiggerOrEqualValue(
                  since.subtract(const Duration(days: 1))) &
              a.entityType.equals('order') &
              a.action.equals('place') &
              a.metadata.like('%"sale_key":"$saleKey"%'))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  Stream<List<AuditLogData>> watchRecent({int limit = 100}) => (select(auditLog)
        ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
        ..limit(limit))
      .watch();

  Future<List<AuditLogData>> queryByEntity(
    String entityType, {
    int? entityId,
  }) {
    return (select(auditLog)
          ..where(
            (a) => entityId != null
                ? a.entityType.equals(entityType) & a.entityId.equals(entityId)
                : a.entityType.equals(entityType),
          )
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
        .get();
  }

  Future<List<AuditLogData>> queryByDateRange(
    DateTime from,
    DateTime to,
  ) {
    return (select(auditLog)
          ..where(
            (a) =>
                a.createdAt.isBiggerOrEqualValue(from) &
                a.createdAt.isSmallerOrEqualValue(to),
          )
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
        .get();
  }
}
