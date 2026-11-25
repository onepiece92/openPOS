import 'package:drift/drift.dart';

/// One till session, from opening the drawer to the end-of-day close.
///
/// At most one shift is open (closed_at NULL) at a time — enforced by
/// `ShiftsDao.openShift`. The close fields are NULL while the shift is open
/// and are frozen at close, together with [summaryText], so a closed shift
/// reads the same even if later refunds change the underlying orders.
///
/// expected_cash = opening_cash + cash_sales + cash_tips − cash_refunds
///                 − paid_out; counted − expected is the over/short.
// Finding the open shift (closed_at IS NULL) and listing closed ones
// newest first.
@TableIndex(name: 'idx_shifts_closed_at', columns: {#closedAt})
class Shifts extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get openedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get closedAt => dateTime().nullable()();
  RealColumn get openingCash =>
      real().withDefault(const Constant(0.0))();
  RealColumn get cashSales => real().nullable()();
  RealColumn get cashTips => real().nullable()();
  RealColumn get cashRefunds => real().nullable()();
  RealColumn get paidOut => real().nullable()();
  RealColumn get expectedCash => real().nullable()();
  RealColumn get countedCash => real().nullable()();
  /// The plain-text close summary as printed/shared at close time.
  TextColumn get summaryText => text().nullable()();
  TextColumn get notes => text().nullable()();
}
