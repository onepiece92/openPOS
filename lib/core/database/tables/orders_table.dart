import 'package:drift/drift.dart';

import 'customers_table.dart';
import 'tables_table.dart';

/// Completed (or held/voided) sales transactions.
///
/// status:         'completed' | 'held' | 'voided' | 'refunded'
/// payment_method: 'cash' | 'card' | 'split' | 'loyalty' | 'wallet'
class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get status =>
      text().withDefault(const Constant('completed'))();
  RealColumn get subtotal => real()();
  RealColumn get taxTotal =>
      real().withDefault(const Constant(0.0))();
  RealColumn get discountTotal =>
      real().withDefault(const Constant(0.0))();
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
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
