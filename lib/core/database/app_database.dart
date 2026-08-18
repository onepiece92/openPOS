import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:pos_app/core/database/connection/native.dart' if (dart.library.html) 'connection/web.dart';

import 'package:pos_app/core/database/daos/audit_dao.dart';
import 'package:pos_app/core/database/daos/customers_dao.dart';
import 'package:pos_app/core/database/daos/expenses_dao.dart';
import 'package:pos_app/core/database/daos/inventory_dao.dart';
import 'package:pos_app/core/database/daos/orders_dao.dart';
import 'package:pos_app/core/database/daos/products_dao.dart';
import 'package:pos_app/core/database/daos/tables_dao.dart';
import 'package:pos_app/core/database/daos/tax_dao.dart';
import 'package:pos_app/core/database/tables/audit_log_table.dart';
import 'package:pos_app/core/database/tables/categories_table.dart';
import 'package:pos_app/core/database/tables/customers_table.dart';
import 'package:pos_app/core/database/tables/expense_categories_table.dart';
import 'package:pos_app/core/database/tables/expenses_table.dart';
import 'package:pos_app/core/database/tables/order_items_table.dart';
import 'package:pos_app/core/database/tables/order_tax_override_table.dart';
import 'package:pos_app/core/database/tables/order_taxes_table.dart';
import 'package:pos_app/core/database/tables/orders_table.dart';
import 'package:pos_app/core/database/tables/product_components_table.dart';
import 'package:pos_app/core/database/tables/product_modifiers_table.dart';
import 'package:pos_app/core/database/tables/product_taxes_table.dart';
import 'package:pos_app/core/database/tables/product_variants_table.dart';
import 'package:pos_app/core/database/tables/products_table.dart';
import 'package:pos_app/core/database/tables/returns_table.dart';
import 'package:pos_app/core/database/tables/stock_adjustments_table.dart';
import 'package:pos_app/core/database/tables/tables_table.dart';
import 'package:pos_app/core/database/tables/tax_group_members_table.dart';
import 'package:pos_app/core/database/tables/tax_groups_table.dart';
import 'package:pos_app/core/database/tables/tax_rates_table.dart';

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
    // Front of House
    Tables,
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
    // Audit
    AuditLog,
  ],
  daos: [
    ProductsDao,
    OrdersDao,
    CustomersDao,
    InventoryDao,
    TaxDao,
    ExpensesDao,
    AuditDao,
    TablesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  /// Bump together with a new `onUpgrade` step below.
  static const int currentSchemaVersion = 10;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultData();
        },
        onUpgrade: (m, from, to) async {
          // Every step uses the Migrator so the DDL is exactly what Drift
          // would generate for a fresh install (NULL / CHECK / DEFAULT text
          // included) — test/drift/migration_test.dart verifies each shipped
          // version upgrades to a schema identical to `createAll()`.
          if (from < 2) {
            await m.addColumn(customers, customers.defaultDiscount);
            await m.addColumn(customers, customers.defaultDiscountIsPercent);
          }
          if (from < 3) {
            await m.addColumn(products, products.isComposite);
            await m.createTable(productComponents);
          }
          if (from < 4) {
            await m.addColumn(products, products.isHiddenInPos);
          }
          if (from < 5) {
            await m.addColumn(products, products.isOutOfStock);
          }
          if (from < 6) {
            // Drop deprecated outbox queue (online sync removed — app is offline-only).
            await customStatement('DROP TABLE IF EXISTS outbox_queue');
          }
          if (from < 7) {
            // Front-of-house tables + nullable FK from orders.
            await m.createTable(tables);
            await m.addColumn(orders, orders.tableId);
          }
          if (from < 8) {
            // Persist loyalty redemption + earn on the order row so receipts
            // can be re-printed and audited without re-deriving from settings.
            await m.addColumn(orders, orders.pointsRedeemed);
            await m.addColumn(orders, orders.loyaltyDiscount);
            await m.addColumn(orders, orders.pointsEarned);
          }
          if (from < 9) {
            // Purchase (cost) price + main/secondary units with conversion.
            await m.addColumn(products, products.purchasePrice);
            await m.addColumn(products, products.unit);
            await m.addColumn(products, products.secondaryUnit);
            await m.addColumn(products, products.conversionRate);
          }
          if (from < 10) {
            // Gap-free invoice numbers + the order discount as entered.
            await m.addColumn(orders, orders.invoiceNo);
            await m.addColumn(orders, orders.discountValue);
            await m.addColumn(orders, orders.discountIsPercent);
            await m.createIndex(idxOrdersInvoiceNo);
            await backfillInvoiceNumbers();
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

  /// Numbers every non-held order that has no invoice_no yet, in
  /// (created_at, id) order, continuing after the highest existing number.
  /// Done row-by-row from Dart: a single UPDATE with a correlated COUNT is
  /// evaluated per row in SQLite and would see its own earlier writes.
  /// Idempotent; used by the v10 migration and by tests.
  Future<void> backfillInvoiceNumbers() => transaction(() async {
        final maxRow = await customSelect(
          'SELECT COALESCE(MAX(invoice_no), 0) AS m FROM orders',
        ).getSingle();
        var next = maxRow.read<int>('m');
        final rows = await customSelect(
          "SELECT id FROM orders WHERE status != 'held' AND invoice_no IS NULL "
          'ORDER BY created_at, id',
        ).get();
        await batch((b) {
          for (final r in rows) {
            next++;
            b.customStatement(
              'UPDATE orders SET invoice_no = ? WHERE id = ?',
              [next, r.read<int>('id')],
            );
          }
        });
      });

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
