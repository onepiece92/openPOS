import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import 'package:pos_app/core/database/app_database.dart';

/// Convenience wrapper for writing to the append-only audit log.
/// Call from DAOs or notifiers after any state-changing operation.
/// Metadata field of an `order` / `place` entry that names the held ticket
/// payment it belongs to (see [AuditService.orderPlaced]).
const kSaleKeyField = 'sale_key';

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

  /// [saleKey] is set when the sale was resumed from a held ticket: the
  /// same key is written on the ticket before the sale, so after a kill the
  /// ticket can be matched to this entry (same transaction as the order)
  /// and removed instead of being sold twice. See `HeldOrdersNotifier`.
  Future<void> orderPlaced(
    int orderId, {
    required double total,
    required String paymentMethod,
    double tip = 0,
    String? saleKey,
  }) =>
      log(
        entityType: 'order',
        entityId: orderId,
        action: 'place',
        newValue: {
          'total': total,
          'tip': tip,
          'payment_method': paymentMethod,
        },
        metadata: saleKey == null ? null : {kSaleKeyField: saleKey},
      );

  /// [tip] is the tip that was still with the shop and is handed back.
  Future<void> orderVoided(int orderId, {String? reason, double tip = 0}) =>
      log(
        entityType: 'order',
        entityId: orderId,
        action: 'void',
        newValue: {'tip': tip},
        metadata: reason != null ? {'reason': reason} : null,
      );

  Future<void> orderRefunded(
    int orderId, {
    required double amount,
    required bool restocked,
    String? reason,
    double tip = 0,
  }) =>
      log(
        entityType: 'order',
        entityId: orderId,
        action: 'refund',
        newValue: {'amount': amount, 'tip': tip, 'restocked': restocked},
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
