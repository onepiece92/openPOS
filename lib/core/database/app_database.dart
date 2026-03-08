import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'connection/native.dart' if (dart.library.html) 'connection/web.dart';

import 'daos/audit_dao.dart';
import 'daos/customers_dao.dart';
import 'daos/expenses_dao.dart';
import 'daos/inventory_dao.dart';
import 'daos/orders_dao.dart';
import 'daos/products_dao.dart';
import 'daos/sync_dao.dart';
import 'daos/tax_dao.dart';
import 'tables/audit_log_table.dart';
import 'tables/categories_table.dart';
import 'tables/customers_table.dart';
import 'tables/expense_categories_table.dart';
import 'tables/expenses_table.dart';
import 'tables/order_items_table.dart';
import 'tables/order_tax_override_table.dart';
import 'tables/order_taxes_table.dart';
import 'tables/orders_table.dart';
import 'tables/outbox_queue_table.dart';
import 'tables/product_components_table.dart';
import 'tables/product_modifiers_table.dart';
import 'tables/product_taxes_table.dart';
import 'tables/product_variants_table.dart';
import 'tables/products_table.dart';
import 'tables/returns_table.dart';
import 'tables/stock_adjustments_table.dart';
import 'tables/tax_group_members_table.dart';
import 'tables/tax_groups_table.dart';
import 'tables/tax_rates_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    // Tax
    TaxRates,
    TaxGroups,
    TaxGroupMembers,
    // Catalog
    Categories,
    Products,
    ProductComponents,
    ProductVariants,
    ProductModifiers,
    ProductTaxes,
    // Customers
    Customers,
    // Orders
    Orders,
    OrderItems,
    OrderTaxes,
    OrderTaxOverrides,
    Returns,
    // Expenses
    ExpenseCategories,
    Expenses,
    // Inventory
    StockAdjustments,
    // Audit & Sync
    AuditLog,
    OutboxQueue,
  ],
  daos: [
    ProductsDao,
    OrdersDao,
    CustomersDao,
    InventoryDao,
    TaxDao,
    ExpensesDao,
    AuditDao,
    SyncDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultData();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement(
              'ALTER TABLE customers ADD COLUMN default_discount REAL NOT NULL DEFAULT 0.0',
            );
            await customStatement(
              'ALTER TABLE customers ADD COLUMN default_discount_is_percent INTEGER NOT NULL DEFAULT 0',
            );
          }
          if (from < 3) {
            await customStatement(
              'ALTER TABLE products ADD COLUMN is_composite INTEGER NOT NULL DEFAULT 0',
            );
            await customStatement('''
              CREATE TABLE IF NOT EXISTS product_components (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                composite_product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
                component_product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
                quantity INTEGER NOT NULL DEFAULT 1
              )
            ''');
          }
          if (from < 4) {
            await customStatement(
              'ALTER TABLE products ADD COLUMN is_hidden_in_pos INTEGER NOT NULL DEFAULT 0',
            );
          }
        },
        beforeOpen: (details) async {
          // Enable WAL mode for better concurrent read performance.
          // Enable FK constraints (off by default in SQLite).
          if (!kIsWeb) {
            await customStatement('PRAGMA journal_mode = WAL');
          }
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Seeds essential data on a fresh install.
  /// Wrapped in a check so it's idempotent — safe to call multiple times.
  Future<void> _seedDefaultData() async {
    final existing = await select(expenseCategories).get();
    if (existing.isNotEmpty) return;

    await batch((b) {
      b.insertAll(expenseCategories, [
        ExpenseCategoriesCompanion.insert(
          name: 'Rent',
          color: const Value('#EF4444'),
          isDefault: const Value(true),
        ),
        ExpenseCategoriesCompanion.insert(
          name: 'Utilities',
          color: const Value('#F59E0B'),
          isDefault: const Value(true),
        ),
        ExpenseCategoriesCompanion.insert(
          name: 'Wages',
          color: const Value('#10B981'),
          isDefault: const Value(true),
        ),
        ExpenseCategoriesCompanion.insert(
          name: 'Supplies',
          color: const Value('#6366F1'),
          isDefault: const Value(true),
        ),
        ExpenseCategoriesCompanion.insert(
          name: 'Other',
          color: const Value('#64748B'),
          isDefault: const Value(true),
        ),
      ]);
    });
  }

  static QueryExecutor _openConnection() => openConnection();
}
