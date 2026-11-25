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
      ? voidOrder(db, audit, orderId: orderId, reason: 't')
      : processReturn(db, audit,
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
