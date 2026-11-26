import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/returns/domain/void_order.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// InventoryDao.stockToRestock: what an order still owes the shelf, read
/// from its own adjustment rows (schema v16 orders), or null (legacy).
void main() {
  late AppDatabase db;
  late AuditService audit;

  setUp(() {
    db = openInMemoryDatabase();
    audit = AuditService(db);
  });
  tearDown(() => db.close());

  Future<Map<int, int>?> owed(int orderId) =>
      db.inventoryDao.stockToRestock(orderId);

  test('a sale is stock-linked, a plain product owes what was taken',
      () async {
    final tea = await seedProduct(db, sku: 'TEA', stock: 10);
    final id = await sell(db, audit, [line(tea, qty: 3)]);
    expect((await db.ordersDao.getById(id))!.stockLinked, 1);
    expect(await owed(id), {tea: 3});
  });

  test('a bundle owes its component rows, not the bundle', () async {
    final bean = await seedProduct(db, sku: 'BEAN', stock: 50);
    final box = await seedProduct(db, sku: 'BOX', stock: 0, composite: true);
    await db.productsDao.replaceComponents(box, [
      ProductComponentsCompanion.insert(
          compositeProductId: box,
          componentProductId: bean,
          quantity: const Value(2)),
    ]);
    final id = await sell(db, audit, [line(box, qty: 2)]);
    // Changing the recipe afterwards changes nothing: rows are the truth.
    await db.productsDao.replaceComponents(box, const []);
    expect(await owed(id), {bean: 4});
  });

  test('a partial restock already done is netted off', () async {
    final tea = await seedProduct(db, sku: 'TEA', stock: 10);
    final cake = await seedProduct(db, sku: 'CAKE', stock: 10);
    final id = await sell(db, audit, [line(tea, qty: 3), line(cake)]);
    await db.inventoryDao.logAdjustment(StockAdjustmentsCompanion.insert(
        productId: tea, delta: 1, reasonCode: 'return', orderId: Value(id)));
    await db.inventoryDao.logAdjustment(StockAdjustmentsCompanion.insert(
        productId: cake, delta: 1, reasonCode: 'return', orderId: Value(id)));
    expect(await owed(id), {tea: 2});
  });

  test('fully put back (a void) owes nothing', () async {
    final tea = await seedProduct(db, sku: 'TEA', stock: 10);
    final id = await sell(db, audit, [line(tea, qty: 3)]);
    await voidOrder(db, audit, trackStock: true, orderId: id, reason: 't');
    expect(await owed(id), isEmpty);
  });

  test('a linked sale that deducted nothing owes nothing (not null)',
      () async {
    final svc = await seedProduct(db, sku: 'SVC', stock: 0); // untracked
    final id = await sell(db, audit, [line(svc, qty: 2)]);
    expect(await db.inventoryDao.getAdjustmentsForOrder(id), isEmpty);
    expect(await owed(id), isNotNull);
    expect(await owed(id), isEmpty);
  });

  test('a legacy order (stock_linked NULL) returns null', () async {
    final id = await db.ordersDao.insertOrder(OrdersCompanion.insert(
        subtotal: 5, total: 5, paymentMethod: 'cash'));
    expect((await db.ordersDao.getById(id))!.stockLinked, isNull);
    expect(await owed(id), isNull);
  });

  test('a missing order throws', () async {
    await expectLater(owed(404), throwsStateError);
  });
}
