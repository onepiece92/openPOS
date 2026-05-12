import 'package:drift/drift.dart';

import 'package:pos_app/core/database/tables/expense_categories_table.dart';

/// Business expense records.
///
/// status:              'pending' | 'approved' | 'rejected'
/// recurring_frequency: 'daily' | 'weekly' | 'monthly' (null if not recurring)
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  IntColumn get categoryId =>
      integer().references(ExpenseCategories, #id)();
  TextColumn get notes => text().nullable()();
  TextColumn get receiptImagePath =>
      text().nullable()(); // local file path
  BoolColumn get isRecurring =>
      boolean().withDefault(const Constant(false))();
  TextColumn get recurringFrequency => text().nullable()();
  BoolColumn get isTaxDeductible =>
      boolean().withDefault(const Constant(false))();
  TextColumn get status =>
      text().withDefault(const Constant('approved'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
