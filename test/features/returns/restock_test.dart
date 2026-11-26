import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/returns/domain/process_return.dart';
import 'package:pos_app/features/returns/domain/void_order.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// Void and refund-with-restock must put back exactly what the sale took.
void main() {
  late AppDatabase db;
  late AuditService audit;

  setUp(() {
    db = openInMemoryDatabase();
    audit = AuditService(db);
  });
  tearDown(() => db.close());

  Future<void> reverse(String how, int orderId, double total) => how == 'void'
      ? voidOrder(db, audit, trackStock: true, orderId: orderId, reason: 't')
      : processReturn(db, audit, trackStock: true,
          orderId: orderId, amount: total, restock: true);

  for (final how in ['void', 'refund']) {
    group(how, () {
      test('restores a secondary-unit line in main units', () async {
        final p = await seedProduct(db, sku: 'EGG', stock: 100);
        // 2 dozen = 24 pcs
        final id = await sell(db, audit,
            [line(p, qty: 2, price: 60, unitLabel: 'dozen', unitsPerQty: 12)]);
        expect((await product(db, p)).stockQuantity, 76);

        await reverse(how, id, 120);

        expect((await product(db, p)).stockQuantity, 100);
        final adj = await db.inventoryDao.getAdjustmentsForProduct(p);
        expect(adj.where((a) => a.reasonCode != 'sale').single.delta, 24);
      });

      test('restores composite components for a secondary-unit line',
          () async {
        final bean = await seedProduct(db, sku: 'BEAN', stock: 100);
        final box = await seedProduct(db, sku: 'BOX', stock: 0, composite: true);
        await db.productsDao.replaceComponents(box, [
          ProductComponentsCompanion.insert(
              compositeProductId: box,
              componentProductId: bean,
              quantity: const Value(2)),
        ]);
        // 1 case = 6 boxes, each box uses 2 beans → 12 beans
        final id = await sell(db, audit,
            [line(box, qty: 1, price: 30, unitLabel: 'case', unitsPerQty: 6)]);
        expect((await product(db, bean)).stockQuantity, 88);

        await reverse(how, id, 30);

        expect((await product(db, bean)).stockQuantity, 100);
      });

      test('leaves an untracked product untracked', () async {
        final p = await seedProduct(db, sku: 'SVC', stock: 0);
        final id = await sell(db, audit, [line(p, qty: 3)]);

        await reverse(how, id, 15);

        final after = await product(db, p);
        expect(after.stockQuantity, 0, reason: 'no phantom stock');
        expect(after.isOutOfStock, isFalse);
        expect(await db.inventoryDao.getAdjustmentsForProduct(p), isEmpty);
      });

      test('sale and $how adjustment rows carry the order id, bundles too',
          () async {
        final tea = await seedProduct(db, sku: 'TEA', stock: 50);
        final bean = await seedProduct(db, sku: 'BEAN', stock: 50);
        final box = await seedProduct(db, sku: 'BOX', stock: 0, composite: true);
        await db.productsDao.replaceComponents(box, [
          ProductComponentsCompanion.insert(
              compositeProductId: box,
              componentProductId: bean,
              quantity: const Value(2)),
        ]);
        final other = await sell(db, audit, [line(tea)]);
        final id = await sell(db, audit, [line(tea, qty: 2), line(box)]);
        // A manual adjustment belongs to no order.
        await db.inventoryDao.logAdjustment(StockAdjustmentsCompanion.insert(
            productId: tea, delta: 5, reasonCode: 'receive'));

        await reverse(how, id, 15);

        final rows = await db.inventoryDao.getAdjustmentsForOrder(id);
        expect(
            rows.map((r) => (r.productId, r.delta, r.reasonCode)),
            [
              (tea, -2, 'sale'),
              (bean, -2, 'sale'), // the bundle's component
              (tea, 2, how == 'void' ? 'void' : 'return'),
              (bean, 2, how == 'void' ? 'void' : 'return'),
            ]);
        expect((await db.inventoryDao.getAdjustmentsForOrder(other)).single.delta,
            -1);
        final manual = (await db.inventoryDao.getAdjustmentsForProduct(tea))
            .where((r) => r.reasonCode == 'receive')
            .single;
        expect(manual.orderId, isNull);
      });

      test('clears out-of-stock on a product that had sold out', () async {
        final p = await seedProduct(db, sku: 'A', stock: 2);
        final id = await sell(db, audit, [line(p, qty: 2)]);
        // Sold out: tracked, nothing left.
        await db.productsDao
            .setStockState(p, stockQuantity: 0, isOutOfStock: true);

        await reverse(how, id, 10);

        final after = await product(db, p);
        expect(after.stockQuantity, 2);
        expect(after.isOutOfStock, isFalse);
      });
    });
  }
}
