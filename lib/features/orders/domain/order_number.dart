import 'package:pos_app/core/database/app_database.dart';

/// The number a customer sees on a bill: the gap-free invoice number
/// (scoped by its fiscal-year prefix when one was set at sale time), or the
/// row id for legacy rows written before invoice numbers existed.
extension OrderNumberX on Order {
  int get displayNo => invoiceNo ?? id;

  /// e.g. `#17`, or `2082/83-17` when the order carries a prefix.
  String get billNo =>
      invoicePrefix.isEmpty ? '#$displayNo' : '$invoicePrefix-$displayNo';
}
