import 'package:drift/drift.dart';

import 'package:pos_app/core/database/tables/orders_table.dart';
import 'package:pos_app/core/database/tables/tax_rates_table.dart';

/// Per-tax-rate breakdown for an order.
/// Snapshots the rate name and percent so receipts remain accurate
/// even if the tax rate is later edited.
class OrderTaxes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id)();
  IntColumn get taxRateId => integer().references(TaxRates, #id)();
  TextColumn get taxRateName => text()(); // snapshot
  RealColumn get taxRatePercent => real()(); // snapshot
  RealColumn get taxableAmount => real()();
  RealColumn get taxAmount => real()();
}
