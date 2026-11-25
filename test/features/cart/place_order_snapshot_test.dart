import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/core/utils/money.dart';
import 'package:pos_app/features/cart/data/place_order.dart';
import 'package:pos_app/features/cart/domain/cart_calculator.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// What a sale freezes on its rows so receipts and reports never have to
/// guess later: whether the tax was inclusive, each line's share of the
/// invoice's tax, and what the goods cost on the day.
void main() {
  late AppDatabase db;
  late AuditService audit;
  setUp(() {
    db = openInMemoryDatabase();
    audit = AuditService(db);
  });
  tearDown(() => db.close());

  Future<TaxRate> rate(double r, {bool inclusive = false}) async {
    final id = await db.taxDao.upsertRate(TaxRatesCompanion.insert(
        name: 'VAT',
        rate: r,
        inclusionType: Value(inclusive ? 'inclusive' : 'exclusive')));
    return (await db.taxDao.getById(id))!;
  }

  Future<int> product(String sku,
          {double cost = 0, bool composite = false}) =>
      db.productsDao.upsert(ProductsCompanion.insert(
          sku: sku,
          name: sku,
          price: 100,
          purchasePrice: Value(cost),
          isComposite: Value(composite)));

  CartItem item(int id, double price,
          {int qty = 1,
          bool taxable = true,
          String unitLabel = '',
          double unitsPerQty = 1}) =>
      CartItem(
          productId: id,
          name: 'p$id',
          unitPrice: price,
          quantity: qty,
          isTaxable: taxable,
          unitLabel: unitLabel,
          unitsPerQty: unitsPerQty);

  Future<int> place(List<CartItem> items, List<TaxRate> rates,
      {int? customerId, double earnRate = 0}) {
    final session = CartSession(
        ticketNumber: '#1', openedAt: DateTime(2026), customerId: customerId);
    final summary = CartCalculator.compute(
        items: items,
        session: session,
        selectedRates: rates,
        loyaltyEnabled: earnRate > 0,
        loyaltyEarnRate: earnRate,
        loyaltyPointValue: 1);
    return placeOrder(db, audit,
        cart: items,
        summary: summary,
        session: session,
        paymentMethod: 'card',
        tenderedAmount: 0);
  }

  test('an inclusive tax line is stored as inclusive, an exclusive one is not',
      () async {
    final p = await product('A');
    final incl =
        await place([item(p, 113)], [await rate(0.13, inclusive: true)]);
    final excl = await place([item(p, 100)], [await rate(0.13)]);

    final a = (await db.ordersDao.getTaxBreakdown(incl)).single;
    expect(a.isInclusive, isTrue);
    expect(a.taxAmount, 13);
    expect(a.taxableAmount, 100);
    expect((await db.ordersDao.getById(incl))!.total, 113);

    final b = (await db.ordersDao.getTaxBreakdown(excl)).single;
    expect(b.isInclusive, isFalse);
    expect((await db.ordersDao.getById(excl))!.total, 113);
  });

  test("each line stores its share of the invoice's tax, summing to it exactly",
      () async {
    final p = await product('A');
    final q = await product('B');
    final r = await product('C');
    // Base 1.50 → VAT 0.20, which does not split evenly over three lines.
    final id = await place([
      item(p, 0.50),
      item(q, 0.50),
      item(r, 0.50),
      item(p, 9.99, taxable: false, unitLabel: 'box', unitsPerQty: 2),
    ], [
      await rate(0.13)
    ]);
    final order = (await db.ordersDao.getById(id))!;
    final items = await db.ordersDao.getItems(id);
    expect(order.taxTotal, 0.20);
    expect(roundMoney(items.fold(0.0, (s, i) => s + i.taxAmount)), 0.20);
    expect(items.map((i) => i.taxAmount).toList()..sort(),
        [0.0, 0.06, 0.07, 0.07]);
    expect(items.last.taxAmount, 0, reason: 'the non-taxable line carries none');
  });

  test('no tax selected → every line stores 0 tax', () async {
    final p = await product('A');
    final id = await place([item(p, 10, qty: 3)], const []);
    expect((await db.ordersDao.getItems(id)).single.taxAmount, 0);
  });

  group('cost of goods is frozen on the line at sale time', () {
    test('the purchase price of the day, per main unit', () async {
      final p = await product('A', cost: 80);
      final id = await place([item(p, 100, qty: 10)], const []);
      // A later price change must not rewrite history.
      await db.productsDao.updateProduct(
          p, const ProductsCompanion(purchasePrice: Value(95)));
      expect((await db.ordersDao.getItems(id)).single.unitCost, 80);
    });

    test('a secondary-unit line keeps the main-unit cost', () async {
      final p = await product('EGG', cost: 5);
      final id = await place(
          [item(p, 70, qty: 2, unitLabel: 'dozen', unitsPerQty: 12)],
          const []);
      final line = (await db.ordersDao.getItems(id)).single;
      expect(line.unitCost, 5);
      // 2 dozen × 12 × 5
      expect(line.quantity * line.unitsPerQty * line.unitCost!, 120);
    });

    test('a composite costs the sum of its components', () async {
      final bun = await product('BUN', cost: 10);
      final patty = await product('PATTY', cost: 35);
      final burger = await product('BURGER', composite: true);
      await db.productsDao.replaceComponents(burger, [
        ProductComponentsCompanion.insert(
            compositeProductId: burger,
            componentProductId: bun,
            quantity: const Value(2)),
        ProductComponentsCompanion.insert(
            compositeProductId: burger, componentProductId: patty),
      ]);
      final id = await place([item(burger, 100)], const []);
      expect((await db.ordersDao.getItems(id)).single.unitCost, 55);
    });

    test('no purchase price → no cost recorded (NULL, not 0)', () async {
      final p = await product('A');
      final id = await place([item(p, 100)], const []);
      expect((await db.ordersDao.getItems(id)).single.unitCost, isNull);
    });

    test('a composite with an uncosted component records no cost', () async {
      final bun = await product('BUN', cost: 10);
      final sauce = await product('SAUCE');
      final burger = await product('BURGER', composite: true);
      await db.productsDao.replaceComponents(burger, [
        ProductComponentsCompanion.insert(
            compositeProductId: burger, componentProductId: bun),
        ProductComponentsCompanion.insert(
            compositeProductId: burger, componentProductId: sauce),
      ]);
      final id = await place([item(burger, 100)], const []);
      expect((await db.ordersDao.getItems(id)).single.unitCost, isNull);
    });
  });

  group('points earned', () {
    test('a walk-in sale stores no earned points', () async {
      final p = await product('A');
      final id = await place([item(p, 100)], const [], earnRate: 1);
      expect((await db.ordersDao.getById(id))!.pointsEarned, 0);
    });

    test('a customer sale stores and credits them', () async {
      final p = await product('A');
      final c = await seedCustomer(db);
      final id =
          await place([item(p, 4.35)], const [], customerId: c, earnRate: 100);
      expect((await db.ordersDao.getById(id))!.pointsEarned, 435);
      expect(await points(db, c), 435);
    });
  });

  test('prorateMoney splits to the cent and always sums to the amount', () {
    expect(prorateMoney(0.20, [0.5, 0.5, 0.5]), [0.07, 0.07, 0.06]);
    expect(prorateMoney(117, [1000]), [117]);
    expect(prorateMoney(1, [1, 0, 2]), [0.33, 0, 0.67]);
    expect(prorateMoney(5, [0, 0]), [0, 0]);
    expect(prorateMoney(0, [3, 4]), [0, 0]);
  });
}
