import 'dart:io';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';

final backupRepositoryProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return BackupRepository(db);
});

class BackupRepository {
  BackupRepository(this._db);
  final AppDatabase _db;

  // ── Products Export ────────────────────────────────────────────────────────

  Future<void> exportProducts() async {
    final products = await (_db.select(_db.products)
          ..where((p) => p.isActive.equals(true)))
        .get();

    final categories = await _db.productsDao.getAllCategories();
    final categoryMap = {for (var c in categories) c.id: c.name};

    final List<List<dynamic>> rows = [
      [
        'SKU',
        'Name',
        'Price',
        'Category',
        'Stock',
        'Is Taxable',
        'Tax Rates',
        'Is Hidden',
        'Is Composite'
      ],
    ];

    for (final p in products) {
      final pTaxes = await _db.taxDao.getRatesForProduct(p.id);
      final taxNames = pTaxes.map((t) => t.name).join('|');

      rows.add([
        p.sku,
        p.name,
        p.price,
        categoryMap[p.categoryId] ?? 'Uncategorized',
        p.stockQuantity,
        p.isTaxable ? 1 : 0,
        taxNames,
        p.isHiddenInPos ? 1 : 0,
        p.isComposite ? 1 : 0,
      ]);
    }

    final csvString = const ListToCsvConverter().convert(rows);
    await _shareCsv(csvString, 'products_backup.csv');
  }

  // ── Products Import ────────────────────────────────────────────────────────

  Future<int> importProducts(String csvContent) async {
    final rows = const CsvToListConverter().convert(csvContent);
    if (rows.length <= 1) return 0;

    final header = rows[0].map((e) => e.toString().toLowerCase()).toList();
    final skuIdx = header.indexOf('sku');
    final nameIdx = header.indexOf('name');
    final priceIdx = header.indexOf('price');
    final catIdx = header.indexOf('category');
    final stockIdx = header.indexOf('stock');
    final taxableIdx = header.indexOf('is taxable');
    final taxesIdx = header.indexOf('tax rates');
    final hiddenIdx = header.indexOf('is hidden');
    final compositeIdx = header.indexOf('is composite');

    if (skuIdx == -1 || nameIdx == -1 || priceIdx == -1) {
      throw Exception('Missing required columns: SKU, Name, Price');
    }

    int count = 0;
    await _db.transaction(() async {
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 3) continue;

        final sku = row[skuIdx].toString();
        final name = row[nameIdx].toString();
        final price = double.tryParse(row[priceIdx].toString()) ?? 0.0;
        final catName = catIdx != -1 ? row[catIdx].toString() : 'Uncategorized';
        final stock =
            stockIdx != -1 ? int.tryParse(row[stockIdx].toString()) ?? 0 : 0;
        final isTaxable = taxableIdx != -1 ? _parseBool(row[taxableIdx]) : true;
        final taxNames =
            taxesIdx != -1 ? row[taxesIdx].toString().split('|') : <String>[];
        final isHidden = hiddenIdx != -1 ? _parseBool(row[hiddenIdx]) : false;
        final isComposite =
            compositeIdx != -1 ? _parseBool(row[compositeIdx]) : false;

        // 1. Handle Category
        int? catId;
        if (catName.isNotEmpty && catName != 'Uncategorized') {
          final existingCat = await (_db.select(_db.categories)
                ..where((c) => c.name.equals(catName)))
              .getSingleOrNull();
          if (existingCat != null) {
            catId = existingCat.id;
          } else {
            catId = await _db.productsDao
                .upsertCategory(CategoriesCompanion.insert(name: catName));
          }
        }

        // 2. Handle Product
        final productId = await _db.productsDao.upsert(ProductsCompanion.insert(
          sku: sku,
          name: name,
          price: price,
          categoryId: Value(catId),
          stockQuantity: Value(stock),
          isTaxable: Value(isTaxable),
          isHiddenInPos: Value(isHidden),
          isComposite: Value(isComposite),
          isActive: const Value(true),
        ));

        // 3. Handle Taxes
        if (taxNames.isNotEmpty) {
          final taxIds = <int>[];
          for (final tName in taxNames) {
            if (tName.trim().isEmpty) continue;
            final existingTax = await (_db.select(_db.taxRates)
                  ..where((t) => t.name.equals(tName.trim())))
                .getSingleOrNull();
            if (existingTax != null) {
              taxIds.add(existingTax.id);
            }
          }
          if (taxIds.isNotEmpty) {
            await _db.taxDao.setProductTaxes(productId, taxIds);
          }
        }

        count++;
      }
    });

    return count;
  }

  // ── Customers Export ───────────────────────────────────────────────────────

  Future<void> exportCustomers() async {
    final customers = await _db.customersDao.getAll();
    final List<List<dynamic>> rows = [
      ['Name', 'Phone', 'Email', 'Loyalty Points', 'Is Tax Exempt'],
    ];

    for (final c in customers) {
      rows.add([
        c.name,
        c.phone ?? '',
        c.email ?? '',
        c.loyaltyPoints,
        c.isTaxExempt ? 1 : 0,
      ]);
    }

    final csvString = const ListToCsvConverter().convert(rows);
    await _shareCsv(csvString, 'customers_backup.csv');
  }

  // ── Customers Import ───────────────────────────────────────────────────────

  Future<int> importCustomers(String csvContent) async {
    final rows = const CsvToListConverter().convert(csvContent);
    if (rows.length <= 1) return 0;

    final header = rows[0].map((e) => e.toString().toLowerCase()).toList();
    final nameIdx = header.indexOf('name');
    final phoneIdx = header.indexOf('phone');
    final emailIdx = header.indexOf('email');
    final pointsIdx = header.indexOf('loyalty points');
    final exemptIdx = header.indexOf('is tax exempt');

    if (nameIdx == -1) throw Exception('Missing required column: Name');

    int count = 0;
    await _db.transaction(() async {
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final name = row[nameIdx].toString();
        if (name.isEmpty) continue;

        final phone = phoneIdx != -1 ? row[phoneIdx].toString() : null;
        final email = emailIdx != -1 ? row[emailIdx].toString() : null;
        final points = pointsIdx != -1
            ? (double.tryParse(row[pointsIdx].toString()) ?? 0.0).toInt()
            : 0;
        final isExempt = exemptIdx != -1 ? _parseBool(row[exemptIdx]) : false;

        await _db.customersDao.upsert(CustomersCompanion.insert(
          name: name,
          phone: Value(phone),
          email: Value(email),
          loyaltyPoints: Value(points),
          isTaxExempt: Value(isExempt),
        ));
        count++;
      }
    });
    return count;
  }

  // ── Expenses Export ────────────────────────────────────────────────────────

  Future<void> exportExpenses() async {
    final expenses = await _db.expensesDao.getAll();
    final categories = await _db.expensesDao.getAllCategories();
    final categoryMap = {for (var c in categories) c.id: c.name};

    final List<List<dynamic>> rows = [
      [
        'Amount',
        'Date',
        'Category',
        'Notes',
        'Is Recurring',
        'Frequency',
        'Tax Deductible',
        'Status'
      ],
    ];

    for (final e in expenses) {
      rows.add([
        e.amount,
        e.date.toIso8601String(),
        categoryMap[e.categoryId] ?? 'General',
        e.notes ?? '',
        e.isRecurring ? 1 : 0,
        e.recurringFrequency ?? '',
        e.isTaxDeductible ? 1 : 0,
        e.status,
      ]);
    }

    final csvString = const ListToCsvConverter().convert(rows);
    await _shareCsv(csvString, 'expenses_backup.csv');
  }

  // ── Expenses Import ────────────────────────────────────────────────────────

  Future<int> importExpenses(String csvContent) async {
    final rows = const CsvToListConverter().convert(csvContent);
    if (rows.length <= 1) return 0;

    final header = rows[0].map((e) => e.toString().toLowerCase()).toList();
    final amountIdx = header.indexOf('amount');
    final dateIdx = header.indexOf('date');
    final catIdx = header.indexOf('category');
    final notesIdx = header.indexOf('notes');
    final recurIdx = header.indexOf('is recurring');
    final freqIdx = header.indexOf('frequency');
    final taxIdx = header.indexOf('tax deductible');
    final statusIdx = header.indexOf('status');

    if (amountIdx == -1 || dateIdx == -1) {
      throw Exception('Missing required columns: Amount, Date');
    }

    int count = 0;
    await _db.transaction(() async {
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 2) continue;

        final amount = double.tryParse(row[amountIdx].toString()) ?? 0.0;
        final date =
            DateTime.tryParse(row[dateIdx].toString()) ?? DateTime.now();
        final catName = catIdx != -1 ? row[catIdx].toString() : 'General';
        final notes = notesIdx != -1 ? row[notesIdx].toString() : null;
        final isRecurring = recurIdx != -1 ? _parseBool(row[recurIdx]) : false;
        final frequency = freqIdx != -1 ? row[freqIdx].toString() : null;
        final isTaxIdx = taxIdx != -1 ? _parseBool(row[taxIdx]) : false;
        final status = statusIdx != -1 ? row[statusIdx].toString() : 'approved';

        // 1. Handle Category
        int catId;
        final existingCat = await (_db.select(_db.expenseCategories)
              ..where((c) => c.name.equals(catName)))
            .getSingleOrNull();
        if (existingCat != null) {
          catId = existingCat.id;
        } else {
          catId = await _db.expensesDao
              .upsertCategory(ExpenseCategoriesCompanion.insert(name: catName));
        }

        // 2. Insert Expense (ID is auto-inc, so this is always a new record)
        await _db.expensesDao.insert(ExpensesCompanion.insert(
          amount: amount,
          date: date,
          categoryId: catId,
          notes: Value(notes),
          isRecurring: Value(isRecurring),
          recurringFrequency: Value(frequency),
          isTaxDeductible: Value(isTaxIdx),
          status: Value(status),
        ));

        count++;
      }
    });

    return count;
  }

  // ── Orders Export ─────────────────────────────────────────────────────────

  Future<void> exportOrders() async {
    final data = await _db.ordersDao.getAllOrdersWithItems();
    final List<List<dynamic>> rows = [
      [
        'Order ID',
        'Status',
        'Subtotal',
        'Tax Total',
        'Discount',
        'Total',
        'Payment Method',
        'Tendered',
        'Change',
        'Customer Name',
        'Notes',
        'Created At',
        'Item Product ID',
        'Item Name',
        'Item SKU',
        'Item Price',
        'Item Qty',
        'Item Discount',
        'Item Tax',
        'Item Total'
      ],
    ];

    for (final row in data) {
      // Get SKU if possible (though we have name as snapshot)
      // Note: productId might be null if product was deleted but order remains
      String sku = '';
      final productId = row.read<int?>('product_id');
      if (productId != null) {
        final p = await (_db.select(_db.products)
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

    final csvString = const ListToCsvConverter().convert(rows);
    await _shareCsv(csvString, 'order_history_backup.csv');
  }

  // ── Orders Import ──────────────────────────────────────────────────────────

  Future<int> importOrders(String csvContent) async {
    final rows = const CsvToListConverter().convert(csvContent);
    if (rows.length <= 1) return 0;

    final header = rows[0].map((e) => e.toString().toLowerCase()).toList();
    final oIdIdx = header.indexOf('order id');
    final statusIdx = header.indexOf('status');
    final totalIdx = header.indexOf('total');
    final methodIdx = header.indexOf('payment method');
    final customerIdx = header.indexOf('customer name');
    final dateIdx = header.indexOf('created at');

    final itemNameIdx = header.indexOf('item name');
    final itemSkuIdx = header.indexOf('item sku');
    final itemPriceIdx = header.indexOf('item price');
    final itemQtyIdx = header.indexOf('item qty');
    final itemTotalIdx = header.indexOf('item total');

    if (oIdIdx == -1 || dateIdx == -1 || itemNameIdx == -1) {
      throw Exception(
          'Format invalid. Missing required columns (Order ID, Created At, Item Name)');
    }

    // Group rows by Order ID to reconstruct orders
    final Map<String, List<List<dynamic>>> orderGroups = {};
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final key = row[oIdIdx].toString();
      orderGroups.putIfAbsent(key, () => []).add(row);
    }

    int count = 0;
    await _db.transaction(() async {
      for (final oId in orderGroups.keys) {
        final group = orderGroups[oId]!;
        final first = group.first;

        // 1. Find/Match Customer
        int? customerId;
        final cName = first[customerIdx].toString();
        if (cName.isNotEmpty) {
          final existing = await (_db.select(_db.customers)
                ..where((c) => c.name.equals(cName)))
              .getSingleOrNull();
          customerId = existing?.id;
        }

        // 2. Insert Order
        final orderId = await _db.ordersDao.insertOrder(OrdersCompanion.insert(
          status: Value(first[statusIdx].toString()),
          subtotal:
              double.tryParse(first[header.indexOf('subtotal')].toString()) ??
                  0.0,
          taxTotal: Value(
              double.tryParse(first[header.indexOf('tax total')].toString()) ??
                  0.0),
          discountTotal: Value(
              double.tryParse(first[header.indexOf('discount')].toString()) ??
                  0.0),
          total: double.tryParse(first[totalIdx].toString()) ?? 0.0,
          paymentMethod: first[methodIdx].toString(),
          tenderedAmount: Value(
              double.tryParse(first[header.indexOf('tendered')].toString()) ??
                  0.0),
          changeAmount: Value(
              double.tryParse(first[header.indexOf('change')].toString()) ??
                  0.0),
          customerId: Value(customerId),
          notes: Value(first[header.indexOf('notes')].toString()),
          createdAt: Value(
              DateTime.tryParse(first[dateIdx].toString()) ?? DateTime.now()),
        ));

        // 3. Insert Items
        final items = <OrderItemsCompanion>[];
        for (final row in group) {
          // Attempt to match product by SKU or Name to get ID
          int? productId;
          final sku = row[itemSkuIdx].toString();
          final name = row[itemNameIdx].toString();

          if (sku.isNotEmpty) {
            final p = await (_db.select(_db.products)
                  ..where((p) => p.sku.equals(sku)))
                .getSingleOrNull();
            productId = p?.id;
          }
          if (productId == null && name.isNotEmpty) {
            final p = await (_db.select(_db.products)
                  ..where((p) => p.name.equals(name)))
                .getSingleOrNull();
            productId = p?.id;
          }

          if (productId == null)
            continue; // Skip if product doesn't exist? Or allow null?

          items.add(OrderItemsCompanion.insert(
            orderId: orderId,
            productId: productId,
            productName: name,
            unitPrice: double.tryParse(row[itemPriceIdx].toString()) ?? 0.0,
            quantity: int.tryParse(row[itemQtyIdx].toString()) ?? 1,
            discount: Value(double.tryParse(
                    row[header.indexOf('item discount')].toString()) ??
                0.0),
            taxAmount: Value(
                double.tryParse(row[header.indexOf('item tax')].toString()) ??
                    0.0),
            lineTotal: double.tryParse(row[itemTotalIdx].toString()) ?? 0.0,
          ));
        }

        if (items.isNotEmpty) {
          await _db.ordersDao.insertItems(items);
        }
        count++;
      }
    });

    return count;
  }

  // ── Sales Report Export ────────────────────────────────────────────────────

  Future<void> exportSalesReport() async {
    final data = await _db.ordersDao.getAllOrdersWithItems();
    final List<List<dynamic>> rows = [
      [
        'Date',
        'Order ID',
        'Item',
        'Qty',
        'Unit Price',
        'Line Total',
        'Payment',
        'Customer',
        'Status'
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

    final csvString = const ListToCsvConverter().convert(rows);
    await _shareCsv(csvString, 'sales_report.csv');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    final s = value.toString().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _shareCsv(String content, String fileName) async {
    final directory = await getTemporaryDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final filePath = p.join(directory.path, fileName);
    final file = File(filePath);
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path)], text: 'POS Data Backup');
  }
}
