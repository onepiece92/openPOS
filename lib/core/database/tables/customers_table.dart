import 'package:drift/drift.dart';

/// Customer profiles linked to orders and loyalty points.
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  IntColumn get loyaltyPoints =>
      integer().withDefault(const Constant(0))();
  RealColumn get defaultDiscount =>
      real().withDefault(const Constant(0.0))();
  BoolColumn get defaultDiscountIsPercent =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isTaxExempt =>
      boolean().withDefault(const Constant(false))();
  TextColumn get taxExemptCertificate =>
      text().nullable()(); // certificate number for audit
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
