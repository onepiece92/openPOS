import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/products/domain/unit_conversion.dart';
import 'package:pos_app/features/returns/domain/void_order.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// New conversions must be whole numbers, but products saved before that
/// rule can hold a fractional one. Their data is left alone: they must keep
/// loading and selling. This pins down what stock does for them meanwhile —
/// each line's main-unit quantity is rounded to a whole unit (half away
/// from zero), and a void puts back exactly what the sale took.
void main() {
  late AppDatabase db;
  late AuditService audit;
  setUp(() {
    db = openInMemoryDatabase();
    audit = AuditService(db);
  });
  tearDown(() => db.close());

  test('a product with a fractional rate still loads, and is flagged for '
      'the form', () async {
    final id = await db.productsDao.upsert(ProductsCompanion.insert(
        sku: 'CAKE',
        name: 'Cake',
        price: 40,
        secondaryUnit: const Value('half'),
        conversionRate: const Value(0.5),
        stockQuantity: const Value(10)));
    final p = await product(db, id);
    expect(p.conversionRate, 0.5);
    expect(isValidConversionRate(p.conversionRate), isFalse);
    expect(validateConversionRate('0.5'), isNotNull);
  });

  test('line rounding: 1 × 0.5 → 1, 3 × 0.5 → 2, 1 × 0.333 → 0', () {
    CartItem l(int qty, double per) => CartItem(
        productId: 1,
        name: 'x',
        unitPrice: 1,
        quantity: qty,
        isTaxable: false,
        unitLabel: 'part',
        unitsPerQty: per);
    expect(l(1, 0.5).mainUnitQty, 1);
    expect(l(2, 0.5).mainUnitQty, 1);
    expect(l(3, 0.5).mainUnitQty, 2);
    expect(l(1, 0.333).mainUnitQty, 0);
    expect(l(2, 0.333).mainUnitQty, 1);
    expect(l(1, 2.5).mainUnitQty, 3);
  });

  test('selling and voiding fractional lines never crashes and is symmetric',
      () async {
    final halves = await seedProduct(db, sku: 'H', stock: 10);
    final ids = <int>[];
    for (var i = 0; i < 3; i++) {
      ids.add(await sell(
          db, audit, [line(halves, unitLabel: 'half', unitsPerQty: 0.5)]));
    }
    // Three separate half-sales take a whole unit each: 3, not 1.5.
    expect((await product(db, halves)).stockQuantity, 7);

    final thirds = await seedProduct(db, sku: 'T', stock: 10);
    await sell(
        db, audit, [line(thirds, unitLabel: 'third', unitsPerQty: 0.333)]);
    // A lone third rounds to nothing: stock is not touched.
    expect((await product(db, thirds)).stockQuantity, 10);

    for (final id in ids) {
      await voidOrder(db, audit, orderId: id, reason: 'test');
    }
    expect((await product(db, halves)).stockQuantity, 10);
  });
}
