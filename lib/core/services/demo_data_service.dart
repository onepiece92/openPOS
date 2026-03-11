import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';

class DemoDataService {
  DemoDataService(this._db);
  final AppDatabase _db;

  Future<void> seed() async {
    // ── Categories ────────────────────────────────────────────────────────
    final catIds = <String, int>{};
    final catRows = [
      ('Croissants & Pastries', 0),
      ('Eclairs', 1),
      ('Tarts & Pies', 2),
      ('Breads & Buns', 3),
      ('Savouries', 4),
      ('Cakes & Sweets', 5),
    ];
    for (final (name, sort) in catRows) {
      catIds[name] = await _db.productsDao.upsertCategory(
        CategoriesCompanion.insert(name: name, sortOrder: Value(sort)),
      );
    }

    // ── Products ──────────────────────────────────────────────────────────
    // (sku, name, price, stock, category)
    final productRows = [
      // Croissants & Pastries
      ('CRO001', 'Butter Croissant',       120.0, 10,'Croissants & Pastries'),
      ('CRO002', 'Almond Croissant',       175.0, 10,'Croissants & Pastries'),
      ('CRO003', 'Croissant',              225.0, 10,'Croissants & Pastries'),
      ('CRO004', 'Small Croissant',        100.0, 10,'Croissants & Pastries'),
      ('CRO005', 'Small Frozen Croissant',  80.0, 10,'Croissants & Pastries'),
      ('CRO006', 'Pain au Chocolat',       135.0, 10,'Croissants & Pastries'),
      // Eclairs
      ('ECL001', 'Chocolate Eclair',  100.0, 10,'Eclairs'),
      ('ECL002', 'Vanilla Eclair',    100.0, 10,'Eclairs'),
      ('ECL003', 'Banana Eclair',     125.0, 10,'Eclairs'),
      ('ECL004', 'Blueberry Eclair',  100.0, 10,'Eclairs'),
      ('ECL005', 'Flavoured Eclair',  100.0, 10,'Eclairs'),
      // Tarts & Pies
      ('TAR001', 'Fruit Tart',                125.0, 10,'Tarts & Pies'),
      ('TAR002', 'Apple Tart',                125.0, 10,'Tarts & Pies'),
      ('TAR003', 'Almond Chocolate Tart',     125.0, 10,'Tarts & Pies'),
      ('TAR004', 'Almond Blackcurrant Tart',  125.0, 10,'Tarts & Pies'),
      ('TAR005', 'Almond Apple Tart',         125.0, 10,'Tarts & Pies'),
      ('TAR006', 'Almond Blueberry Tart',     125.0, 10,'Tarts & Pies'),
      ('TAR007', 'Custard Pie',               125.0, 10,'Tarts & Pies'),
      ('TAR008', 'Apple Crumble Pie',         125.0, 10,'Tarts & Pies'),
      ('TAR009', 'Strawberry Pie',            150.0, 10,'Tarts & Pies'),
      ('TAR010', 'Mango Pie',                 125.0, 10,'Tarts & Pies'),
      ('TAR011', 'Mango Pie (Whole)',        1000.0, 10,'Tarts & Pies'),
      ('TAR012', 'Lemon Tart',                100.0, 10,'Tarts & Pies'),
      ('TAR013', 'Mille-Feuille',             150.0, 10,'Tarts & Pies'),
      ('TAR014', 'Mulberry Tart (Whole)',    1000.0, 10,'Tarts & Pies'),
      // Breads & Buns
      ('BRD001', 'Multigrain Bread',          180.0, 10,'Breads & Buns'),
      ('BRD002', 'Sourdough Bread',           330.0, 10,'Breads & Buns'),
      ('BRD003', 'Multigrain Sourdough Bread',380.0, 10,'Breads & Buns'),
      ('BRD004', 'Focaccia',                   90.0, 10,'Breads & Buns'),
      ('BRD005', 'Small Baguette',             75.0, 10,'Breads & Buns'),
      ('BRD006', 'Long Baguette',             100.0, 10,'Breads & Buns'),
      ('BRD007', 'Multigrain Baguette',       100.0, 10,'Breads & Buns'),
      ('BRD008', 'Banana Bread (Slice)',      100.0, 10,'Breads & Buns'),
      ('BRD009', 'Burger Bun',                 25.0, 10,'Breads & Buns'),
      ('BRD010', 'Panini Bread',               40.0, 10,'Breads & Buns'),
      ('BRD011', 'Breakfast Bun',              40.0, 10,'Breads & Buns'),
      // Savouries
      ('SAV001', 'Quiche',                 150.0, 10,'Savouries'),
      ('SAV002', 'Chicken Patty',          100.0, 10,'Savouries'),
      ('SAV003', 'Veg Patty',               90.0, 10,'Savouries'),
      ('SAV004', 'Burger Patty',           100.0, 10,'Savouries'),
      ('SAV005', 'Chicken Burger Patty',   110.0, 10,'Savouries'),
      ('SAV006', 'Sausage Roll',           100.0, 10,'Savouries'),
      ('SAV007', 'Sausage Roll (Large)',   200.0, 10,'Savouries'),
      ('SAV008', 'Bread Pudding',           80.0, 10,'Savouries'),
      ('SAV009', 'Puffed Dough',           600.0, 10,'Savouries'),
      // Cakes & Sweets
      ('CAK001', 'Brownie',        120.0, 10,'Cakes & Sweets'),
      ('CAK002', 'Caramel Cake',   950.0, 10,'Cakes & Sweets'),
      ('CAK003', 'Apple Strudel',  125.0, 10,'Cakes & Sweets'),
      ('CAK004', 'Custom Order',     0.0, 10,'Cakes & Sweets'),
    ];

    // Collect sku → (id, price) for order seeding
    final productMap = <String, (int, double)>{};
    for (final (sku, name, price, stock, cat) in productRows) {
      final id = await _db.productsDao.upsert(
        ProductsCompanion.insert(
          sku: sku,
          name: name,
          price: price,
          stockQuantity: Value(stock),
          categoryId: Value(catIds[cat]),
        ),
      );
      productMap[sku] = (id, price);
    }

    // ── Tax rates ─────────────────────────────────────────────────────────
    final vatId = await _db.taxDao.upsertRate(
      TaxRatesCompanion.insert(
        name: 'VAT',
        rate: 0.13, // 13% Nepal VAT
        inclusionType: const Value('exclusive'),
      ),
    );

    // ── Customers ─────────────────────────────────────────────────────────
    // (name, phone, email, loyaltyPts, defaultDiscount, isPercent)
    final customerDefs = [
      ('Anita Sharma',   '9841000001', 'anita@gmail.com',   350, 10.0, true),
      ('Bikash Thapa',   '9851000002', null,                120,  0.0, false),
      ('Sushma Karki',   '9861000003', 'sushma@gmail.com',  560, 15.0, true),
      ('Dipak Rai',      '9841000004', null,                 80, 50.0, false),
      ('Priya Maharjan', '9851000005', 'priya@outlook.com', 200,  5.0, true),
    ];
    final customerIds = <int>[];
    for (final (name, phone, email, pts, disc, isPct) in customerDefs) {
      final id = await _db.customersDao.upsert(
        CustomersCompanion.insert(
          name: name,
          phone: Value(phone),
          email: Value(email),
          loyaltyPoints: Value(pts),
          defaultDiscount: Value(disc),
          defaultDiscountIsPercent: Value(isPct),
        ),
      );
      customerIds.add(id);
    }

    // ── Demo orders ───────────────────────────────────────────────────────
    // Each entry: (daysAgo, [(sku, qty)], paymentMethod, customerIndex or -1)
    // Tax: 13% VAT exclusive applied to all taxable items
    final now = DateTime.now();
    DateTime ago(int days) => DateTime(
          now.year, now.month, now.day,
          8 + (days % 10), (days * 7) % 60,
        ).subtract(Duration(days: days));

    final orders = [
      // ── This week ─────────────────────────────────────────────────────
      (0, [('CRO001', 3), ('ECL001', 2)],          'cash', -1),
      (0, [('BRD002', 1), ('TAR001', 2)],           'card',  0),
      (1, [('CRO002', 2), ('CRO006', 1), ('CAK001', 1)], 'cash', -1),
      (1, [('SAV001', 2), ('SAV006', 1)],           'card',  2),
      (2, [('TAR009', 1), ('ECL003', 3)],           'cash', -1),
      (2, [('BRD003', 1), ('BRD005', 2)],           'cash',  1),
      (3, [('CRO001', 5), ('CRO004', 3)],           'cash', -1),
      (3, [('CAK002', 1)],                          'card',  4),
      (4, [('TAR011', 1), ('CAK001', 2)],           'cash', -1),
      (4, [('ECL001', 4), ('ECL002', 2)],           'card',  0),
      (5, [('SAV009', 1), ('BRD001', 1)],           'cash', -1),
      (5, [('CRO002', 3), ('TAR002', 2)],           'cash',  3),
      (6, [('CAK003', 2), ('TAR012', 3)],           'card', -1),
      (6, [('BRD002', 2), ('SAV002', 2)],           'cash',  2),
      // ── Earlier this month ────────────────────────────────────────────
      (8,  [('TAR014', 1)],                         'card', -1),
      (9,  [('CRO001', 4), ('ECL004', 3)],          'cash',  1),
      (10, [('SAV007', 1), ('SAV001', 2)],          'cash', -1),
      (11, [('BRD003', 1), ('TAR005', 2)],          'card',  0),
      (12, [('CAK002', 1), ('CAK001', 3)],          'cash', -1),
      (13, [('CRO006', 3), ('ECL003', 2)],          'card',  4),
      (15, [('TAR009', 2), ('TAR013', 1)],          'cash', -1),
      (17, [('BRD002', 1), ('BRD007', 2)],          'cash',  2),
      (19, [('CRO001', 6), ('CRO004', 4)],          'card', -1),
      (21, [('SAV001', 3), ('SAV002', 2)],          'cash',  3),
      (23, [('ECL001', 5), ('ECL005', 3)],          'card', -1),
      (25, [('TAR011', 1), ('CAK003', 2)],          'cash',  1),
      (27, [('BRD001', 2), ('BRD004', 1)],          'card', -1),
      (29, [('CRO002', 3), ('CAK001', 4)],          'cash',  0),
    ];

    for (final (daysAgo, items, method, custIdx) in orders) {
      final orderDate = ago(daysAgo);

      // Compute subtotal
      double subtotal = 0;
      for (final (sku, qty) in items) {
        final (_, price) = productMap[sku]!;
        subtotal += price * qty;
      }

      final taxAmt = double.parse((subtotal * 0.13).toStringAsFixed(2));
      final total = subtotal + taxAmt;
      final tendered = method == 'cash'
          ? ((total / 100).ceil() * 100).toDouble()
          : null;

      final orderId = await _db.ordersDao.insertOrder(
        OrdersCompanion(
          status: const Value('completed'),
          subtotal: Value(subtotal),
          taxTotal: Value(taxAmt),
          discountTotal: const Value(0.0),
          total: Value(total),
          paymentMethod: Value(method),
          tenderedAmount: Value(tendered),
          changeAmount: tendered != null
              ? Value(tendered - total)
              : const Value(null),
          customerId: custIdx >= 0
              ? Value(customerIds[custIdx])
              : const Value(null),
          createdAt: Value(orderDate),
          updatedAt: Value(orderDate),
        ),
      );

      await _db.ordersDao.insertItems([
        for (final (sku, qty) in items)
          OrderItemsCompanion.insert(
            orderId: orderId,
            productId: productMap[sku]!.$1,
            productName: productRows
                .firstWhere((r) => r.$1 == sku)
                .$2,
            unitPrice: productMap[sku]!.$2,
            quantity: qty,
            lineTotal: productMap[sku]!.$2 * qty,
          ),
      ]);

      if (taxAmt > 0) {
        await _db.ordersDao.insertTaxLines([
          OrderTaxesCompanion.insert(
            orderId: orderId,
            taxRateId: vatId,
            taxRateName: 'VAT',
            taxRatePercent: 0.13,
            taxableAmount: subtotal,
            taxAmount: taxAmt,
          ),
        ]);
      }
    }
  }
}

final demoDataServiceProvider = Provider<DemoDataService>((ref) {
  return DemoDataService(ref.watch(databaseProvider));
});
