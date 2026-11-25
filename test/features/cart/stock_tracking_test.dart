import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// Stock convention: stock 0 + !isOutOfStock = untracked (unlimited).
void main() {
  late AppDatabase db;
  late AuditService audit;

  setUp(() {
    db = openInMemoryDatabase();
    audit = AuditService(db);
  });
  tearDown(() => db.close());

  test('selling the last unit marks a tracked product out of stock',
      () async {
    final p = await seedProduct(db, sku: 'A', stock: 2);
    await sell(db, audit, [line(p, qty: 2)]);

    final after = await product(db, p);
    expect(after.stockQuantity, 0);
    expect(after.isOutOfStock, isTrue,
        reason: 'stock 0 without the flag would read as unlimited');
  });

  test('selling part of the stock leaves the flag alone', () async {
    final p = await seedProduct(db, sku: 'A', stock: 5);
    await sell(db, audit, [line(p, qty: 2)]);

    final after = await product(db, p);
    expect(after.stockQuantity, 3);
    expect(after.isOutOfStock, isFalse);
  });

  test('overselling never drives stock negative', () async {
    final p = await seedProduct(db, sku: 'A', stock: 2);
    await sell(db, audit, [line(p, qty: 5)]);

    final after = await product(db, p);
    expect(after.stockQuantity, 0);
    expect(after.isOutOfStock, isTrue);
    final adj = await db.inventoryDao.getAdjustmentsForProduct(p);
    expect(adj.single.delta, -2, reason: 'log what was actually deducted');
  });

  test('a composite sale that empties a component marks it out of stock',
      () async {
    final comp = await seedProduct(db, sku: 'BEAN', stock: 3);
    final latte = await seedProduct(db, sku: 'LATTE', stock: 0, composite: true);
    await db.productsDao.replaceComponents(latte, [
      ProductComponentsCompanion.insert(
          compositeProductId: latte, componentProductId: comp),
    ]);
    await sell(db, audit, [line(latte, qty: 3)]);

    final after = await product(db, comp);
    expect(after.stockQuantity, 0);
    expect(after.isOutOfStock, isTrue);
  });

  test('selling an untracked product writes no stock adjustment', () async {
    final p = await seedProduct(db, sku: 'A', stock: 0);
    await sell(db, audit, [line(p, qty: 3)]);

    final after = await product(db, p);
    expect(after.stockQuantity, 0);
    expect(after.isOutOfStock, isFalse);
    expect(await db.inventoryDao.getAdjustmentsForProduct(p), isEmpty);
  });
}
