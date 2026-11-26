import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'package:pos_app/core/database/connection/native.dart';
import 'package:pos_app/core/database/database_open_errors.dart';
import 'package:pos_app/core/database/upgrade_progress.dart';

import 'package:pos_app/core/database/daos/audit_dao.dart';
import 'package:pos_app/core/database/daos/customers_dao.dart';
import 'package:pos_app/core/database/daos/expenses_dao.dart';
import 'package:pos_app/core/database/daos/inventory_dao.dart';
import 'package:pos_app/core/database/daos/orders_dao.dart';
import 'package:pos_app/core/database/daos/products_dao.dart';
import 'package:pos_app/core/database/daos/shifts_dao.dart';
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
import 'package:pos_app/core/database/tables/product_taxes_table.dart';
import 'package:pos_app/core/database/tables/products_table.dart';
import 'package:pos_app/core/database/tables/returns_table.dart';
import 'package:pos_app/core/database/tables/shifts_table.dart';
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
    // Till sessions (end-of-day drawer close)
    Shifts,
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
    ShiftsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  /// Bump together with a new `onUpgrade` step below.
  static const int currentSchemaVersion = 16;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          // One transaction, so a first launch killed half-way leaves an
          // empty file (user_version 0) that simply runs onCreate again.
          await transaction(() async {
            await m.createAll();
            await _seedDefaultData();
            await customStatement('PRAGMA user_version = $schemaVersion');
          });
        },
        onUpgrade: (m, from, to) async {
          // A database written by a newer app: refuse it instead of letting
          // Drift stamp it with our (lower) version.
          if (from > to) {
            throw DatabaseTooNewError(from, to);
          }
          // Tells the launch surface a migration is running (see
          // databaseUpgradeRunning); cleared however the upgrade ends.
          databaseUpgradeRunning.value = true;
          // Drift (2.28) neither wraps onUpgrade in a transaction nor writes
          // user_version until it returns, so a crash mid-upgrade used to
          // leave half the DDL applied and the old version on disk — every
          // later launch re-ran the step and died on "duplicate column".
          // Now the whole upgrade and the new user_version commit together
          // or not at all. Nothing below needs to run outside a
          // transaction: there is no VACUUM or journal_mode here, and
          // foreign keys are still off at this point (beforeOpen turns them
          // on after the migration), so alterTable's own
          // `PRAGMA foreign_keys = OFF` is skipped and its inner transaction
          // becomes a savepoint.
          await transaction(() async {
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
              await customStatement(
                'CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_invoice_no ON orders (invoice_no)',
              );
              await backfillInvoiceNumbers();
            }
            if (from < 11) {
              // Fiscal-year invoice prefix + physical print counter. The
              // invoice_no unique index becomes composite so each prefix owns
              // its own gap-free sequence.
              await m.addColumn(orders, orders.invoicePrefix);
              await m.addColumn(orders, orders.printCount);
              await customStatement('DROP INDEX IF EXISTS idx_orders_invoice_no');
              await m.createIndex(idxOrdersInvoiceNo);
            }
            if (from < 12) {
              // Variants/modifiers never reached the sale flow (no UI, no
              // writes) — drop them and the always-NULL order_items.variant_id.
              // alterTable recreates order_items from the *current* definition,
              // which already includes the v13 unit columns and the v14 cost
              // column — the transformer fills them since the old table has
              // nothing to copy from.
              // ignore: experimental_member_use
              await m.alterTable(TableMigration(orderItems, columnTransformer: {
                orderItems.unitLabel: const Constant(''),
                orderItems.unitsPerQty: const Constant(1.0),
                orderItems.unitCost: const Constant<double>(null),
              }));
              await customStatement('DROP TABLE IF EXISTS product_variants');
              await customStatement('DROP TABLE IF EXISTS product_modifiers');
            } else {
              // Databases already at v12+ add the later order_items columns
              // one by one — older ones got them in the recreate above.
              if (from < 13) {
                // Secondary-unit selling: snapshot which unit a line was sold
                // in and its main-unit conversion.
                await m.addColumn(orderItems, orderItems.unitLabel);
                await m.addColumn(orderItems, orderItems.unitsPerQty);
              }
              if (from < 14) {
                await m.addColumn(orderItems, orderItems.unitCost);
              }
            }
            if (from < 14) {
              // Cost of goods snapshot per line + whether each tax line was
              // inclusive (so receipts and reports stop guessing).
              await m.addColumn(orderTaxes, orderTaxes.isInclusive);
              await backfillV14();
            }
            if (from < 15) {
              // Secondary indexes so history, reports and per-order lookups
              // stop scanning whole tables as the shop's data grows. Each one
              // is declared with @TableIndex on its table; the query it serves
              // is pinned by test/core/database/query_plan_test.dart.
              await m.createIndex(idxOrdersCreatedAt);
              await m.createIndex(idxOrdersCustomerId);
              await m.createIndex(idxOrderItemsOrderId);
              await m.createIndex(idxOrderTaxesOrderId);
              await m.createIndex(idxReturnsOrderId);
              await m.createIndex(idxAuditLogCreatedAt);
              await m.createIndex(idxStockAdjustmentsProductCreated);
              await m.createIndex(idxExpensesDate);
            }
            if (from < 16) {
              // Tips (kept out of orders.total) and refunded tips, the void
              // time, plus till sessions for the end-of-day drawer close.
              // ADD COLUMN with a constant default (or NULL) only rewrites
              // the schema, not the rows.
              await m.addColumn(orders, orders.tipAmount);
              await m.addColumn(orders, orders.voidedAt);
              // Partial: holds voided orders only (pre-v16 voids have no
              // voided_at), so it is empty after the upgrade.
              await m.createIndex(idxOrdersVoidedAt);
              await m.addColumn(returns, returns.tipAmount);
              await m.createTable(shifts);
              await m.createIndex(idxShiftsClosedAt);
              await m.createIndex(idxShiftsOneOpen);
              // The close sums refunds by the date they were handed out.
              await m.createIndex(idxReturnsCreatedAt);
              // Stock movements traceable to the order that caused them.
              await m.addColumn(stockAdjustments, stockAdjustments.orderId);
              await m.createIndex(idxStockAdjustmentsOrderId);
              // Which orders those rows fully describe (NULL for all
              // existing orders).
              await m.addColumn(orders, orders.stockLinked);
            }
            await customStatement('PRAGMA user_version = $to');
          }).whenComplete(() => databaseUpgradeRunning.value = false);
        },
        beforeOpen: (details) async {
          // Enable WAL mode for better concurrent read performance.
          // Enable FK constraints (off by default in SQLite).
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA foreign_keys = ON');
          // Sorting/grouping scratch space in RAM instead of temp files —
          // measurably faster for the long-range report queries. `synchronous`
          // is deliberately left at its default: a committed sale must
          // survive power loss.
          await customStatement('PRAGMA temp_store = MEMORY');
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

  /// Fills the two v14 columns for rows that predate them. Idempotent; used
  /// by the v14 migration and by tests.
  ///
  /// `order_items.unit_cost`: the cost at the time of sale was never stored,
  /// so the product's *current* purchase price is the best estimate there is
  /// (for a composite, the sum of its current components). Products with no
  /// purchase price — or a composite with a component that has none — stay
  /// NULL, which reports show as "no cost recorded".
  ///
  /// `order_taxes.is_inclusive`: unknown for old rows, but an order's own
  /// totals settle it when *all* of its tax was inclusive: then the total is
  /// subtotal − discount − loyalty with no tax added. Everything else keeps
  /// the default (exclusive), which is right for all-exclusive orders and a
  /// guess only for an order that mixed both kinds.
  Future<void> backfillV14() => transaction(() async {
        await customStatement(
          'UPDATE order_items SET unit_cost = ('
          '  SELECT CASE WHEN p.purchase_price > 0 THEN p.purchase_price END '
          '  FROM products p '
          '  WHERE p.id = order_items.product_id AND p.is_composite = 0) '
          'WHERE unit_cost IS NULL',
        );
        await customStatement(
          'UPDATE order_items SET unit_cost = ('
          '  SELECT CASE WHEN COUNT(*) > 0 AND MIN(cp.purchase_price) > 0 '
          '    THEN SUM(pc.quantity * cp.purchase_price) END '
          '  FROM product_components pc '
          '  JOIN products cp ON cp.id = pc.component_product_id '
          '  WHERE pc.composite_product_id = order_items.product_id) '
          'WHERE unit_cost IS NULL AND product_id IN '
          '  (SELECT id FROM products WHERE is_composite = 1)',
        );
        await customStatement(
          'UPDATE order_taxes SET is_inclusive = 1 '
          'WHERE is_inclusive = 0 AND order_id IN ('
          '  SELECT id FROM orders WHERE tax_total > 0.005 AND '
          '  ABS(total - (subtotal - discount_total - loyalty_discount)) < 0.005)',
        );
      });

  /// Factory reset: deletes every row, then seeds the same defaults as a
  /// fresh install, in one transaction (all or nothing). Children before
  /// parents so no foreign key is ever left dangling: stock adjustments,
  /// order taxes/overrides/items and returns before orders; orders before
  /// the customers and restaurant tables they point at; product links
  /// before products; categories before tax rates.
  Future<void> eraseAllData() => transaction(() async {
        for (final t in <TableInfo<Table, Object?>>[
          stockAdjustments,
          orderTaxOverrides,
          orderTaxes,
          orderItems,
          returns,
          orders,
          tables,
          expenses,
          productTaxes,
          productComponents,
          products,
          customers,
          categories,
          taxGroupMembers,
          taxGroups,
          taxRates,
          expenseCategories,
          auditLog,
          shifts,
        ]) {
          await delete(t).go();
        }
        await _seedDefaultData();
      });

  /// Rebuilds the database file so space freed by a big delete is given back
  /// (`VACUUM`). For a factory reset only: it rewrites the whole file, so
  /// it is slow on a large database and must not run during normal use.
  /// SQLite refuses `VACUUM` inside a transaction, so call it on its own,
  /// never from within [transaction].
  Future<void> compact() => customStatement('VACUUM');

  /// [eraseAllData], then [compact] so a reset doesn't leave a large file
  /// behind. Shrinking is a bonus: if `VACUUM` fails the erase has already
  /// committed, so the error is logged and the reset carries on.
  Future<void> eraseAllDataAndCompact() async {
    await eraseAllData();
    try {
      await compact();
    } catch (e, st) {
      debugPrint('compact after reset failed: $e\n$st');
    }
  }

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
