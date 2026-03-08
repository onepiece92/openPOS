import 'package:drift/drift.dart';

/// Predefined and custom expense categories (rent, utilities, wages, etc.).
class ExpenseCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get color =>
      text().withDefault(const Constant('#6366F1'))(); // hex color
  BoolColumn get isDefault =>
      boolean().withDefault(const Constant(false))(); // seeded at install
}
