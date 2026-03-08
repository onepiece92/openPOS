import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/audit_log_table.dart';

part 'audit_dao.g.dart';

@DriftAccessor(tables: [AuditLog])
class AuditDao extends DatabaseAccessor<AppDatabase> with _$AuditDaoMixin {
  AuditDao(super.db);

  // Append-only — no update/delete methods exposed here by design.

  Future<int> log(AuditLogCompanion entry) => into(auditLog).insert(entry);

  Stream<List<AuditLogData>> watchRecent({int limit = 100}) =>
      (select(auditLog)
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
                ? a.entityType.equals(entityType) &
                    a.entityId.equals(entityId)
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
