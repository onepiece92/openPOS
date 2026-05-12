import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import 'package:pos_app/core/database/app_database.dart';

/// Convenience wrapper for writing to the append-only audit log.
/// Call from DAOs or notifiers after any state-changing operation.
class AuditService {
  const AuditService(this._db);

  final AppDatabase _db;

  Future<void> log({
    required String entityType,
    int? entityId,
    required String action,
    Object? oldValue,
    Object? newValue,
    Map<String, Object?>? metadata,
  }) async {
    await _db.auditDao.log(
      AuditLogCompanion.insert(
        entityType: entityType,
        entityId: Value(entityId),
        action: action,
        oldValue: Value(oldValue != null ? jsonEncode(oldValue) : null),
        newValue: Value(newValue != null ? jsonEncode(newValue) : null),
        metadata: Value(metadata != null ? jsonEncode(metadata) : null),
      ),
    );
  }

  // ── Convenience methods for common audit events ───────────────────────

  Future<void> orderPlaced(
    int orderId, {
    required double total,
    required String paymentMethod,
  }) =>
      log(
        entityType: 'order',
        entityId: orderId,
        action: 'place',
        newValue: {'total': total, 'payment_method': paymentMethod},
      );

  Future<void> orderVoided(int orderId, {String? reason}) => log(
        entityType: 'order',
        entityId: orderId,
        action: 'void',
        metadata: reason != null ? {'reason': reason} : null,
      );

  Future<void> orderRefunded(
    int orderId, {
    required double amount,
    required bool restocked,
    String? reason,
  }) =>
      log(
        entityType: 'order',
        entityId: orderId,
        action: 'refund',
        newValue: {'amount': amount, 'restocked': restocked},
        metadata: reason != null ? {'reason': reason} : null,
      );

  Future<void> taxOverridden({
    required int orderId,
    required double originalTax,
    required double overrideTax,
    required String reason,
  }) =>
      log(
        entityType: 'tax_override',
        entityId: orderId,
        action: 'override',
        oldValue: {'tax': originalTax},
        newValue: {'tax': overrideTax},
        metadata: {'reason': reason, 'pin_verified': true},
      );

  Future<void> settingChanged({
    required String key,
    required Object? oldVal,
    required Object? newVal,
  }) =>
      log(
        entityType: 'setting',
        action: 'update',
        oldValue: {key: oldVal},
        newValue: {key: newVal},
      );
}
