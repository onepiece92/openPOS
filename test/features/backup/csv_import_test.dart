import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/backup/data/backup_repository.dart';
import 'package:pos_app/features/cart/data/place_order.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/orders/domain/order_number.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';
import 'package:pos_app/features/receipts/presentation/receipt_pdf_service.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// CSV import: what a file in a user's hands does to the database.
void main() {
  late AppDatabase db;
  late BackupRepository repo;

  setUp(() {
    db = openInMemoryDatabase();
    repo = BackupRepository(db);
  });
  tearDown(() => db.close());

  Future<List<Product>> products() =>
      (db.select(db.products)..orderBy([(p) => OrderingTerm.asc(p.id)])).get();
  Future<List<Customer>> customers() =>
      (db.select(db.customers)..orderBy([(c) => OrderingTerm.asc(c.id)]))
          .get();
  Future<List<Order>> orders() =>
      (db.select(db.orders)..orderBy([(o) => OrderingTerm.asc(o.id)])).get();

  const productsHeader =
      'SKU,Name,Price,Category,Stock,Is Taxable,Tax Rates,Is Hidden,Is Composite';
  const ordersHeader =
      'Order ID,Status,Subtotal,Tax Total,Discount,Total,Payment Method,'
      'Tendered,Change,Customer Name,Notes,Created At,Item Product ID,'
      'Item Name,Item SKU,Item Price,Item Qty,Item Discount,Item Tax,'
      'Item Total';

  // ── 1. Text columns stay text ────────────────────────────────────────────

  group('text columns', () {
    test('a SKU keeps its leading zeros', () async {
      await repo.importProducts('$productsHeader\r\n'
          '00123,Tea,100.0,Drinks,5,1,,0,0\r\n'
          '0001e5,Odd,1,Drinks,0,1,,0,0');
      expect((await products()).map((p) => p.sku), ['00123', '0001e5']);
    });

    test('a phone keeps its leading zero; a numeric name stays text',
        () async {
      await repo.importCustomers('Name,Phone,Email,Loyalty Points,Is Tax Exempt\r\n'
          'Asha,0412345678,,12,0\r\n'
          '007,+977 0980,,0,1');
      final all = await customers();
      expect(all.map((c) => c.phone), ['0412345678', '+977 0980']);
      expect(all.map((c) => c.name), ['Asha', '007']);
      expect(all.map((c) => c.loyaltyPoints), [12, 0]);
      expect(all.map((c) => c.isTaxExempt), [false, true]);
    });

    test('blank optional text is stored as NULL, not as an empty string',
        () async {
      await repo.importCustomers(
          'Name,Phone,Email,Loyalty Points,Is Tax Exempt\r\nAsha,,,0,0');
      final c = (await customers()).single;
      expect(c.phone, isNull);
      expect(c.email, isNull);

      await repo.importExpenses(
          'Amount,Date,Category,Notes,Is Recurring,Frequency,Tax Deductible,Status\r\n'
          '12.5,2026-03-01T09:30:00.000,Rent,,0,,0,approved');
      final e = (await db.expensesDao.getAll()).single;
      expect(e.notes, isNull);
      expect(e.recurringFrequency, isNull);
    });

    test('numbers that are not numbers stop the import with the row named',
        () async {
      await expectLater(
        repo.importProducts('$productsHeader\r\n'
            'A,Tea,100,Drinks,5,1,,0,0\r\n'
            'B,Bun,abc,Drinks,5,1,,0,0'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            allOf(contains('Row 3'), contains('Price'), contains('abc')))),
      );
      expect(await products(), isEmpty, reason: 'nothing half-imported');

      await expectLater(
        repo.importExpenses('Amount,Date\r\n5,not a date'),
        throwsA(isA<FormatException>().having(
            (e) => e.message, 'message', allOf(contains('Row 2'), contains('Date')))),
      );
    });

    test('a blank price or stock on a new product is zero', () async {
      await repo.importProducts('$productsHeader\r\nA,Tea,,,,,,,');
      final p = (await products()).single;
      expect(p.price, 0);
      expect(p.stockQuantity, 0);
      expect(p.isTaxable, isTrue);
      expect(p.categoryId, isNull);
    });
  });

  // ── 2. Line endings, BOM, blank lines ────────────────────────────────────

  group('file shape', () {
    const rows = [
      productsHeader,
      'A1,Tea,100,Drinks,5,1,,0,0',
      'B2,"Bun, sweet",20.5,Bakery,0,0,,1,0',
    ];

    for (final (label, eol) in [
      ('CRLF', '\r\n'),
      ('LF', '\n'),
      ('CR', '\r'),
    ]) {
      test('$label line endings import every row', () async {
        expect(await repo.importProducts(rows.join(eol)), 2);
        expect((await products()).map((p) => p.name), ['Tea', 'Bun, sweet']);
      });
    }

    test('a byte-order mark, a trailing newline and blank lines are ignored',
        () async {
      final csv = '﻿${rows.join('\n')}\n\n\n';
      expect(await repo.importProducts(csv), 2);
      final all = await products();
      expect(all.map((p) => p.sku), ['A1', 'B2']);
      expect(all[1].price, 20.5);
    });

    test('a line break inside quotes is data, whatever the file uses',
        () async {
      await repo.importCustomers('Name,Phone\n"Asha\nGurung",01\n"B\r\nC",02\n');
      expect((await customers()).map((c) => c.name),
          ['Asha\nGurung', 'B\r\nC']);
    });

    test('headers match whatever their case or padding', () async {
      expect(await repo.importProducts(' sku , NAME ,price\nA,Tea,5\n'), 1);
      expect((await products()).single.price, 5);
    });

    test('a short row does not crash the import', () async {
      expect(
          await repo.importCustomers(
              'Name,Phone,Email,Loyalty Points,Is Tax Exempt\nAsha\nBina,02'),
          2);
      expect((await customers()).map((c) => c.phone), [null, '02']);
    });
  });

  // ── 3. Products: update in place ─────────────────────────────────────────

  group('products re-import', () {
    test('an existing SKU is updated in place, keeping its id', () async {
      final id = await db.productsDao.upsert(ProductsCompanion.insert(
          sku: '00123',
          name: 'Tea',
          price: 100,
          purchasePrice: const Value(60),
          stockQuantity: const Value(5)));

      final report = await repo.importProductsReport('$productsHeader\r\n'
          '00123,Green Tea,120,Drinks,9,0,,1,0\r\n'
          'NEW-1,Bun,20,Bakery,3,1,,0,0');
      expect((report.added, report.updated), (1, 1));

      final all = await products();
      expect(all, hasLength(2));
      final tea = all.first;
      expect(tea.id, id);
      expect(tea.name, 'Green Tea');
      expect(tea.price, 120);
      expect(tea.stockQuantity, 9);
      expect(tea.isTaxable, isFalse);
      expect(tea.isHiddenInPos, isTrue);
      expect(tea.purchasePrice, 60, reason: 'not in the file, so untouched');
      expect(tea.categoryId, isNotNull);
    });

    test('a soft-deleted product is restored, not duplicated', () async {
      final id = await db.productsDao.upsert(ProductsCompanion.insert(
          sku: 'OLD', name: 'Old', price: 1, isActive: const Value(false)));
      expect(await repo.importProducts('$productsHeader\r\nOLD,Old,2,,0,1,,0,0'),
          1);
      final p = (await products()).single;
      expect(p.id, id);
      expect(p.isActive, isTrue);
      expect(p.price, 2);
    });

    test('importing the same file twice changes nothing the second time',
        () async {
      const csv = '$productsHeader\r\n'
          '00123,Tea,100,Drinks,5,1,,0,0\r\n'
          ',No Sku,7,Uncategorized,1,1,,0,0';
      final first = await repo.importProductsReport(csv);
      expect((first.added, first.updated), (2, 0));
      final before = await products();

      final second = await repo.importProductsReport(csv);
      expect((second.added, second.updated), (0, 2));
      final after = await products();
      expect(after.map((p) => (p.id, p.sku, p.name, p.price, p.stockQuantity)),
          before.map((p) => (p.id, p.sku, p.name, p.price, p.stockQuantity)));
      expect(before[1].sku, isNotEmpty, reason: 'a SKU is generated');
    });

    test('a row with no SKU matches on exact name', () async {
      final id = await db.productsDao
          .upsert(ProductsCompanion.insert(sku: 'T', name: 'Tea', price: 1));
      await repo.importProducts('Name,Price,SKU\nTea,9,\ntea,3,');
      final all = await products();
      expect(all.map((p) => (p.id, p.sku, p.price)).first, (id, 'T', 9.0));
      expect(all, hasLength(2), reason: '"tea" is not "Tea": added as new');
    });

    test('a row with no SKU and an ambiguous name is refused', () async {
      for (final sku in ['T1', 'T2']) {
        await db.productsDao
            .upsert(ProductsCompanion.insert(sku: sku, name: 'Tea', price: 1));
      }
      await expectLater(
        repo.importProducts('Name,Price,SKU\nTea,9,'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            allOf(contains('Row 2'), contains('Tea'), contains('SKU')))),
      );
      expect((await products()).map((p) => p.price), [1, 1]);
    });

    test('a column the file lacks is left alone on update', () async {
      await db.productsDao.upsert(ProductsCompanion.insert(
          sku: 'T',
          name: 'Tea',
          price: 1,
          stockQuantity: const Value(7),
          isHiddenInPos: const Value(true)));
      await repo.importProducts('SKU,Name,Price\nT,Tea,2');
      final p = (await products()).single;
      expect((p.price, p.stockQuantity, p.isHiddenInPos), (2.0, 7, true));
    });

    test('a stock change made by an import is logged', () async {
      final id = await db.productsDao.upsert(ProductsCompanion.insert(
          sku: 'T', name: 'Tea', price: 1, stockQuantity: const Value(7)));
      await repo.importProducts('SKU,Name,Price,Stock\nT,Tea,1,4');
      final log = await db.inventoryDao.getAdjustmentsForProduct(id);
      expect(log.map((a) => (a.delta, a.reasonCode)), [(-3, 'count')]);
      expect(log.single.notes, contains('CSV import'));

      await repo.importProducts('SKU,Name,Price,Stock\nT,Tea,1,4');
      expect(await db.inventoryDao.getAdjustmentsForProduct(id), hasLength(1),
          reason: 'no change, no entry');
    });
  });

  // ── 4. Customers / expenses / orders re-import ───────────────────────────

  group('customers re-import', () {
    const header = 'Name,Phone,Email,Loyalty Points,Is Tax Exempt';

    test('matched on phone, else on name + email; updated in place',
        () async {
      const csv = '$header\r\n'
          'Asha,0412345678,a@x.np,10,0\r\n'
          'Bina,,b@x.np,0,1\r\n'
          'Bina,,other@x.np,0,0\r\n'
          'Chandra,,,5,0';
      final first = await repo.importCustomersReport(csv);
      expect((first.added, first.updated), (4, 0));
      final before = await customers();

      final second = await repo.importCustomersReport(csv);
      expect((second.added, second.updated), (0, 4));
      expect(await customers(), hasLength(4));

      // Same phone, new name and points: the same customer, updated.
      await repo.importCustomers('$header\r\nAsha G.,0412345678,,99,1');
      final asha = (await customers()).first;
      expect(asha.id, before.first.id);
      expect(asha.name, 'Asha G.');
      expect(asha.loyaltyPoints, 99);
      expect(asha.isTaxExempt, isTrue);
      expect(asha.email, 'a@x.np', reason: 'a blank cell does not erase');
      expect(await customers(), hasLength(4));
    });

    test('two people sharing a phone stay two people', () async {
      const csv = '$header\r\nAsha,0412,,0,0\r\nBina,0412,,0,0';
      await repo.importCustomers(csv);
      await repo.importCustomers(csv);
      expect((await customers()).map((c) => c.name), ['Asha', 'Bina']);
    });
  });

  test('expenses have no identifier: a second import adds them again',
      () async {
    const csv =
        'Amount,Date,Category,Notes,Is Recurring,Frequency,Tax Deductible,Status\r\n'
        '12.5,2026-03-01T09:30:00.000,Rent,March,1,monthly,1,approved';
    final first = await repo.importExpensesReport(csv);
    final second = await repo.importExpensesReport(csv);
    expect((first.added, second.added, second.skipped), (1, 1, 0));
    expect(await db.expensesDao.getAll(), hasLength(2));
    final rent = (await db.expensesDao.getAllCategories())
        .where((c) => c.name == 'Rent');
    expect(rent, hasLength(1), reason: 'the category is reused');
  });

  group('orders', () {
    String orderRow(
      int id, {
      String status = 'completed',
      double total = 200,
      String method = 'cash',
      String tendered = '500.0',
      String change = '300.0',
      String customer = '',
      String at = '2026-03-01T09:30:00.000',
      String item = 'Tea',
      String sku = 'TEA',
      double price = 100,
      int qty = 2,
    }) =>
        '$id,$status,$total,0.0,0.0,$total,$method,$tendered,$change,'
        '$customer,,$at,1,$item,$sku,$price,$qty,0.0,0.0,${price * qty}';

    Future<void> seedTea() => db.productsDao
        .upsert(ProductsCompanion.insert(sku: 'TEA', name: 'Tea', price: 100));

    test('imported orders carry no tip (schema v16 default)', () async {
      await seedTea();
      await repo.importOrders([ordersHeader, orderRow(7)].join('\r\n'));
      final o = (await orders()).single;
      expect(o.billNo, 'IMP-7');
      expect((o.total, o.tipAmount), (200.0, 0.0));
    });

    test('the payment method is stored trimmed and lower-case, blank as cash',
        () async {
      await seedTea();
      await repo.importOrders([
        ordersHeader,
        orderRow(1, method: ' Cash '),
        orderRow(2, method: 'CARD', tendered: '0.0', change: '0.0'),
        orderRow(3, method: ''),
      ].join('\r\n'));
      expect((await orders()).map((o) => o.paymentMethod),
          ['cash', 'card', 'cash']);
    });

    test('a second import of the same file adds nothing', () async {
      await seedTea();
      final csv = [ordersHeader, orderRow(7), orderRow(9, total: 100, qty: 1)]
          .join('\r\n');
      final first = await repo.importOrdersReport(csv);
      expect((first.added, first.skipped), (2, 0));
      final second = await repo.importOrdersReport(csv);
      expect((second.added, second.skipped), (0, 2));
      expect(await orders(), hasLength(2));
      final revenue = (await orders()).fold(0.0, (s, o) => s + o.total);
      expect(revenue, 300);
    });

    test('importing a shop\'s own export back into it adds nothing', () async {
      final p = await seedProduct(db, sku: 'TEA', stock: 0);
      await sell(db, AuditService(db), [line(p, qty: 2)]);
      final o = (await orders()).single;
      final csv = [
        ordersHeader,
        '${o.id},completed,${o.subtotal},0.0,0.0,${o.total},cash,10.0,0.0,,,'
            '${o.createdAt.toIso8601String()},$p,TEA,TEA,5.0,2,0.0,0.0,10.0',
      ].join('\r\n');
      final report = await repo.importOrdersReport(csv);
      expect((report.added, report.skipped), (0, 1));
      expect(await orders(), hasLength(1));
    });

    test('same Order ID but a different sale is a different order', () async {
      await seedTea();
      await repo.importOrders([ordersHeader, orderRow(7)].join('\n'));
      // Another shop's order 7: other time, other total.
      final report = await repo.importOrdersReport([
        ordersHeader,
        orderRow(7, total: 100, qty: 1, at: '2026-04-02T10:00:00.000')
      ].join('\n'));
      expect((report.added, report.skipped), (1, 0));
      final all = await orders();
      expect(all, hasLength(2));
      expect(all[0].billNo, 'IMP-7');
      expect(all[1].billNo, 'IMP-${all[1].id}');
      expect(all[1].invoiceNo, isNull);
    });

    test('imported orders are labelled IMP- and take no invoice numbers',
        () async {
      final audit = AuditService(db);
      final p = await seedProduct(db, sku: 'TEA', stock: 0);
      Future<Order> sell({String prefix = ''}) async {
        final id = await placeOrder(db, audit,
            cart: [line(p)],
            summary: const CartSummary(
                subtotal: 5,
                orderDiscount: 0,
                loyaltyDiscount: 0,
                taxLines: [],
                taxAmount: 0,
                total: 5,
                taxEnabled: false,
                pointsToEarn: 0),
            session: CartSession(ticketNumber: '#1', openedAt: DateTime.now()),
            paymentMethod: 'cash',
            tenderedAmount: 5,
            invoicePrefix: prefix);
        return (await db.ordersDao.getById(id))!;
      }

      expect((await sell()).billNo, '#1');
      expect((await sell(prefix: '2082/83')).billNo, '2082/83-1');

      await repo.importOrders([
        ordersHeader,
        orderRow(1),
        orderRow(2, at: '2026-03-02T09:30:00.000'),
        orderRow(17, at: '2026-03-03T09:30:00.000'),
      ].join('\r\n'));

      final imported = (await orders()).skip(2).toList();
      expect(imported.map((o) => o.billNo), ['IMP-1', 'IMP-2', 'IMP-17']);
      expect(imported.map((o) => o.invoicePrefix).toSet(), {'IMP'});

      // The real sequences carry on exactly where they were.
      expect(await db.ordersDao.nextInvoiceNo(), 2);
      expect(await db.ordersDao.nextInvoiceNo(prefix: '2082/83'), 2);
      expect((await sell()).billNo, '#2');
      expect((await sell(prefix: '2082/83')).billNo, '2082/83-2');
      final bills = (await orders()).map((o) => o.billNo).toList();
      expect(bills.toSet(), hasLength(bills.length),
          reason: 'no two orders show the same bill number: $bills');
    });

    test('a line whose product is unknown is left out and noted on the order',
        () async {
      await seedTea();
      final csv = [
        ordersHeader,
        orderRow(7, total: 260),
        orderRow(7, total: 260, item: 'Mystery, bun', sku: 'NOPE', price: 30, qty: 2)
            .replaceFirst('Mystery, bun', '"Mystery, bun"'),
      ].join('\r\n');
      final report = await repo.importOrdersReport(csv);
      expect((report.added, report.unmatchedLines), (1, 1));
      final o = (await orders()).single;
      expect(o.total, 260);
      final items = await db.ordersDao.getItems(o.id);
      expect(items.map((i) => i.productName), ['Tea']);
      expect(o.notes, contains('Mystery, bun'));
      expect(o.notes, contains('60.00'));
      expect(report.summary('orders'), contains('1 line'));
    });

    test('lines match on SKU first, then on name', () async {
      await seedTea();
      final bun = await db.productsDao
          .upsert(ProductsCompanion.insert(sku: 'B', name: 'Bun', price: 1));
      await repo.importOrders([
        ordersHeader,
        orderRow(7, item: 'Tea as sold', sku: 'TEA'),
        orderRow(7, item: 'Bun', sku: ''),
      ].join('\n'));
      final items = await db.ordersDao.getItems((await orders()).single.id);
      expect(items.map((i) => (i.productName, i.productId)),
          [('Tea as sold', 1), ('Bun', bun)]);
    });

    test('only the required columns: the rest default', () async {
      await seedTea();
      final report = await repo.importOrdersReport(
          'Order ID,Created At,Item Name,Total\n5,2026-03-01 09:30:00,Tea,100');
      expect(report.added, 1);
      final o = (await orders()).single;
      expect(o.status, 'completed');
      expect(o.paymentMethod, 'cash');
      expect((o.subtotal, o.total, o.taxTotal, o.discountTotal),
          (100.0, 100.0, 0.0, 0.0));
      expect((o.tenderedAmount, o.changeAmount, o.customerId, o.notes),
          (null, null, null, null));
      final item = (await db.ordersDao.getItems(o.id)).single;
      expect((item.quantity, item.unitPrice, item.lineTotal), (1, 0.0, 0.0));
    });

    test('a blank payment method becomes cash', () async {
      await seedTea();
      await repo.importOrders(
          [ordersHeader, orderRow(7, method: '', tendered: '0.0', change: '0.0')]
              .join('\n'));
      expect((await orders()).single.paymentMethod, 'cash');
    });

    test('tendered and change: nothing recorded is NULL, not 0.00', () async {
      await seedTea();
      await repo.importOrders([
        ordersHeader,
        orderRow(1, method: 'card', tendered: '0.0', change: '0.0'),
        orderRow(2, method: 'wallet', tendered: '', change: ''),
        orderRow(3, method: 'cash', tendered: '500.0', change: '300.0'),
        orderRow(4, method: 'cash', tendered: '200.0', change: '0.0'),
        orderRow(5, method: 'cash', tendered: '0.0', change: '0.0'),
      ].join('\n'));
      expect((await orders()).map((o) => (o.tenderedAmount, o.changeAmount)), [
        (null, null),
        (null, null),
        (500.0, 300.0),
        (200.0, 0.0),
        (null, null),
      ]);
    });

    test('customers and products with repeated names do not crash it',
        () async {
      for (final sku in ['T1', 'T2']) {
        await db.productsDao
            .upsert(ProductsCompanion.insert(sku: sku, name: 'Twin', price: 1));
      }
      for (var i = 0; i < 2; i++) {
        await db.customersDao.upsert(CustomersCompanion.insert(name: 'Asha'));
      }
      final report = await repo.importOrdersReport([
        ordersHeader,
        orderRow(7, customer: 'Asha', item: 'Twin', sku: ''),
      ].join('\n'));
      expect((report.added, report.unmatchedLines), (1, 1));
      expect((await orders()).single.customerId, isNull,
          reason: 'two customers called Asha: not guessed');
    });
  });

  // ── 5. Receipts tolerate an order with no payment method ─────────────────

  group('receipt for an order with an empty payment method', () {
    Future<ReceiptBodyData> emptyMethodOrder() async {
      final id = await db.ordersDao.insertOrder(OrdersCompanion.insert(
          subtotal: 10, total: 10, paymentMethod: ''));
      return ReceiptBodyData(
          order: (await db.ordersDao.getById(id))!,
          items: const [],
          taxes: const [],
          businessName: 'Shop');
    }

    final fmt = CurrencyFormatter(symbol: 'Rs ', locale: 'en_US');

    testWidgets('on screen', (tester) async {
      late ReceiptBodyData data;
      await tester.runAsync(() async => data = await emptyMethodOrder());
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: ReceiptBody(data: data, fmt: fmt))));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Payment Mode:'), findsOneWidget);
    });

    test('as a PDF', () async {
      final doc = await buildReceiptPdf(await emptyMethodOrder(), fmt);
      expect(await doc.save(), isNotEmpty);
    });
  });
}
