import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/cart/data/place_order.dart';
import 'package:pos_app/features/cart/domain/cart_calculator.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/reports/domain/report_data.dart';
import 'package:pos_app/features/returns/domain/process_return.dart';
import 'package:pos_app/features/returns/domain/void_order.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';
import '../../_support/features.dart';

/// The dashboard's money figures and how they hang together:
///
///   revenue        takings including VAT, net of refunds
///   VAT collected  the tax inside those takings
///   sales ex-VAT   revenue − VAT collected
///   cost of goods  what the sold goods cost on the day of the sale
///   net profit     sales ex-VAT − cost of goods − expenses
void main() {
  late AppDatabase db;
  late AuditService audit;
  late ProviderContainer c;

  setUp(() {
    db = openInMemoryDatabase();
    audit = AuditService(db);
    c = ProviderContainer(
        overrides: [allFeaturesOn, databaseProvider.overrideWithValue(db)]);
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });

  Future<ReportData> report({ReportQuery? query}) async {
    const p = ReportPeriod.today;
    final q = query ?? ReportQuery(from: p.from, to: p.to, label: 'x');
    final sub = c.listen(reportProvider(q), (_, __) {});
    c.invalidate(reportProvider(q));
    final d = await c.read(reportProvider(q).future);
    sub.close();
    return d;
  }

  Future<TaxRate> vat({bool inclusive = false}) async {
    final id = await db.taxDao.upsertRate(TaxRatesCompanion.insert(
        name: 'VAT',
        rate: 0.13,
        inclusionType: Value(inclusive ? 'inclusive' : 'exclusive')));
    return (await db.taxDao.getById(id))!;
  }

  Future<int> product(String name,
          {double cost = 0, String? secondaryUnit, double conversion = 1}) =>
      db.productsDao.upsert(ProductsCompanion.insert(
          sku: name,
          name: name,
          price: 100,
          purchasePrice: Value(cost),
          secondaryUnit: Value(secondaryUnit),
          conversionRate: Value(conversion)));

  CartItem item(int id, String name, double price,
          {int qty = 1,
          bool taxable = true,
          String unitLabel = '',
          double unitsPerQty = 1}) =>
      CartItem(
          productId: id,
          name: name,
          unitPrice: price,
          quantity: qty,
          isTaxable: taxable,
          unitLabel: unitLabel,
          unitsPerQty: unitsPerQty);

  Future<int> place(
    List<CartItem> items, {
    List<TaxRate> rates = const [],
    double discountPercent = 0,
    int? customerId,
    int redeem = 0,
  }) {
    final session = CartSession(
        ticketNumber: '#1',
        openedAt: DateTime.now(),
        customerId: customerId,
        orderDiscount: discountPercent,
        orderDiscountIsPercent: true,
        loyaltyPointsToRedeem: redeem);
    final summary = CartCalculator.compute(
        items: items,
        session: session,
        selectedRates: rates,
        loyaltyEnabled: redeem > 0,
        loyaltyPointValue: 1,
        customerLoyaltyPoints: 100000);
    return placeOrder(db, audit,
        cart: items,
        summary: summary,
        session: session,
        paymentMethod: 'card',
        tenderedAmount: 0);
  }

  Future<void> expense(double amount) async {
    final cat = await db.expensesDao
        .insertCategory(ExpenseCategoriesCompanion.insert(name: 'Rent'));
    await db.expensesDao.insert(ExpensesCompanion.insert(
        amount: amount, date: DateTime.now(), categoryId: cat));
  }

  group('net profit', () {
    late int orderId;
    setUp(() async {
      // 10 × 100 (bought at 80), 10 % off, 13 % VAT on top, one expense of 50.
      final widget = await product('Widget', cost: 80);
      orderId = await place([item(widget, 'Widget', 100, qty: 10)],
          rates: [await vat()], discountPercent: 10);
      await expense(50);
    });

    test('the worked example', () async {
      final d = await report();
      expect(d.revenue, 1017);
      expect(d.vatCollected, 117);
      expect(d.salesExVat, 900);
      expect(d.costOfGoods, 800);
      expect(d.expenses, 50);
      expect(d.profit, 50);
      expect(d.uncostedLines, 0);
    });

    test('a later purchase-price change does not move past profit', () async {
      final widget = (await db.ordersDao.getItems(orderId)).single.productId;
      await db.productsDao.updateProduct(
          widget, const ProductsCompanion(purchasePrice: Value(95)));
      expect((await report()).costOfGoods, 800);
    });

    test('a partial refund scales revenue, VAT and cost by the share kept',
        () async {
      // 508.50 of 1017 refunded → exactly half of the sale is kept.
      await processReturn(db, audit,
          orderId: orderId, amount: 508.50, restock: false);
      final d = await report();
      expect(d.revenue, 508.50);
      expect(d.vatCollected, 58.50);
      expect(d.salesExVat, 450);
      expect(d.costOfGoods, 400);
      expect(d.profit, 0);
      expect(d.topProducts.single.sales, 450);
    });

    test('a fully refunded order contributes nothing', () async {
      await processReturn(db, audit,
          orderId: orderId, amount: 1017, restock: false);
      final d = await report();
      expect(d.revenue, 0);
      expect(d.vatCollected, 0);
      expect(d.costOfGoods, 0);
      expect(d.profit, -50);
      expect(d.topProducts, isEmpty);
    });

    test('a voided order contributes nothing', () async {
      await voidOrder(db, audit, orderId: orderId, reason: 'test');
      final d = await report();
      expect(d.revenue, 0);
      expect(d.vatCollected, 0);
      expect(d.costOfGoods, 0);
      expect(d.profit, -50);
      expect(d.topProducts, isEmpty);
    });
  });

  test('inclusive VAT is taken out of sales; the total is unchanged', () async {
    final tea = await product('Tea', cost: 60);
    await place([item(tea, 'Tea', 113)], rates: [await vat(inclusive: true)]);
    final d = await report();
    expect(d.revenue, 113);
    expect(d.vatCollected, 13);
    expect(d.salesExVat, 100);
    expect(d.profit, 40);
    expect(d.topProducts.single.sales, 100);
  });

  test('points redeemed are money not received: they come off sales, not VAT',
      () async {
    final tea = await product('Tea', cost: 60);
    final customer = await seedCustomer(db, points: 500);
    await place([item(tea, 'Tea', 100)],
        rates: [await vat()], customerId: customer, redeem: 13);
    final d = await report();
    expect(d.revenue, 100);
    expect(d.vatCollected, 13);
    expect(d.salesExVat, 87);
    expect(d.profit, 27);
    expect(d.topProducts.single.sales, 87);
  });

  test('sold items with no cost recorded are counted, not hidden', () async {
    final costed = await product('Costed', cost: 40);
    final unknown = await product('Unknown');
    await place([item(costed, 'Costed', 100), item(unknown, 'Unknown', 100)]);
    final d = await report();
    expect(d.costOfGoods, 40);
    expect(d.soldLines, 2);
    expect(d.uncostedLines, 1);
    expect(d.profit, 160, reason: 'the unknown cost counts as zero');
  });

  test('an older order with several tax lines still reports its whole tax',
      () async {
    // Carts are limited to one rate now; orders placed before that keep
    // their lines, and both count as VAT collected.
    final tea = await product('Tea', cost: 60);
    final rate = await vat();
    final id = await db.ordersDao.insertOrder(OrdersCompanion.insert(
        subtotal: 100,
        taxTotal: const Value(18),
        total: 118,
        paymentMethod: 'cash'));
    await db.ordersDao.insertItems([
      OrderItemsCompanion.insert(
          orderId: id,
          productId: tea,
          productName: 'Tea',
          unitPrice: 100,
          quantity: 1,
          lineTotal: 100,
          unitCost: const Value(60)),
    ]);
    await db.ordersDao.insertTaxLines([
      OrderTaxesCompanion.insert(
          orderId: id,
          taxRateId: rate.id,
          taxRateName: 'VAT',
          taxRatePercent: 0.13,
          taxableAmount: 100,
          taxAmount: 13),
      OrderTaxesCompanion.insert(
          orderId: id,
          taxRateId: rate.id,
          taxRateName: 'Levy',
          taxRatePercent: 0.05,
          taxableAmount: 100,
          taxAmount: 5),
    ]);
    expect(await db.ordersDao.getTaxBreakdown(id), hasLength(2));
    final d = await report();
    expect(d.revenue, 118);
    expect(d.vatCollected, 18);
    expect(d.salesExVat, 100);
    expect(d.profit, 40);
    expect(d.topProducts.single.sales, 100);
  });

  group('top products', () {
    test('one row per product: renames and secondary units do not split it',
        () async {
      final eggs = await product('Eggs',
          cost: 5, secondaryUnit: 'dozen', conversion: 12);
      await place([item(eggs, 'Eggs', 10, qty: 3)]);
      await place([
        item(eggs, 'Eggs', 110, qty: 2, unitLabel: 'dozen', unitsPerQty: 12)
      ]);
      await db.productsDao.updateProduct(
          eggs, const ProductsCompanion(name: Value('Farm eggs')));
      await place([item(eggs, 'Farm eggs', 10, qty: 1)]);

      final top = (await report()).topProducts;
      expect(top, hasLength(1));
      expect(top.single.name, 'Farm eggs', reason: 'the current name');
      expect(top.single.qty, 3 + 24 + 1, reason: 'counted in main units');
      expect(top.single.sales, 30 + 220 + 10);
    });

    test(
        'the money column is sales ex-VAT after the order discount, and '
        'adds up to the dashboard figure', () async {
      final a = await product('A', cost: 10);
      final b = await product('B', cost: 10);
      // 300 + 100 = 400, 25 % off → 300; B is not taxable; VAT 13 % of 225.
      await place([
        item(a, 'A', 100, qty: 3),
        item(b, 'B', 100, taxable: false),
      ], rates: [
        await vat()
      ], discountPercent: 25);
      final d = await report();
      final byName = {for (final t in d.topProducts) t.name: t.sales};
      expect(byName, {'A': 225.0, 'B': 75.0});
      expect(d.vatCollected, 29.25);
      expect(d.salesExVat, 300);
      expect(d.topProducts.fold(0.0, (s, t) => s + t.sales), d.salesExVat);
    });
  });

  group('chart granularity follows calendar days', () {
    Future<void> orderAt(DateTime when, double total) =>
        db.ordersDao.insertOrder(OrdersCompanion.insert(
            subtotal: total,
            total: total,
            paymentMethod: 'cash',
            createdAt: Value(when)));

    ReportQuery range(DateTime fromDay, DateTime toDay) => ReportQuery(
        from: fromDay,
        to: DateTime(toDay.year, toDay.month, toDay.day, 23, 59, 59, 999),
        label: 'x');

    test('a single day is charted hourly', () async {
      await orderAt(DateTime(2026, 3, 10, 9), 40);
      final d = await report(
          query: range(DateTime(2026, 3, 10), DateTime(2026, 3, 10)));
      expect(d.chartTitle, 'Hourly Sales');
      expect(d.chartTotals[4], 40);
    });

    test('two days are charted as two days, not merged into one clock',
        () async {
      await orderAt(DateTime(2026, 3, 10, 9), 40);
      await orderAt(DateTime(2026, 3, 11, 9), 60);
      final d = await report(
          query: range(DateTime(2026, 3, 10), DateTime(2026, 3, 11)));
      expect(d.chartTitle, 'Daily Sales');
      expect(d.chartDates, ['10/3', '11/3']);
      expect(d.chartTotals, [40, 60]);
    });

    test('a daily range has one bucket per calendar day', () async {
      for (final day in [30, 31, 32]) {
        await orderAt(DateTime(2026, 10, day, 12), 100);
      }
      final d = await report(
          query: range(DateTime(2026, 10, 30), DateTime(2026, 11, 1)));
      expect(d.chartDates, ['30/10', '31/10', '1/11']);
      expect(d.chartTotals, [100, 100, 100]);
    });
  });
}
