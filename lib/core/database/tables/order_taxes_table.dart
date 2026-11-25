import 'package:drift/drift.dart';

import 'package:pos_app/core/database/tables/orders_table.dart';
import 'package:pos_app/core/database/tables/tax_rates_table.dart';

/// Per-tax-rate breakdown for an order.
/// Snapshots the rate name and percent so receipts remain accurate
/// even if the tax rate is later edited.
// Tax lines of one order: receipts, order detail, top-products report.
@TableIndex(name: 'idx_order_taxes_order_id', columns: {#orderId})
class OrderTaxes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id)();
  IntColumn get taxRateId => integer().references(TaxRates, #id)();
  TextColumn get taxRateName => text()(); // snapshot
  RealColumn get taxRatePercent => real()(); // snapshot
  RealColumn get taxableAmount => real()();
  RealColumn get taxAmount => real()();
  /// True when the tax was already inside the item prices (so it is not
  /// added to the total). Rows written before schema v14 did not record
  /// this; the migration infers it where the order's totals prove it and
  /// otherwise leaves the default, exclusive.
  BoolColumn get isInclusive =>
      boolean().withDefault(const Constant(false))();
}
