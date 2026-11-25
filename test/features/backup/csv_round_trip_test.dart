import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/backup/data/backup_repository.dart';
import 'package:pos_app/features/backup/data/csv_text.dart';
import 'package:pos_app/features/orders/domain/order_number.dart';

import '../../_support/test_db.dart';

/// Export from one shop, import into an empty one, and compare everything
/// the CSV format can carry. Each test also pins down what it cannot carry,
/// so the limits of a CSV "backup" are written down where they are checked.
///
/// The fixtures use the awkward values real shops have: barcodes and phones
/// with leading zeros, names with commas, quotes and line breaks, Devanagari.
void main() {
  late AppDatabase source;
  late AppDatabase target;
  late Directory tmp;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    source = openInMemoryDatabase();
    target = openInMemoryDatabase();
    tmp = await Directory.systemTemp.createTemp('pos_csv_rt_');
  });
  tearDown(() async {
    await source.close();
    await target.close();
    await tmp.delete(recursive: true);
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  /// What a user's file goes through: written as UTF-8, read back as text.
  Future<String> viaFile(String csv) async {
    final file = File('${tmp.path}/x.csv');
    await file.writeAsBytes(utf8.encode(csv));
    return file.readAsString();
  }

  // ── The parser against the writer ────────────────────────────────────────

  test('exports use CRLF, no byte-order mark and no trailing newline',
      () async {
    await source.customersDao.upsert(CustomersCompanion.insert(name: 'A'));
    await source.customersDao.upsert(CustomersCompanion.insert(name: 'B'));
    final csv = await BackupRepository(source).customersCsv();
    expect(csv, 'Name,Phone,Email,Loyalty Points,Is Tax Exempt\r\n'
        'A,,,0,0\r\n'
        'B,,,0,0');
  });

  test('parseCsvText reads cells as text, whatever the line ending', () {
    const cells = [
      ['SKU', 'Name', 'Note'],
      ['00123', 'चिया, "कालो"', 'line 1\nline 2\r\nline 3'],
      ['', ' padded ', ''],
      ['1e5', '0412345678', '-0.50'],
    ];
    String quoted(String c) =>
        RegExp('[",\r\n]').hasMatch(c) ? '"${c.replaceAll('"', '""')}"' : c;
    for (final eol in ['\r\n', '\n', '\r']) {
      final csv = cells.map((r) => r.map(quoted).join(',')).join(eol);
      expect(parseCsvText(csv), cells, reason: 'eol ${eol.codeUnits}');
      expect(parseCsvText('﻿$csv$eol$eol'), cells,
          reason: 'BOM and trailing blank lines, eol ${eol.codeUnits}');
    }
    expect(parseCsvText(''), isEmpty);
    expect(parseCsvText('\r\n\n'), isEmpty);
    expect(parseCsvText('a,""\n""\n'), [
      ['a', ''],
      [''],
    ]);
  });

  // ── Products ─────────────────────────────────────────────────────────────

  test('products round-trip', () async {
    final drinks = await source.productsDao
        .upsertCategory(CategoriesCompanion.insert(name: 'पेय, "Drinks"'));
    final vat = await source.taxDao
        .upsertRate(TaxRatesCompanion.insert(name: 'VAT', rate: 0.13));
    final service = await source.taxDao
        .upsertRate(TaxRatesCompanion.insert(name: 'Service', rate: 0.1));

    final tea = await source.productsDao.upsert(ProductsCompanion.insert(
      sku: '00123',
      name: 'चिया (Tea), "special"\nlarge',
      price: 120.5,
      categoryId: Value(drinks),
      stockQuantity: const Value(-4),
      isTaxable: const Value(true),
      // Not in the file:
      purchasePrice: const Value(80),
      unit: const Value('cup'),
      secondaryUnit: const Value('flask'),
      conversionRate: const Value(6),
      imagePath: const Value('/img/tea.png'),
      isOutOfStock: const Value(true),
    ));
    await source.taxDao.setProductTaxes(tea, [vat, service]);
    await source.productsDao.upsert(ProductsCompanion.insert(
      sku: '0007',
      name: 'Bun, sweet',
      price: 20,
      stockQuantity: const Value(12),
      isTaxable: const Value(false),
      isHiddenInPos: const Value(true),
      isComposite: const Value(true),
    ));
    await source.productsDao.upsert(ProductsCompanion.insert(
        sku: '1e3', name: '1234', price: 0.1)); // number-shaped text
    await source.productsDao.upsert(ProductsCompanion.insert(
        sku: 'GONE', name: 'Deleted', price: 1, isActive: const Value(false)));

    final csv = await viaFile(await BackupRepository(source).productsCsv());

    // The target already has the tax rates (they are not in the file).
    await target.taxDao
        .upsertRate(TaxRatesCompanion.insert(name: 'VAT', rate: 0.13));
    await target.taxDao
        .upsertRate(TaxRatesCompanion.insert(name: 'Service', rate: 0.1));
    final report = await BackupRepository(target).importProductsReport(csv);
    expect((report.added, report.updated, report.skipped), (3, 0, 0));

    Future<List<Object>> carried(AppDatabase db) async {
      final cats = {
        for (final c in await db.productsDao.getAllCategories()) c.id: c.name
      };
      return [
        for (final p in await (db.select(db.products)
              ..where((p) => p.isActive.equals(true))
              ..orderBy([(p) => OrderingTerm.asc(p.id)]))
            .get())
          (
            p.sku,
            p.name,
            p.price,
            cats[p.categoryId],
            p.stockQuantity,
            p.isTaxable,
            p.isHiddenInPos,
            p.isComposite,
            ((await db.taxDao.getRatesForProduct(p.id))
                    .map((t) => t.name)
                    .toList()
                  ..sort())
                .join('|'),
          ),
      ];
    }

    expect(await carried(target), await carried(source));
    expect((await carried(target)).first.toString(), contains('00123'));
    expect(await BackupRepository(target).productsCsv(), csv,
        reason: 're-exporting gives the same file');

    // Not carried: cost, units, image, the out-of-stock switch, deleted
    // products, composite recipes. They come back as defaults.
    final t = await target.productsDao.getBySku('00123');
    expect(
      (t!.purchasePrice, t.unit, t.secondaryUnit, t.conversionRate, t.imagePath, t.isOutOfStock),
      (0.0, 'pcs', null, 1.0, null, false),
    );
    expect(await target.productsDao.getBySku('GONE'), isNull);

    // Second import: nothing new.
    final again = await BackupRepository(target).importProductsReport(csv);
    expect((again.added, again.updated), (0, 3));
    expect(await BackupRepository(target).productsCsv(), csv);
  });

  test('products: tax rates the target does not have are not created',
      () async {
    final vat = await source.taxDao
        .upsertRate(TaxRatesCompanion.insert(name: 'VAT', rate: 0.13));
    final p = await source.productsDao
        .upsert(ProductsCompanion.insert(sku: 'A', name: 'A', price: 1));
    await source.taxDao.setProductTaxes(p, [vat]);
    await BackupRepository(target)
        .importProducts(await BackupRepository(source).productsCsv());
    final imported = await target.productsDao.getBySku('A');
    expect(await target.taxDao.getRatesForProduct(imported!.id), isEmpty);
    expect((await target.select(target.taxRates).get()).map((t) => t.name),
        isNot(contains('VAT')));
  });

  // ── Customers ────────────────────────────────────────────────────────────

  test('customers round-trip', () async {
    for (final c in [
      CustomersCompanion.insert(
        name: 'आशा गुरुङ',
        phone: const Value('0412345678'),
        email: const Value('asha@example.com'),
        loyaltyPoints: const Value(120),
        isTaxExempt: const Value(true),
        // Not in the file:
        address: const Value('Pokhara-6'),
        defaultDiscount: const Value(5),
        defaultDiscountIsPercent: const Value(true),
        taxExemptCertificate: const Value('CERT-9'),
      ),
      CustomersCompanion.insert(
          name: 'O\'Brien, "Bob"\nJr.', phone: const Value('+977 0980-000')),
      CustomersCompanion.insert(name: 'No Contact'),
      // Same phone as another customer; same name as another customer.
      CustomersCompanion.insert(
          name: 'Bina', phone: const Value('0412345678')),
      CustomersCompanion.insert(
          name: 'Bina', email: const Value('bina@example.com')),
      CustomersCompanion.insert(name: '0042'),
    ]) {
      await source.customersDao.upsert(c);
    }

    final csv = await viaFile(await BackupRepository(source).customersCsv());
    final report = await BackupRepository(target).importCustomersReport(csv);
    expect((report.added, report.updated), (6, 0));

    Future<List<Object>> carried(AppDatabase db) async => [
          for (final c in await (db.select(db.customers)
                ..orderBy([(c) => OrderingTerm.asc(c.id)]))
              .get())
            (c.name, c.phone, c.email, c.loyaltyPoints, c.isTaxExempt),
        ];
    expect(await carried(target), await carried(source));
    expect(await BackupRepository(target).customersCsv(), csv);

    // Not carried: address, default discount, exemption certificate.
    final asha = (await target.customersDao.getAll()).first;
    expect(
      (asha.address, asha.defaultDiscount, asha.defaultDiscountIsPercent, asha.taxExemptCertificate),
      (null, 0.0, false, null),
    );

    // Second import: nothing new.
    final again = await BackupRepository(target).importCustomersReport(csv);
    expect((again.added, again.updated), (0, 6));
    expect(await BackupRepository(target).customersCsv(), csv);
  });

  // ── Expenses ─────────────────────────────────────────────────────────────

  test('expenses round-trip', () async {
    final rent = await source.expensesDao.upsertCategory(
        ExpenseCategoriesCompanion.insert(name: 'भाडा, "Rent"'));
    final general = (await source.expensesDao.getAllCategories()).first.id;
    await source.expensesDao.insert(ExpensesCompanion.insert(
      amount: 15000.75,
      date: DateTime(2026, 3, 1, 9, 30, 15),
      categoryId: rent,
      notes: const Value('मार्च को भाडा, "paid"\nby cheque 000123'),
      isRecurring: const Value(true),
      recurringFrequency: const Value('monthly'),
      isTaxDeductible: const Value(true),
      status: const Value('pending'),
      receiptImagePath: const Value('/img/r.png'), // not in the file
    ));
    await source.expensesDao.insert(ExpensesCompanion.insert(
        amount: 0.05, date: DateTime(2025, 12, 31), categoryId: general));

    final csv = await viaFile(await BackupRepository(source).expensesCsv());
    final report = await BackupRepository(target).importExpensesReport(csv);
    expect(report.added, 2);

    Future<List<Object>> carried(AppDatabase db) async {
      final cats = {
        for (final c in await db.expensesDao.getAllCategories()) c.id: c.name
      };
      final all = await db.expensesDao.getAll()
        ..sort((a, b) => a.id.compareTo(b.id));
      return [
        for (final e in all)
          (
            e.amount,
            e.date,
            cats[e.categoryId],
            e.notes,
            e.isRecurring,
            e.recurringFrequency,
            e.isTaxDeductible,
            e.status,
          ),
      ];
    }

    expect(await carried(target), await carried(source));
    expect(await BackupRepository(target).expensesCsv(), csv);
    // Not carried: the receipt photo.
    expect((await target.expensesDao.getAll()).map((e) => e.receiptImagePath),
        [null, null]);

    // Second import: the file has no key, so every expense is added again.
    await BackupRepository(target).importExpenses(csv);
    expect(await target.expensesDao.getAll(), hasLength(4));
  });

  // ── Orders ───────────────────────────────────────────────────────────────

  test('orders round-trip', () async {
    final tea = await source.productsDao.upsert(ProductsCompanion.insert(
        sku: '00123', name: 'चिया', price: 100, secondaryUnit: const Value('flask')));
    final bun = await source.productsDao.upsert(
        ProductsCompanion.insert(sku: '0007', name: 'Bun, "sweet"', price: 20));
    final asha = await source.customersDao.upsert(CustomersCompanion.insert(
        name: 'आशा, "AG"', phone: const Value('0412345678')));

    Future<int> order(
      DateTime at, {
      int? invoiceNo,
      String prefix = '',
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
        source.ordersDao.insertOrder(OrdersCompanion.insert(
          invoiceNo: Value(invoiceNo),
          invoicePrefix: Value(prefix),
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
          // Not in the file:
          pointsEarned: const Value(3),
          printCount: const Value(2),
        ));

    final o1 = await order(DateTime(2026, 3, 1, 9, 30),
        invoiceNo: 1,
        prefix: '2082/83',
        subtotal: 220,
        tax: 28.6,
        discount: 10,
        tendered: 500,
        change: 261.4,
        customerId: asha,
        notes: 'घण्टी बजाउनुहोस्, then wait\nsays "hi"');
    final o2 = await order(DateTime(2026, 3, 2, 18, 5, 7),
        invoiceNo: 2, prefix: '2082/83', status: 'voided', method: 'card');
    await order(DateTime(2026, 3, 3, 8), subtotal: 0, method: 'wallet');
    final o4 = await order(DateTime(2026, 3, 4, 12),
        status: 'refunded', subtotal: 40, tendered: 40, change: 0);
    await source.ordersDao.insertItems([
      OrderItemsCompanion.insert(
          orderId: o1,
          productId: tea,
          productName: 'चिया (as sold)',
          unitPrice: 100,
          quantity: 2,
          taxAmount: const Value(26),
          lineTotal: 200,
          unitLabel: const Value('flask'), // not in the file
          unitsPerQty: const Value(6), // not in the file
          unitCost: const Value(55)), // not in the file
      OrderItemsCompanion.insert(
          orderId: o1,
          productId: bun,
          productName: 'Bun, "sweet"',
          unitPrice: 30,
          quantity: 1,
          discount: const Value(10),
          taxAmount: const Value(2.6),
          lineTotal: 20),
      OrderItemsCompanion.insert(
          orderId: o2,
          productId: tea,
          productName: 'चिया',
          unitPrice: 100,
          quantity: 1,
          lineTotal: 100),
      OrderItemsCompanion.insert(
          orderId: o4,
          productId: bun,
          productName: 'Bun\nhalf',
          unitPrice: 20,
          quantity: 2,
          lineTotal: 40),
    ]);
    await source.ordersDao.insertTaxLines([
      OrderTaxesCompanion.insert(
          orderId: o1,
          taxRateId: await source.taxDao
              .upsertRate(TaxRatesCompanion.insert(name: 'VAT', rate: 0.13)),
          taxRateName: 'VAT',
          taxRatePercent: 13,
          taxableAmount: 220,
          taxAmount: 28.6),
    ]);

    final srcRepo = BackupRepository(source);
    final tgtRepo = BackupRepository(target);
    final ordersFile = File('${tmp.path}/orders.csv');
    await srcRepo.writeOrdersCsv(ordersFile);
    final csv = await ordersFile.readAsString();

    // As the import screen advises: products and customers first.
    await tgtRepo.importProducts(await srcRepo.productsCsv());
    await tgtRepo.importCustomers(await srcRepo.customersCsv());
    final report = await tgtRepo.importOrdersReport(csv);
    expect((report.added, report.skipped, report.unmatchedLines), (4, 0, 0));

    Future<List<Object>> carried(AppDatabase db) async {
      final names = {
        for (final c in await db.customersDao.getAll()) c.id: c.name
      };
      final skus = {
        for (final p in await db.select(db.products).get()) p.id: p.sku
      };
      final all = await (db.select(db.orders)
            ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
          .get();
      return [
        for (final o in all)
          (
            o.status,
            o.subtotal,
            o.taxTotal,
            o.discountTotal,
            o.total,
            o.paymentMethod,
            o.tenderedAmount,
            o.changeAmount,
            names[o.customerId],
            o.notes,
            o.createdAt,
            [
              for (final i in await db.ordersDao.getItems(o.id))
                (
                  i.productName,
                  skus[i.productId],
                  i.unitPrice,
                  i.quantity,
                  i.discount,
                  i.taxAmount,
                  i.lineTotal,
                ),
            ].toString(),
          ),
      ];
    }

    final got = await carried(target);
    expect(got, await carried(source));
    expect(got.toString(), contains('00123'));
    expect(got.toString(), contains('घण्टी बजाउनुहोस्, then wait\nsays "hi"'));

    // Re-exporting gives the same file apart from the two id columns.
    List<List<String>> withoutIds(String csv) => [
          for (final row in parseCsvText(csv))
            [
              for (var i = 0; i < row.length; i++)
                if (i != 0 && i != 12) row[i],
            ],
        ];
    await tgtRepo.writeOrdersCsv(ordersFile);
    expect(withoutIds(await ordersFile.readAsString()), withoutIds(csv));

    // Not carried: the bill number (the file has the row id, not the
    // invoice number), loyalty points, print count, tax lines, the unit a
    // line was sold in and its cost.
    final imported = await (target.select(target.orders)
          ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
        .get();
    expect(imported.map((o) => o.billNo),
        ['IMP-$o1', 'IMP-$o2', 'IMP-3', 'IMP-$o4']);
    expect((await source.ordersDao.getById(o1))!.billNo, '2082/83-1');
    final first = imported.first;
    expect((first.pointsEarned, first.printCount), (0, 0));
    expect(await target.ordersDao.getTaxBreakdown(first.id), isEmpty);
    final line = (await target.ordersDao.getItems(first.id)).first;
    expect((line.unitLabel, line.unitsPerQty, line.unitCost), ('', 1.0, null));
    // Stock is not moved by an import.
    expect((await target.productsDao.getBySku('00123'))!.stockQuantity, 0);

    // Second import: every order is recognised and skipped.
    final again = await tgtRepo.importOrdersReport(csv);
    expect((again.added, again.skipped), (0, 4));
    // And the source shop can take its own export back without doubling.
    final home = await srcRepo.importOrdersReport(csv);
    expect((home.added, home.skipped), (0, 4));
    // Nor does the target's own export double it.
    final back = await tgtRepo.importOrdersReport(await ordersFile.readAsString());
    expect((back.added, back.skipped), (0, 4));
    expect(await target.select(target.orders).get(), hasLength(4));
  });

  test('a file saved by a spreadsheet (LF, BOM, trailing newline) imports '
      'the same', () async {
    await source.productsDao.upsert(
        ProductsCompanion.insert(sku: '00123', name: 'चिया, "tea"', price: 1));
    await source.productsDao
        .upsert(ProductsCompanion.insert(sku: '0007', name: 'Bun', price: 2));
    final csv = await BackupRepository(source).productsCsv();
    final resaved = '﻿${csv.replaceAll('\r\n', '\n')}\n';

    expect(await BackupRepository(target).importProducts(await viaFile(resaved)), 2);
    expect(await BackupRepository(target).productsCsv(), csv);
  });
}
