import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/backup/data/backup_repository.dart';

import '../../_support/test_db.dart';

/// The orders / sales-report CSV exports are written a page at a time with
/// the product SKU joined in SQL. Files already in users' hands must stay
/// re-importable, so the output has to be byte-for-byte what the previous
/// implementation (kept below, verbatim, as the reference) produced.
void main() {
  late AppDatabase db;
  late Directory tmp;

  setUp(() async {
    db = openInMemoryDatabase();
    tmp = await Directory.systemTemp.createTemp('pos_csv_');
  });
  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  // ── The implementation this replaced ─────────────────────────────────────

  Future<List<QueryRow>> legacyAllOrdersWithItems() => db.customSelect(
        'SELECT '
        'o.id as o_id, o.status, o.subtotal as o_subtotal, o.tax_total, o.discount_total as o_discount, o.total as o_total, '
        'o.payment_method, o.tendered_amount, o.change_amount, o.customer_id, o.notes, o.created_at, '
        'oi.id as item_id, oi.product_id, oi.product_name, oi.unit_price, oi.quantity, oi.discount as item_discount, '
        'oi.tax_amount as item_tax, oi.line_total, '
        'c.name as customer_name '
        'FROM orders o '
        'LEFT JOIN order_items oi ON o.id = oi.order_id '
        'LEFT JOIN customers c ON o.customer_id = c.id '
        'ORDER BY o.created_at DESC',
      ).get();

  Future<String> legacyOrdersCsv() async {
    final data = await legacyAllOrdersWithItems();
    final List<List<dynamic>> rows = [
      [
        'Order ID', 'Status', 'Subtotal', 'Tax Total', 'Discount', 'Total', //
        'Payment Method', 'Tendered', 'Change', 'Customer Name', 'Notes',
        'Created At', 'Item Product ID', 'Item Name', 'Item SKU',
        'Item Price', 'Item Qty', 'Item Discount', 'Item Tax', 'Item Total'
      ],
    ];
    for (final row in data) {
      String sku = '';
      final productId = row.read<int?>('product_id');
      if (productId != null) {
        final p = await (db.select(db.products)
              ..where((p) => p.id.equals(productId)))
            .getSingleOrNull();
        sku = p?.sku ?? '';
      }
      rows.add([
        row.read<int>('o_id'),
        row.read<String>('status'),
        row.read<double>('o_subtotal'),
        row.read<double>('tax_total'),
        row.read<double>('o_discount'),
        row.read<double>('o_total'),
        row.read<String>('payment_method'),
        row.read<double?>('tendered_amount') ?? 0.0,
        row.read<double?>('change_amount') ?? 0.0,
        row.read<String?>('customer_name') ?? '',
        row.read<String?>('notes') ?? '',
        row.read<DateTime>('created_at').toIso8601String(),
        productId ?? '',
        row.read<String?>('product_name') ?? '',
        sku,
        row.read<double?>('unit_price') ?? 0.0,
        row.read<int?>('quantity') ?? 0,
        row.read<double?>('item_discount') ?? 0.0,
        row.read<double?>('item_tax') ?? 0.0,
        row.read<double?>('line_total') ?? 0.0,
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  Future<String> legacySalesReportCsv() async {
    final data = await legacyAllOrdersWithItems();
    final List<List<dynamic>> rows = [
      [
        'Date', 'Order ID', 'Item', 'Qty', 'Unit Price', 'Line Total', //
        'Payment', 'Customer', 'Status'
      ],
    ];
    for (final row in data) {
      rows.add([
        row.read<DateTime>('created_at').toIso8601String().split('T')[0],
        row.read<int>('o_id'),
        row.read<String?>('product_name') ?? 'Unknown',
        row.read<int?>('quantity') ?? 0,
        row.read<double?>('unit_price') ?? 0.0,
        row.read<double?>('line_total') ?? 0.0,
        row.read<String>('payment_method'),
        row.read<String?>('customer_name') ?? 'Walk-in',
        row.read<String>('status'),
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  // ── Fixture ──────────────────────────────────────────────────────────────

  /// A small shop exercising every column: quoting (commas, quotes, line
  /// breaks), NULLs, a customer, a secondary-unit line, an order without
  /// lines, a renamed product, voided/refunded statuses, and two orders
  /// sharing a timestamp.
  Future<void> seed() async {
    final tea = await db.productsDao.upsert(ProductsCompanion.insert(
        sku: 'TEA-01', name: 'Tea (renamed since)', price: 100));
    final eggs = await db.productsDao.upsert(
        ProductsCompanion.insert(sku: 'EGG,"XL"', name: 'Eggs', price: 15));
    final asha = await db.customersDao
        .upsert(CustomersCompanion.insert(name: 'Asha "AG" Gurung, Mrs'));

    Future<int> order(
      DateTime at, {
      String status = 'completed',
      double subtotal = 100,
      double tax = 0,
      double discount = 0,
      String method = 'cash',
      double? tendered,
      double? change,
      int? customerId,
      String? notes,
    }) =>
        db.ordersDao.insertOrder(OrdersCompanion.insert(
          subtotal: subtotal,
          total: subtotal + tax - discount,
          paymentMethod: method,
          status: Value(status),
          taxTotal: Value(tax),
          discountTotal: Value(discount),
          tenderedAmount: Value(tendered),
          changeAmount: Value(change),
          customerId: Value(customerId),
          notes: Value(notes),
          createdAt: Value(at),
        ));
    OrderItemsCompanion item(int o, int product, String name, double price,
            int qty,
            {double discount = 0, double tax = 0}) =>
        OrderItemsCompanion.insert(
          orderId: o,
          productId: product,
          productName: name,
          unitPrice: price,
          quantity: qty,
          discount: Value(discount),
          taxAmount: Value(tax),
          lineTotal: price * qty - discount,
        );

    final o1 = await order(DateTime(2026, 3, 1, 9, 30),
        subtotal: 280.5,
        tax: 36.47,
        discount: 10,
        tendered: 500,
        change: 193.03,
        customerId: asha,
        notes: 'Ring bell, then wait\nSecond line; says "hi"');
    final o2 = await order(DateTime(2026, 3, 2, 18, 5, 7),
        status: 'voided', method: 'card');
    await order(DateTime(2026, 3, 3, 8), subtotal: 0); // no lines at all
    final o4 = await order(DateTime(2026, 3, 2, 18, 5, 7), // same second as o2
        status: 'refunded',
        method: 'wallet',
        customerId: asha);
    final o5 = await order(DateTime(2025, 12, 31, 23, 59, 59), subtotal: 45);
    await db.ordersDao.insertItems([
      item(o1, tea, 'Tea', 100, 2, tax: 26),
      item(o1, eggs, 'Eggs (dozen)', 90.5, 1, discount: 10, tax: 10.47),
      item(o2, tea, 'Tea', 100, 1),
      item(o4, eggs, 'Eggs', 15, 4),
      item(o4, tea, 'Tea, "special"', 40, 1),
      item(o5, eggs, 'Eggs', 15, 3),
    ]);
  }

  Future<String> written(Future<void> Function(File file) write) async {
    final file = File('${tmp.path}/out.csv');
    await write(file);
    // Compare bytes, not decoded text, so encoding and line endings count.
    return String.fromCharCodes(await file.readAsBytes());
  }

  String bytesOf(String s) => String.fromCharCodes(s.codeUnits);

  test('orders CSV is byte-identical to the previous implementation, '
      'whatever the page size', () async {
    await seed();
    final expected = await legacyOrdersCsv();
    expect(expected, contains('TEA-01'));
    expect(expected.split('\r\n'), hasLength(8), reason: 'header + 7 rows');

    final repo = BackupRepository(db);
    for (final pageSize in [1, 2, 3, 500]) {
      expect(
        await written((f) => repo.writeOrdersCsv(f, pageSize: pageSize)),
        bytesOf(expected),
        reason: 'pageSize $pageSize',
      );
    }
    expect(await written(repo.writeOrdersCsv), bytesOf(expected));
  });

  test('sales report CSV is byte-identical to the previous implementation',
      () async {
    await seed();
    final expected = await legacySalesReportCsv();
    final repo = BackupRepository(db);
    for (final pageSize in [1, 2, 500]) {
      expect(
        await written((f) => repo.writeSalesReportCsv(f, pageSize: pageSize)),
        bytesOf(expected),
        reason: 'pageSize $pageSize',
      );
    }
  });

  test('an empty history exports just the header, as before', () async {
    final repo = BackupRepository(db);
    expect(await written(repo.writeOrdersCsv), await legacyOrdersCsv());
    expect(
        await written(repo.writeSalesReportCsv), await legacySalesReportCsv());
  });

  test('the export still round-trips through importOrders', () async {
    await seed();
    final repo = BackupRepository(db);
    final csv = await written(repo.writeOrdersCsv);

    // A second, empty shop to import into (separate in-memory databases).
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(
        () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);
    final other = openInMemoryDatabase();
    addTearDown(other.close);
    final imported = await BackupRepository(other).importOrders(csv);
    expect(imported, greaterThan(0));
    final count = await other
        .customSelect('SELECT COUNT(*) AS c FROM orders')
        .map((r) => r.read<int>('c'))
        .getSingle();
    expect(count, imported);
  });

  test('each page is one bounded query — no lookup per row', () async {
    await seed();
    final rows = await db.ordersDao.ordersWithItemsPage(limit: 2);
    // Newest two orders: the line-less one, then the later-inserted of the
    // two sharing a timestamp (2 lines).
    expect(rows.map((r) => r.read<int>('o_id')), [3, 4, 4]);
    expect(rows.map((r) => r.read<String?>('product_sku')),
        [null, 'EGG,"XL"', 'TEA-01']);
  });
}
