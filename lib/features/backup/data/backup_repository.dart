import 'dart:io';
import 'dart:ui' show Rect;
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/tables/orders_table.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/backup/data/csv_text.dart';
import 'package:pos_app/features/backup/data/share_files.dart';

final backupRepositoryProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return BackupRepository(db, share: ref.watch(shareFilesProvider));
});

/// What each CSV import does to records that are already here, as the
/// import screen tells it before the file is picked.
const csvImportExplanation = (
  products: 'Each row is matched to a product by SKU, or by exact name when '
      'the row has no SKU. A matching product is updated in place with the '
      "file's name, price, category, stock and flags, and a deleted product "
      'is restored. Rows with no match are added as new products.\n\n'
      'Importing the same file again creates no duplicates; it sets the '
      "file's values again.",
  customers: 'Each row is matched to a customer by phone number, or by exact '
      'name and email when the row has no phone. A matching customer is '
      "updated in place, including their loyalty points, with the file's "
      'values. Rows with no match are added as new customers.\n\n'
      'Importing the same file again creates no duplicates; it sets the '
      "file's values again.",
  expenses: 'Every row is added as a new expense. Expense files carry no '
      'identifier, so nothing is matched or updated: importing a file that '
      'was imported before records every expense in it a second time.',
  orders: 'Orders already in this database (same Order ID, date and total) '
      'are skipped, so importing the same file again adds nothing. The rest '
      'are added as new orders numbered IMP-<Order ID>, separate from your own '
      'invoice numbers. Stock and loyalty points are not changed.\n\n'
      'Import Products and Customers first: an order line whose product is '
      'not found by SKU or name is left out and listed in the order notes.',
);

/// What a CSV import did.
class CsvImportReport {
  const CsvImportReport({
    this.added = 0,
    this.updated = 0,
    this.skipped = 0,
    this.unmatchedLines = 0,
  });

  /// Rows that became new records.
  final int added;

  /// Rows that matched an existing record, which now holds the file's values.
  final int updated;

  /// Rows left alone: orders already present, rows with no name.
  final int skipped;

  /// Order lines left out because their product is not in this database.
  final int unmatchedLines;

  /// Records written to the database.
  int get written => added + updated;

  /// One line for the cashier, e.g. `Products: 3 added, 5 updated`.
  String summary(String noun) {
    final parts = [
      if (added > 0 || written + skipped == 0) '$added added',
      if (updated > 0) '$updated updated',
      if (skipped > 0)
        noun == 'orders'
            ? '$skipped already here (skipped)'
            : '$skipped skipped',
    ];
    final title = '${noun[0].toUpperCase()}${noun.substring(1)}';
    final lines = unmatchedLines == 1 ? '1 line' : '$unmatchedLines lines';
    return '$title: ${parts.join(', ')}'
        '${unmatchedLines > 0 ? '. $lines left out: product not found (see order notes)' : ''}';
  }
}

class BackupRepository {
  BackupRepository(
    this._db, {
    ShareFiles share = shareFilesWithOs,
    Future<Directory> Function() tempDirectory = getTemporaryDirectory,
  })  : _share = share,
        _tempDirectory = tempDirectory;
  final AppDatabase _db;
  final ShareFiles _share;
  final Future<Directory> Function() _tempDirectory;

  // Every export takes a `shareOrigin`: the on-screen rectangle of the tile
  // that was tapped. iPad anchors the share sheet to it and share_plus fails
  // the share without one.

  // ── Products Export ────────────────────────────────────────────────────────

  Future<void> exportProducts({required Rect shareOrigin}) async =>
      _shareCsv(await productsCsv(), 'products_backup.csv', shareOrigin);

  /// The products CSV: one row per active product.
  @visibleForTesting
  Future<String> productsCsv() async {
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

    return const ListToCsvConverter().convert(rows);
  }

  // ── Products Import ────────────────────────────────────────────────────────

  /// Number of products added or updated. See [importProductsReport].
  Future<int> importProducts(String csvContent) async =>
      (await importProductsReport(csvContent)).written;

  /// Adds or updates products from a products CSV.
  ///
  /// A row is matched to an existing product — active, hidden or deleted —
  /// by SKU when it has one, otherwise by exact name. A match is updated in
  /// place, keeping its id (orders and stock history point at it), and is
  /// made active again if it had been deleted. Only columns the file has are
  /// written; a blank cell leaves the product's value alone. Rows without a
  /// match are added, with a generated SKU when the row has none.
  ///
  /// A row with no SKU whose name fits several products is refused rather
  /// than guessed at. Any error rolls the whole import back.
  Future<CsvImportReport> importProductsReport(String csvContent) async {
    final table = CsvTable.parse(csvContent);
    if (table.rows.isEmpty) return const CsvImportReport();
    table.require(['SKU', 'Name', 'Price']);

    var added = 0, updated = 0, skipped = 0;
    await _db.transaction(() async {
      for (final row in table.rows) {
        if (row.isBlank) continue;

        final sku = row.text('sku');
        final name = row.text('name');
        final price = row.numberOf('price');
        final stock = row.intOf('stock');
        final isTaxable = row.boolOf('is taxable');
        final isHidden = row.boolOf('is hidden');
        final isComposite = row.boolOf('is composite');

        // 1. Category. 'Uncategorized' is how the export writes "none".
        final catName = row.text('category');
        final noCategory = catName == 'Uncategorized';
        int? catId;
        if (catName.isNotEmpty && !noCategory) {
          final existingCat = await (_db.select(_db.categories)
                ..where((c) => c.name.equals(catName))
                ..orderBy([(c) => OrderingTerm.asc(c.id)])
                ..limit(1))
              .getSingleOrNull();
          catId = existingCat?.id ??
              await _db.productsDao
                  .upsertCategory(CategoriesCompanion.insert(name: catName));
        }

        // 2. Product: update the match, or add.
        final existing = await _matchProduct(row, sku: sku, name: name);
        final int productId;
        if (existing != null) {
          productId = existing.id;
          await _db.productsDao.updateProduct(
            existing.id,
            ProductsCompanion(
              name: name.isEmpty ? const Value.absent() : Value(name),
              price: Value.absentIfNull(price),
              categoryId: catId != null
                  ? Value(catId)
                  : (noCategory ? const Value(null) : const Value.absent()),
              stockQuantity: Value.absentIfNull(stock),
              isTaxable: Value.absentIfNull(isTaxable),
              isHiddenInPos: Value.absentIfNull(isHidden),
              isComposite: Value.absentIfNull(isComposite),
              isActive: const Value(true),
              updatedAt: Value(DateTime.now()),
            ),
          );
          if (stock != null && stock != existing.stockQuantity) {
            await _db.inventoryDao.logAdjustment(
              StockAdjustmentsCompanion.insert(
                productId: existing.id,
                delta: stock - existing.stockQuantity,
                reasonCode: 'count',
                notes: const Value('CSV import'),
              ),
            );
          }
          updated++;
        } else if (name.isEmpty) {
          skipped++; // nothing to match and nothing to call it
          continue;
        } else {
          productId = await _db.into(_db.products).insert(
                ProductsCompanion.insert(
                  sku: sku.isEmpty ? await _newSku() : sku,
                  name: name,
                  price: price ?? 0.0,
                  categoryId: Value(catId),
                  stockQuantity: Value(stock ?? 0),
                  isTaxable: Value(isTaxable ?? true),
                  isHiddenInPos: Value(isHidden ?? false),
                  isComposite: Value(isComposite ?? false),
                ),
              );
          added++;
        }

        // 3. Taxes: only rates that already exist here, matched by name.
        final taxIds = <int>[];
        for (final tName in row.text('tax rates').split('|')) {
          if (tName.trim().isEmpty) continue;
          final existingTax = await (_db.select(_db.taxRates)
                ..where((t) => t.name.equals(tName.trim()))
                ..orderBy([(t) => OrderingTerm.asc(t.id)])
                ..limit(1))
              .getSingleOrNull();
          if (existingTax != null) taxIds.add(existingTax.id);
        }
        if (taxIds.isNotEmpty) {
          await _db.taxDao.setProductTaxes(productId, taxIds);
        }
      }
    });

    return CsvImportReport(added: added, updated: updated, skipped: skipped);
  }

  /// The product a products-CSV row refers to, if it exists already.
  Future<Product?> _matchProduct(
    CsvRow row, {
    required String sku,
    required String name,
  }) async {
    if (sku.isNotEmpty) return _db.productsDao.getBySku(sku);
    if (name.isEmpty) return null;
    final sameName = await (_db.select(_db.products)
          ..where((p) => p.name.equals(name)))
        .get();
    if (sameName.length <= 1) return sameName.firstOrNull;
    // Several share the name. One live product among deleted ones is
    // unambiguous; anything else would be a guess.
    final active = sameName.where((p) => p.isActive).toList();
    if (active.length == 1) return active.single;
    throw row.error(
        '"$name" has no SKU and ${sameName.length} products have that '
        'name. Add the SKU so the right one is updated');
  }

  /// A SKU for a row that came without one, as the product form makes them.
  Future<String> _newSku() async {
    while (true) {
      final sku = const Uuid().v4().substring(0, 8).toUpperCase();
      if (await _db.productsDao.getBySku(sku) == null) return sku;
    }
  }

  // ── Customers Export ───────────────────────────────────────────────────────

  Future<void> exportCustomers({required Rect shareOrigin}) async =>
      _shareCsv(await customersCsv(), 'customers_backup.csv', shareOrigin);

  /// The customers CSV: one row per customer.
  @visibleForTesting
  Future<String> customersCsv() async {
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

    return const ListToCsvConverter().convert(rows);
  }

  // ── Customers Import ───────────────────────────────────────────────────────

  /// Number of customers added or updated. See [importCustomersReport].
  Future<int> importCustomers(String csvContent) async =>
      (await importCustomersReport(csvContent)).written;

  /// Adds or updates customers from a customers CSV.
  ///
  /// A row with a phone number is matched to the customer with that exact
  /// phone: the one with the row's name if several share the number, or the
  /// only one (whose name the row then replaces). A row with no phone is
  /// matched on exact name plus email. A match is updated in place —
  /// including its loyalty points, when the file has that column — and a
  /// blank cell leaves the customer's value alone. Rows without a match are
  /// added.
  ///
  /// No customer is matched by two rows of one file, so a file listing two
  /// people on one phone, or the same name twice, yields two customers.
  Future<CsvImportReport> importCustomersReport(String csvContent) async {
    final table = CsvTable.parse(csvContent);
    if (table.rows.isEmpty) return const CsvImportReport();
    table.require(['Name']);

    var added = 0, updated = 0, skipped = 0;
    final written = <int>{}; // customers this file has already produced
    await _db.transaction(() async {
      for (final row in table.rows) {
        if (row.isBlank) continue;
        final name = row.text('name');
        if (name.isEmpty) {
          skipped++;
          continue;
        }

        final phone = row.textOrNull('phone');
        final email = row.textOrNull('email');
        // Whole points; a spreadsheet may have written 12.0.
        final points = row.numberOf('loyalty points')?.toInt();
        final isExempt = row.boolOf('is tax exempt');

        final existing = await _matchCustomer(
            name: name, phone: phone, email: email, taken: written);
        if (existing != null) {
          written.add(existing.id);
          await (_db.update(_db.customers)
                ..where((c) => c.id.equals(existing.id)))
              .write(CustomersCompanion(
            name: Value(name),
            phone: Value.absentIfNull(phone),
            email: Value.absentIfNull(email),
            loyaltyPoints: Value.absentIfNull(points),
            isTaxExempt: Value.absentIfNull(isExempt),
            updatedAt: Value(DateTime.now()),
          ));
          updated++;
        } else {
          written.add(
              await _db.into(_db.customers).insert(CustomersCompanion.insert(
                    name: name,
                    phone: Value(phone),
                    email: Value(email),
                    loyaltyPoints: Value(points ?? 0),
                    isTaxExempt: Value(isExempt ?? false),
                  )));
          added++;
        }
      }
    });
    return CsvImportReport(added: added, updated: updated, skipped: skipped);
  }

  /// The customer a customers-CSV row refers to, if they exist already.
  /// Customers in [taken] were matched by an earlier row of the same file.
  Future<Customer?> _matchCustomer({
    required String name,
    required String? phone,
    required String? email,
    required Set<int> taken,
  }) async {
    if (phone != null) {
      final samePhone = await (_db.select(_db.customers)
            ..where((c) => c.phone.equals(phone))
            ..orderBy([(c) => OrderingTerm.asc(c.id)]))
          .get();
      final free = samePhone.where((c) => !taken.contains(c.id)).toList();
      final sameName = free.where((c) => c.name == name).firstOrNull;
      if (sameName != null) return sameName;
      // One customer on this number under another name: the same person,
      // renamed. Several (a household, a business): one more person.
      return samePhone.length == 1 && free.length == 1 ? free.single : null;
    }
    final sameName = await (_db.select(_db.customers)
          ..where((c) => c.name.equals(name))
          ..orderBy([(c) => OrderingTerm.asc(c.id)]))
        .get();
    return sameName
        .where((c) =>
            !taken.contains(c.id) && (c.email ?? '').trim() == (email ?? ''))
        .firstOrNull;
  }

  // ── Expenses Export ────────────────────────────────────────────────────────

  Future<void> exportExpenses({required Rect shareOrigin}) async =>
      _shareCsv(await expensesCsv(), 'expenses_backup.csv', shareOrigin);

  /// The expenses CSV: one row per expense. It carries no id.
  @visibleForTesting
  Future<String> expensesCsv() async {
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

    return const ListToCsvConverter().convert(rows);
  }

  // ── Expenses Import ────────────────────────────────────────────────────────

  /// Number of expenses added. See [importExpensesReport].
  Future<int> importExpenses(String csvContent) async =>
      (await importExpensesReport(csvContent)).written;

  /// Adds every row of an expenses CSV as a new expense.
  ///
  /// The file has no id or other stable key, and two expenses of the same
  /// amount, day and category are ordinary, so rows are never matched to
  /// existing expenses: importing a file twice records its expenses twice.
  Future<CsvImportReport> importExpensesReport(String csvContent) async {
    final table = CsvTable.parse(csvContent);
    if (table.rows.isEmpty) return const CsvImportReport();
    table.require(['Amount', 'Date']);

    var added = 0;
    await _db.transaction(() async {
      for (final row in table.rows) {
        if (row.isBlank) continue;

        final amount = row.numberOf('amount');
        if (amount == null) throw row.error('Amount is blank');
        final date = row.dateOf('date');
        if (date == null) throw row.error('Date is blank');
        final catName = row.textOrNull('category') ?? 'General';

        // 1. Category
        final existingCat = await (_db.select(_db.expenseCategories)
              ..where((c) => c.name.equals(catName))
              ..orderBy([(c) => OrderingTerm.asc(c.id)])
              ..limit(1))
            .getSingleOrNull();
        final catId = existingCat?.id ??
            await _db.expensesDao.upsertCategory(
                ExpenseCategoriesCompanion.insert(name: catName));

        // 2. Always a new record.
        await _db.expensesDao.insert(ExpensesCompanion.insert(
          amount: amount,
          date: date,
          categoryId: catId,
          notes: Value(row.textOrNull('notes')),
          isRecurring: Value(row.boolOf('is recurring') ?? false),
          recurringFrequency: Value(row.textOrNull('frequency')),
          isTaxDeductible: Value(row.boolOf('tax deductible') ?? false),
          status: Value(row.textOrNull('status') ?? 'approved'),
        ));
        added++;
      }
    });

    return CsvImportReport(added: added);
  }

  // ── Orders Export ─────────────────────────────────────────────────────────

  static const _ordersCsvHeader = <dynamic>[
    'Order ID',
    'Status',
    'Subtotal',
    'Tax Total',
    'Discount',
    'Total',
    'Tip',
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
  ];

  Future<void> exportOrders({required Rect shareOrigin}) async {
    final file = await _tempFile('order_history_backup.csv');
    await writeOrdersCsv(file);
    await _shareFile(file, shareOrigin);
  }

  /// Writes the whole order history to [file] as CSV, one row per order
  /// line, newest order first. Reads [pageSize] orders at a time and appends
  /// each page to the file, so memory stays flat however long the history.
  @visibleForTesting
  Future<void> writeOrdersCsv(File file, {int pageSize = 500}) =>
      _writeOrderLinesCsv(
        file,
        header: _ordersCsvHeader,
        pageSize: pageSize,
        toCsvRow: (row) {
          // product_id is NULL only on the placeholder row of an order that
          // has no lines; the SKU is the product's current one.
          final productId = row.read<int?>('product_id');
          return [
            row.read<int>('o_id'),
            row.read<String>('status'),
            row.read<double>('o_subtotal'),
            row.read<double>('tax_total'),
            row.read<double>('o_discount'),
            row.read<double>('o_total'),
            row.read<double>('o_tip'),
            row.read<String>('payment_method'),
            row.read<double?>('tendered_amount') ?? 0.0,
            row.read<double?>('change_amount') ?? 0.0,
            row.read<String?>('customer_name') ?? '',
            row.read<String?>('notes') ?? '',
            row.read<DateTime>('created_at').toIso8601String(),
            productId ?? '',
            row.read<String?>('product_name') ?? '',
            row.read<String?>('product_sku') ?? '',
            row.read<double?>('unit_price') ?? 0.0,
            row.read<int?>('quantity') ?? 0,
            row.read<double?>('item_discount') ?? 0.0,
            row.read<double?>('item_tax') ?? 0.0,
            row.read<double?>('line_total') ?? 0.0,
          ];
        },
      );

  /// Streams `OrdersDao.ordersWithItemsPage` into [file]: header first, then
  /// each page as it is read. The bytes are exactly what
  /// `ListToCsvConverter().convert([header, ...allRows])` would produce.
  Future<void> _writeOrderLinesCsv(
    File file, {
    required List<dynamic> header,
    required List<dynamic> Function(QueryRow row) toCsvRow,
    required int pageSize,
  }) async {
    const csv = ListToCsvConverter();
    final sink = file.openWrite();
    try {
      sink.write(csv.convert([header]));
      ({DateTime createdAt, int id})? cursor;
      while (true) {
        final page = await _db.ordersDao
            .ordersWithItemsPage(before: cursor, limit: pageSize);
        if (page.isEmpty) break;
        sink
          ..write(_csvEol)
          ..write(csv.convert([for (final row in page) toCsvRow(row)]));
        await sink.flush();
        cursor = (
          createdAt: page.last.read<DateTime>('created_at'),
          id: page.last.read<int>('o_id'),
        );
      }
    } finally {
      await sink.close();
    }
  }

  /// Row separator of [ListToCsvConverter] (its default).
  static const _csvEol = '\r\n';

  // ── Orders Import ──────────────────────────────────────────────────────────

  /// Invoice prefix carried by every order that came from a CSV file. Bill
  /// numbers are `prefix-number`, so these read `IMP-17` and can never be
  /// taken for the shop's own invoice `#17`. Invoice sequences run per
  /// prefix, so imports never advance a real one.
  static const importedOrderPrefix = kImportedInvoicePrefix;

  /// Number of orders added. See [importOrdersReport].
  Future<int> importOrders(String csvContent) async =>
      (await importOrdersReport(csvContent)).written;

  /// Adds the orders of an order-history CSV (one row per order line; rows
  /// sharing an Order ID are one order).
  ///
  /// **Already present → skipped.** An order is taken to be here already
  /// when an order with the file's Order ID — as its own id, or as the
  /// number it was imported under — also has the same date and total. So
  /// re-importing a file, or importing a shop's export back into that shop,
  /// adds nothing.
  ///
  /// **Numbering.** Imported orders get prefix [importedOrderPrefix] and the
  /// file's Order ID as their number (`IMP-17`). If that number is taken by
  /// a different imported order (files from two shops), the order gets no
  /// number and shows as `IMP-<its row id>`.
  ///
  /// **Lines.** A line is tied to a product by SKU, else by name. A line
  /// whose product cannot be found is left out — an order line must point
  /// at a product — and the order's notes say which, since its total still
  /// includes it. Stock, loyalty points and tax lines are not touched.
  Future<CsvImportReport> importOrdersReport(String csvContent) async {
    final table = CsvTable.parse(csvContent);
    if (table.rows.isEmpty) return const CsvImportReport();
    table.require(['Order ID', 'Created At', 'Item Name', 'Total']);

    // Group rows by Order ID to reconstruct orders (file order kept).
    final orderGroups = <String, List<CsvRow>>{};
    for (final row in table.rows) {
      if (row.isBlank) continue;
      final key = row.text('order id');
      if (key.isEmpty) throw row.error('Order ID is blank');
      orderGroups.putIfAbsent(key, () => []).add(row);
    }

    var added = 0, skipped = 0, unmatchedLines = 0;
    await _db.transaction(() async {
      for (final MapEntry(key: fileId, value: group) in orderGroups.entries) {
        final first = group.first;

        final createdAt = first.dateOf('created at');
        if (createdAt == null) throw first.error('Created At is blank');
        final total = first.numberOf('total');
        if (total == null) throw first.error('Total is blank');

        // 1. Already here?
        final sourceId = int.tryParse(fileId);
        var invoiceNo = sourceId;
        if (sourceId != null) {
          bool sameSale(Order o) =>
              o.createdAt.difference(createdAt).inSeconds == 0 &&
              (o.total - total).abs() < 0.005;

          final own = await _db.ordersDao.getById(sourceId);
          final imported = await (_db.select(_db.orders)
                ..where((o) =>
                    o.invoicePrefix.equals(importedOrderPrefix) &
                    o.invoiceNo.equals(sourceId)))
              .getSingleOrNull();
          if ((own != null && sameSale(own)) ||
              (imported != null && sameSale(imported))) {
            skipped++;
            continue;
          }
          // IMP-<n> belongs to a different sale: go without a number.
          if (imported != null) invoiceNo = null;
        }

        // 2. Customer, by exact name — only when exactly one has it.
        int? customerId;
        final cName = first.text('customer name');
        if (cName.isNotEmpty) {
          final matches = await (_db.select(_db.customers)
                ..where((c) => c.name.equals(cName))
                ..limit(2))
              .get();
          if (matches.length == 1) customerId = matches.single.id;
        }

        // 3. Payment. The export writes 0 where nothing was recorded, so a
        // zero that cannot be a real cash payment is read back as "none".
        // Lower-cased so 'Cash' and 'cash' are one method; blank reads as
        // cash, as before.
        final method =
            first.textOrNull('payment method')?.toLowerCase() ?? 'cash';
        var tendered = first.numberOf('tendered');
        var change = first.numberOf('change');
        final nothingTendered = tendered == null ||
            (tendered == 0 && (method != 'cash' || total > 0));
        if (nothingTendered) tendered = change = null;

        // 4. Lines.
        final items = <OrderItemsCompanion Function(int orderId)>[];
        final leftOut = <String>[];
        for (final row in group) {
          final sku = row.text('item sku');
          final name = row.text('item name');
          // An order with no lines is exported as one row with no item.
          if (sku.isEmpty && name.isEmpty) continue;

          final unitPrice = row.numberOf('item price') ?? 0.0;
          final quantity = row.intOf('item qty') ?? 1;
          final discount = row.numberOf('item discount') ?? 0.0;
          final taxAmount = row.numberOf('item tax') ?? 0.0;
          final lineTotal =
              row.numberOf('item total') ?? unitPrice * quantity - discount;

          final productId = await _matchOrderLineProduct(sku: sku, name: name);
          if (productId == null) {
            leftOut.add('${name.isEmpty ? sku : name} ×$quantity = '
                '${lineTotal.toStringAsFixed(2)}');
            continue;
          }
          items.add((orderId) => OrderItemsCompanion.insert(
                orderId: orderId,
                productId: productId,
                productName: name.isEmpty ? sku : name,
                unitPrice: unitPrice,
                quantity: quantity,
                discount: Value(discount),
                taxAmount: Value(taxAmount),
                lineTotal: lineTotal,
              ));
        }

        var notes = first.textOrNull('notes');
        if (leftOut.isNotEmpty) {
          unmatchedLines += leftOut.length;
          final lines = leftOut.length == 1 ? '1 line' : '${leftOut.length} lines';
          notes = [
            if (notes != null) notes,
            'CSV import: $lines left out, product not found — '
                '${leftOut.join('; ')}',
          ].join('\n');
        }

        // 5. Insert.
        final orderId = await _db.ordersDao.insertOrder(OrdersCompanion.insert(
          invoiceNo: Value(invoiceNo),
          invoicePrefix: const Value(importedOrderPrefix),
          status: Value(first.textOrNull('status') ?? 'completed'),
          subtotal: first.numberOf('subtotal') ?? total,
          taxTotal: Value(first.numberOf('tax total') ?? 0.0),
          discountTotal: Value(first.numberOf('discount') ?? 0.0),
          total: total,
          // Older exports have no Tip column: no tip.
          tipAmount: Value(
              (first.numberOf('tip') ?? 0.0).clamp(0.0, double.infinity)),
          paymentMethod: method,
          tenderedAmount: Value(tendered),
          changeAmount: Value(change),
          customerId: Value(customerId),
          notes: Value(notes),
          createdAt: Value(createdAt),
        ));
        if (items.isNotEmpty) {
          await _db.ordersDao
              .insertItems([for (final item in items) item(orderId)]);
        }
        added++;
      }
    });

    return CsvImportReport(
        added: added, skipped: skipped, unmatchedLines: unmatchedLines);
  }

  /// The product an order line was a sale of: by SKU (deleted products
  /// included — old sales still point at them), else by name when the name
  /// picks out one product.
  Future<int?> _matchOrderLineProduct({
    required String sku,
    required String name,
  }) async {
    if (sku.isNotEmpty) {
      final bySku = await _db.productsDao.getBySku(sku);
      if (bySku != null) return bySku.id;
    }
    if (name.isEmpty) return null;
    final sameName = await (_db.select(_db.products)
          ..where((p) => p.name.equals(name)))
        .get();
    if (sameName.length == 1) return sameName.single.id;
    final active = sameName.where((p) => p.isActive).toList();
    return active.length == 1 ? active.single.id : null;
  }

  // ── Sales Report Export ────────────────────────────────────────────────────

  Future<void> exportSalesReport({required Rect shareOrigin}) async {
    final file = await _tempFile('sales_report.csv');
    await writeSalesReportCsv(file);
    await _shareFile(file, shareOrigin);
  }

  /// Same paged, flat-memory write as [writeOrdersCsv].
  @visibleForTesting
  Future<void> writeSalesReportCsv(File file, {int pageSize = 500}) =>
      _writeOrderLinesCsv(
        file,
        header: const [
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
        pageSize: pageSize,
        toCsvRow: (row) => [
          row.read<DateTime>('created_at').toIso8601String().split('T')[0],
          row.read<int>('o_id'),
          row.read<String?>('product_name') ?? 'Unknown',
          row.read<int?>('quantity') ?? 0,
          row.read<double?>('unit_price') ?? 0.0,
          row.read<double?>('line_total') ?? 0.0,
          row.read<String>('payment_method'),
          row.read<String?>('customer_name') ?? 'Walk-in',
          row.read<String>('status'),
        ],
      );

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<File> _tempFile(String fileName) async {
    final directory = await _tempDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File(p.join(directory.path, fileName));
  }

  Future<void> _shareFile(File file, Rect shareOrigin) => _share(
        [XFile(file.path)],
        text: 'POS Data Backup',
        sharePositionOrigin: shareOrigin,
      );

  Future<void> _shareCsv(
      String content, String fileName, Rect shareOrigin) async {
    final file = await _tempFile(fileName);
    await file.writeAsString(content);
    await _shareFile(file, shareOrigin);
  }
}
