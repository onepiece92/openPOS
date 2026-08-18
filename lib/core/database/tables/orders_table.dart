import 'package:drift/drift.dart';

import 'package:pos_app/core/database/tables/customers_table.dart';
import 'package:pos_app/core/database/tables/tables_table.dart';

/// Completed (or held/voided) sales transactions.
///
/// status:         'completed' | 'held' | 'voided' | 'refunded'
/// payment_method: 'cash' | 'card' | 'split' | 'loyalty' | 'wallet'
///
/// invoice_no is a gap-free sequence assigned when a sale is placed; voided
/// and refunded orders keep theirs (they are cancelled, not erased).
@TableIndex(name: 'idx_orders_invoice_no', columns: {#invoiceNo}, unique: true)
class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceNo => integer().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('completed'))();
  RealColumn get subtotal => real()();
  RealColumn get taxTotal =>
      real().withDefault(const Constant(0.0))();
  RealColumn get discountTotal =>
      real().withDefault(const Constant(0.0))();
  /// Order-level discount as entered (e.g. 10 → 10 % or 10 flat), so a
  /// held ticket can be resumed and a receipt can show "10 % off".
  RealColumn get discountValue => real().nullable()();
  BoolColumn get discountIsPercent =>
      boolean().withDefault(const Constant(false))();
  RealColumn get total => real()();
  TextColumn get paymentMethod => text()();
  RealColumn get tenderedAmount =>
      real().nullable()(); // cash tendered
  RealColumn get changeAmount =>
      real().nullable()(); // change due to customer
  IntColumn get customerId =>
      integer().nullable().references(Customers, #id)();
  IntColumn get tableId =>
      integer().nullable().references(Tables, #id)();
  IntColumn get pointsRedeemed =>
      integer().withDefault(const Constant(0))();
  RealColumn get loyaltyDiscount =>
      real().withDefault(const Constant(0.0))();
  IntColumn get pointsEarned =>
      integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
