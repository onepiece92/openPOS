import 'package:drift/drift.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/tables/expense_categories_table.dart';
import 'package:pos_app/core/database/tables/expenses_table.dart';

part 'expenses_dao.g.dart';

@DriftAccessor(tables: [Expenses, ExpenseCategories])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  Stream<List<Expense>> watchAll() =>
      (select(expenses)
            ..orderBy([(e) => OrderingTerm.desc(e.date)]))
          .watch();

  Stream<List<ExpenseCategory>> watchCategories() =>
      select(expenseCategories).watch();

  Future<int> insert(ExpensesCompanion entry) =>
      into(expenses).insert(entry);

  Future<void> updateExpense(ExpensesCompanion entry) =>
      (update(expenses)..where((e) => e.id.equals(entry.id.value)))
          .write(entry);

  Future<List<Expense>> getAll() => select(expenses).get();

  Future<List<ExpenseCategory>> getAllCategories() => select(expenseCategories).get();

  Future<int> insertCategory(ExpenseCategoriesCompanion entry) =>
      into(expenseCategories).insert(entry);

  Future<int> upsertCategory(ExpenseCategoriesCompanion entry) =>
      into(expenseCategories).insertOnConflictUpdate(entry);

  Future<double> totalForPeriod(DateTime from, DateTime to) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0.0) as total FROM expenses '
      'WHERE date >= ? AND date <= ?',
      variables: [Variable(from), Variable(to)],
    ).getSingle();
    return result.read<double>('total');
  }
}
