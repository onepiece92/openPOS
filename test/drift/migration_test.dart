import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_common.dart' show ValidationOptions;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';

import 'generated/schema.dart';

/// Upgrades a database created at every schema version that has shipped
/// (v4 · v6 – v15) through our hand-written `onUpgrade` steps and
/// asserts the result is byte-for-byte what Drift expects for the current
/// version — tables, columns, types, defaults, indexes.
///
/// To add a version: bump `AppDatabase.currentSchemaVersion`, then
///   dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
///   dart run drift_dev schema generate drift_schemas/ test/drift/generated/
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  const shipped = [4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

  for (final from in shipped) {
    test('upgrade v$from → v${AppDatabase.currentSchemaVersion} yields the expected schema',
        () async {
      final connection = await verifier.startAt(from);
      final db = AppDatabase(connection);
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);
    });
  }

  test('a fresh install (onCreate → createAll) matches what the code expects',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    // Runs createAll, then compares the live SQLite schema against the
    // generated table definitions (with dropped-table checking on).
    await db.validateDatabaseSchema(
      options: const ValidationOptions(validateDropped: true),
    );
  });

  test('order_items survive the v12 variant_id column drop', () async {
    final schema = await verifier.schemaAt(11);
    schema.rawDatabase.execute(
      "INSERT INTO products (sku, name, price) VALUES ('X', 'X', 5)",
    );
    schema.rawDatabase.execute(
      "INSERT INTO orders (subtotal, total, payment_method) VALUES (5, 5, 'cash')",
    );
    // A v11-era line item with variant_id still present (and NULL, as always).
    schema.rawDatabase.execute(
      'INSERT INTO order_items (order_id, product_id, variant_id, product_name, unit_price, quantity, line_total) '
      "VALUES (1, 1, NULL, 'Espresso', 5, 2, 10)",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);

    final items = await db.ordersDao.getItems(1);
    expect(items, hasLength(1));
    expect(items.single.productName, 'Espresso');
    expect(items.single.quantity, 2);
    expect(items.single.lineTotal, 10);
  });

  test('data survives v8 → current (invoice numbers back-filled)', () async {
    final schema = await verifier.schemaAt(8);
    // Seed two v8-era orders straight into the raw sqlite3 database.
    schema.rawDatabase.execute(
      "INSERT INTO orders (status, subtotal, total, payment_method, created_at, updated_at) "
      "VALUES ('completed', 5, 5, 'cash', 100, 100), ('completed', 7, 7, 'cash', 200, 200)",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);

    final rows = await db.customSelect(
      'SELECT invoice_no, total FROM orders ORDER BY created_at',
    ).get();
    expect(rows.map((r) => r.read<int?>('invoice_no')), [1, 2]);
    expect(rows.map((r) => r.read<double>('total')), [5, 7]);
  });

  // ── v14: cost snapshot on order lines, inclusive flag on tax lines ───────

  /// Seeds a v13 shop: products with and without a purchase price, a
  /// composite, a fractional secondary unit, and orders of every tax shape.
  void seedV13(void Function(String sql) execute) {
    execute(
      'INSERT INTO products (id, sku, name, price, purchase_price, is_composite, secondary_unit, conversion_rate) VALUES '
      "(1, 'TEA', 'Tea', 100, 80, 0, NULL, 1), "
      "(2, 'NOCOST', 'No cost', 50, 0, 0, NULL, 1), "
      "(3, 'BUNDLE', 'Bundle', 300, 0, 1, NULL, 1), "
      "(4, 'HALF', 'Cake', 40, 10, 0, 'half', 0.5), "
      "(5, 'BUNDLE2', 'Bundle with an uncosted part', 300, 0, 1, NULL, 1)",
    );
    execute(
      'INSERT INTO product_components (composite_product_id, component_product_id, quantity) VALUES '
      '(3, 1, 2), (3, 4, 1), (5, 1, 1), (5, 2, 1)',
    );
    execute(
        "INSERT INTO tax_rates (id, name, rate) VALUES (1, 'VAT', 0.13), (2, 'Levy', 0.05)");
    execute(
      'INSERT INTO orders (id, status, subtotal, discount_total, tax_total, loyalty_discount, total, payment_method, invoice_no) VALUES '
      // 1: exclusive 13 % on 1000 − 100 discount
      "(1, 'completed', 1000, 100, 117, 0, 1017, 'card', 1), "
      // 2: inclusive 13 % on 113 — nothing added to the total
      "(2, 'completed', 113, 0, 13, 0, 113, 'cash', 2), "
      // 3: inclusive 13 % on 113 with 20 of loyalty redeemed
      "(3, 'completed', 113, 0, 13, 20, 93, 'cash', 3), "
      // 4: two exclusive rates on 100
      "(4, 'completed', 100, 0, 18, 0, 118, 'cash', 4), "
      // 5: untaxed
      "(5, 'completed', 50, 0, 0, 0, 50, 'cash', 5), "
      // 6: exclusive 13 % on 100, paid entirely with points → total 0
      "(6, 'completed', 100, 0, 13, 113, 0, 'cash', 6)",
    );
    execute(
      'INSERT INTO order_items (order_id, product_id, product_name, unit_price, quantity, line_total, unit_label, units_per_qty) VALUES '
      "(1, 1, 'Tea', 100, 10, 1000, '', 1), "
      "(2, 4, 'Cake (half)', 113, 1, 113, 'half', 0.5), "
      "(3, 3, 'Bundle', 113, 1, 113, '', 1), "
      "(4, 5, 'Bundle with an uncosted part', 100, 1, 100, '', 1), "
      "(5, 2, 'No cost', 50, 1, 50, '', 1)",
    );
    execute(
      'INSERT INTO order_taxes (order_id, tax_rate_id, tax_rate_name, tax_rate_percent, taxable_amount, tax_amount) VALUES '
      "(1, 1, 'VAT', 0.13, 900, 117), "
      "(2, 1, 'VAT', 0.13, 100, 13), "
      "(3, 1, 'VAT', 0.13, 100, 13), "
      "(4, 1, 'VAT', 0.13, 100, 13), "
      "(4, 2, 'Levy', 0.05, 100, 5), "
      "(6, 1, 'VAT', 0.13, 100, 13)",
    );
  }

  test('v13 → v14 keeps every row and backfills cost and the inclusive flag',
      () async {
    final schema = await verifier.schemaAt(13);
    seedV13(schema.rawDatabase.execute);

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);

    Future<int> count(String table) async => (await db
            .customSelect('SELECT COUNT(*) AS c FROM $table')
            .getSingle())
        .read<int>('c');
    expect(await count('orders'), 6);
    expect(await count('order_items'), 5);
    expect(await count('order_taxes'), 6);
    expect(await count('products'), 5);

    // Untouched: totals, and the fractional conversion rate is not rewritten.
    final totals = await db
        .customSelect('SELECT total FROM orders ORDER BY id')
        .map((r) => r.read<double>('total'))
        .get();
    expect(totals, [1017, 113, 93, 118, 50, 0]);
    expect((await db.productsDao.getById(4))!.conversionRate, 0.5);

    // Cost: the product's current purchase price, per main unit.
    final cost = {
      for (final r in await db
          .customSelect('SELECT order_id, unit_cost FROM order_items')
          .get())
        r.read<int>('order_id'): r.read<double?>('unit_cost'),
    };
    expect(cost[1], 80); // Tea
    expect(cost[2], 10); // Cake, per main unit (the half sells at 0.5 of it)
    expect(cost[3], 170); // Bundle = 2 × Tea 80 + 1 × Cake 10
    expect(cost[4], isNull); // a component has no purchase price
    expect(cost[5], isNull); // no purchase price

    // Inclusive flag: inferred only where the totals prove it.
    final inclusive = {
      for (final r in await db
          .customSelect('SELECT order_id, MIN(is_inclusive) AS lo, '
              'MAX(is_inclusive) AS hi FROM order_taxes GROUP BY order_id')
          .get())
        r.read<int>('order_id'): (r.read<int>('lo'), r.read<int>('hi')),
    };
    expect(inclusive[1], (0, 0));
    expect(inclusive[2], (1, 1));
    expect(inclusive[3], (1, 1), reason: 'loyalty is netted before comparing');
    expect(inclusive[4], (0, 0));
    expect(inclusive[6], (0, 0), reason: 'paid with points, still exclusive');
  });

  test('v11 → v14 (order_items recreated on the way) gets the same backfill',
      () async {
    final schema = await verifier.schemaAt(11);
    schema.rawDatabase.execute(
      "INSERT INTO products (id, sku, name, price, purchase_price) VALUES (1, 'TEA', 'Tea', 100, 80)",
    );
    schema.rawDatabase.execute(
      "INSERT INTO orders (subtotal, total, payment_method) VALUES (200, 200, 'cash')",
    );
    schema.rawDatabase.execute(
      'INSERT INTO order_items (order_id, product_id, variant_id, product_name, unit_price, quantity, line_total) '
      "VALUES (1, 1, NULL, 'Tea', 100, 2, 200)",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);

    final item = (await db.ordersDao.getItems(1)).single;
    expect(item.unitCost, 80);
    expect(item.unitsPerQty, 1.0);
    expect(item.quantity, 2);
  });

  // ── v15: secondary indexes ───────────────────────────────────────────────

  const v15Indexes = {
    'idx_orders_created_at': 'orders',
    'idx_orders_customer_id': 'orders',
    'idx_order_items_order_id': 'order_items',
    'idx_order_taxes_order_id': 'order_taxes',
    'idx_returns_order_id': 'returns',
    'idx_audit_log_created_at': 'audit_log',
    'idx_stock_adjustments_product_created': 'stock_adjustments',
    'idx_expenses_date': 'expenses',
  };

  const allIndexes = {
    ...v15Indexes,
    'idx_orders_invoice_no': 'orders',
    'idx_shifts_closed_at': 'shifts',
    'idx_shifts_one_open': 'shifts',
    'idx_orders_voided_at': 'orders',
    'idx_returns_created_at': 'returns',
  };

  Future<Map<String, String>> indexes(AppDatabase db) async => {
        for (final r in await db
            .customSelect("SELECT name, tbl_name FROM sqlite_master "
                "WHERE type = 'index' AND name LIKE 'idx!_%' ESCAPE '!'")
            .get())
          r.read<String>('name'): r.read<String>('tbl_name'),
      };

  test('v14 → v15 adds the indexes and touches no rows', () async {
    final schema = await verifier.schemaAt(14);
    final raw = schema.rawDatabase;
    raw.execute("INSERT INTO products (id, sku, name, price) VALUES (1, 'TEA', 'Tea', 100)");
    raw.execute("INSERT INTO customers (id, name) VALUES (1, 'Asha')");
    raw.execute("INSERT INTO tax_rates (id, name, rate) VALUES (1, 'VAT', 0.13)");
    raw.execute(
      'INSERT INTO orders (id, status, subtotal, tax_total, total, payment_method, invoice_no, customer_id, created_at, updated_at) VALUES '
      "(1, 'completed', 100, 13, 113, 'cash', 1, 1, 1000, 1000), "
      "(2, 'voided', 200, 26, 226, 'card', 2, NULL, 2000, 2000)",
    );
    raw.execute(
      'INSERT INTO order_items (order_id, product_id, product_name, unit_price, quantity, line_total, unit_cost) VALUES '
      "(1, 1, 'Tea', 100, 1, 100, 60), (2, 1, 'Tea', 100, 2, 200, NULL)",
    );
    raw.execute(
      'INSERT INTO order_taxes (order_id, tax_rate_id, tax_rate_name, tax_rate_percent, taxable_amount, tax_amount, is_inclusive) VALUES '
      "(1, 1, 'VAT', 0.13, 100, 13, 0), (2, 1, 'VAT', 0.13, 200, 26, 1)",
    );
    raw.execute('INSERT INTO returns (order_id, amount, created_at) VALUES (1, 13, 1500)');
    raw.execute(
        "INSERT INTO stock_adjustments (product_id, delta, reason_code, created_at) VALUES (1, -1, 'sale', 1000)");
    raw.execute(
        "INSERT INTO audit_log (entity_type, entity_id, action, created_at) VALUES ('order', 1, 'create', 1000)");
    raw.execute(
        'INSERT INTO expenses (amount, date, category_id, created_at) '
        "SELECT 50, 1000, id, 1000 FROM expense_categories LIMIT 1");
    String dump(String table) => raw
        .select('SELECT * FROM $table ORDER BY id')
        .map((r) => r.values.join('|'))
        .join('\n');
    const tables = [
      'orders', 'order_items', 'order_taxes', 'returns', //
      'stock_adjustments', 'audit_log', 'expenses', 'products', 'customers',
    ];
    final before = {for (final t in tables) t: dump(t)};
    expect(before['orders'], isNotEmpty);

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);

    for (final t in tables) {
      final rows = await db.customSelect('SELECT * FROM $t ORDER BY id').get();
      // v16 appends tip_amount (default 0) to orders and returns, and
      // voided_at (NULL) to orders; every
      // column that existed at v14 must be untouched.
      expect(
          rows
              .map((r) => (Map.of(r.data)
                    ..remove('tip_amount')
                    ..remove('voided_at'))
                  .values
                  .join('|'))
              .join('\n'),
          before[t],
          reason: '$t rows must be untouched');
    }
    expect(await indexes(db), allIndexes);
  });

  test('a fresh install has the same indexes as an upgraded one', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(await indexes(db), allIndexes);
  });

  // ── v16: tips, refunded tips, till sessions ──────────────────────────────

  test('v15 → v16 adds tip columns at 0 and the shifts table, keeps rows',
      () async {
    final schema = await verifier.schemaAt(15);
    final raw = schema.rawDatabase;
    raw.execute(
      'INSERT INTO orders (id, status, subtotal, tax_total, total, payment_method, invoice_no, created_at, updated_at) VALUES '
      "(1, 'completed', 100, 13, 113, 'cash', 1, 1000, 1000), "
      "(2, 'refunded', 50, 0, 50, 'card', 2, 2000, 2000)",
    );
    raw.execute(
        'INSERT INTO returns (order_id, amount, created_at) VALUES (1, 13, 1500), (2, 50, 2500)');

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);

    final orders = await db
        .customSelect(
            'SELECT id, total, tip_amount, voided_at FROM orders ORDER BY id')
        .get();
    expect(
        orders.map((r) => (
              r.read<double>('total'),
              r.read<double>('tip_amount'),
              r.read<int?>('voided_at'),
            )),
        [(113.0, 0.0, null), (50.0, 0.0, null)]);
    final returns = await db
        .customSelect('SELECT amount, tip_amount FROM returns ORDER BY id')
        .get();
    expect(returns.map((r) => (r.read<double>('amount'), r.read<double>('tip_amount'))),
        [(13.0, 0.0), (50.0, 0.0)]);
    expect(await db.shiftsDao.currentShift(), isNull);
    expect(await indexes(db), allIndexes);
  });

  // ── The upgrade is atomic ────────────────────────────────────────────────

  /// Every statement of the v16 step, in order, by a fragment of its SQL.
  const v16Statements = [
    'ALTER TABLE "orders" ADD COLUMN "tip_amount"',
    'ALTER TABLE "orders" ADD COLUMN "voided_at"',
    'idx_orders_voided_at',
    'ALTER TABLE "returns" ADD COLUMN "tip_amount"',
    'CREATE TABLE IF NOT EXISTS "shifts"',
    'idx_shifts_closed_at',
    'idx_shifts_one_open',
    'idx_returns_created_at',
    'PRAGMA user_version',
  ];

  test('a clean v15 → v16 runs exactly the v16 statements listed', () async {
    final schema = await verifier.schemaAt(15);
    final db = _CutAfter(schema.newConnection(), v16Statements, failAt: -1);
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get();
    expect(db.seen, v16Statements);
  });

  for (var i = 0; i < v16Statements.length; i++) {
    test('interrupted after v16 statement ${i + 1} '
        '(${v16Statements[i]}): rolled back, the next launch upgrades',
        () async {
      final schema = await verifier.schemaAt(15);
      final raw = schema.rawDatabase;
      raw.execute(
          "INSERT INTO orders (id, subtotal, total, payment_method) VALUES (1, 5, 5, 'cash')");

      final crashed =
          _CutAfter(schema.newConnection(), v16Statements, failAt: i);
      await expectLater(
          crashed.customSelect('SELECT 1').get(), throwsA(anything));
      await crashed.close();

      // Nothing of v16 stuck: still a v15 file.
      expect(raw.select('PRAGMA user_version').single.values.single, 15);
      final cols = raw.select('PRAGMA table_info(orders)').map((r) => r['name']);
      expect(cols, isNot(contains('tip_amount')));
      expect(raw.select("SELECT name FROM sqlite_master WHERE name = 'shifts'"),
          isEmpty);

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);
      expect((await db.ordersDao.getById(1))!.tipAmount, 0);
    });
  }

  test('a database from a newer app is refused, not re-stamped', () async {
    final schema = await verifier.schemaAt(AppDatabase.currentSchemaVersion);
    final raw = schema.rawDatabase
      ..execute('PRAGMA user_version = ${AppDatabase.currentSchemaVersion + 1}');
    final db = AppDatabase(schema.newConnection());
    await expectLater(db.customSelect('SELECT 1').get(),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'message', contains('newer than this app'))));
    await db.close();
    expect(raw.select('PRAGMA user_version').single.values.single,
        AppDatabase.currentSchemaVersion + 1);
  });
}

/// An [AppDatabase] whose statements each run, then it throws right after
/// the [failAt]-th one that matches [watched] — a crash between two
/// statements of a step. (A real power cut rolls back the same way:
/// SQLite's journal undoes an uncommitted transaction on the next open.)
/// Records what it saw. Migrator DDL goes through [customStatement].
class _CutAfter extends AppDatabase {
  _CutAfter(super.executor, this.watched, {required this.failAt});
  final List<String> watched;
  final int failAt;
  final seen = <String>[];

  @override
  Future<void> customStatement(String statement, [List<dynamic>? args]) async {
    await super.customStatement(statement, args);
    for (final w in watched) {
      if (statement.contains(w)) {
        seen.add(w);
        if (seen.length - 1 == failAt) {
          throw StateError('simulated crash after: $statement');
        }
        break;
      }
    }
  }
}
