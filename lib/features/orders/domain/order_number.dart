import 'package:pos_app/core/database/app_database.dart';

/// The number a customer sees on a bill: the gap-free invoice number, or the
/// row id for legacy rows written before invoice numbers existed.
extension OrderNumberX on Order {
  int get displayNo => invoiceNo ?? id;

  /// e.g. `#17`
  String get billNo => '#$displayNo';
}
