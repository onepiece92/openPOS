import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/tables/orders_table.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/returns/domain/process_return.dart';
import 'package:pos_app/features/returns/domain/reverse_sale.dart';
import 'package:pos_app/features/returns/domain/void_order.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// Void and refund restock: a stock-linked (v16) order from its own
/// adjustment rows, a legacy CSV import not at all, any other legacy order
/// from its lines while Stock tracking is on.
void main() {
  late AppDatabase db;
  late AuditService audit;

  setUp(() {
    db = openInMemoryDatabase();
    audit = AuditService(db);
  });
  tearDown(() => db.close());

  Future<int> stockOf(int id) async =>
      (await db.productsDao.getById(id))!.stockQuantity;
  Future<List<StockAdjustment>> rowsOf(int orderId, String reason) async =>
      (await db.inventoryDao.getAdjustmentsForOrder(orderId))
          .where((a) => a.reasonCode == reason)
          .toList();
  Future<RestockResult> voidIt(int id, {bool trackStock = true}) =>
      voidOrder(db, audit, orderId: id, reason: 't', trackStock: trackStock);
  Future<RefundResult> refund(int id, double amount,
          {bool restock = true, bool trackStock = true}) =>
      processReturn(db, audit,
          orderId: id,
          amount: amount,
          restock: restock,
          trackStock: trackStock);

  group('stock-linked (v16) order', () {
    test('a void restocks exactly the sale rows, and only tracked ones',
        () async {
      final tea = await seedProduct(db, sku: 'TEA', stock: 10);
      final svc = await seedProduct(db, sku: 'SVC', stock: 0); // untracked
      final id = await sell(db, audit, [line(tea, qty: 3), line(svc, qty: 2)]);
      expect(await stockOf(tea), 7);

      await voidIt(id);

      expect(await stockOf(tea), 10);
      expect(await stockOf(svc), 0, reason: 'no phantom stock');
      final voids = await rowsOf(id, 'void');
      expect(voids.map((a) => (a.productId, a.delta)), [(tea, 3)]);
      expect(await db.inventoryDao.stockToRestock(id), isEmpty);
    });

    test('a bundle restocks the components it took, not today\'s recipe',
        () async {
      final bean = await seedProduct(db, sku: 'BEAN', stock: 50);
      final cup = await seedProduct(db, sku: 'CUP', stock: 50);
      final box = await seedProduct(db, sku: 'BOX', stock: 0, composite: true);
      await db.productsDao.replaceComponents(box, [
        ProductComponentsCompanion.insert(
            compositeProductId: box,
            componentProductId: bean,
            quantity: const Value(2)),
      ]);
      final id = await sell(db, audit, [line(box, qty: 2)]);
      expect(await stockOf(bean), 46);
      // The recipe changes after the sale.
      await db.productsDao.replaceComponents(box, [
        ProductComponentsCompanion.insert(
            compositeProductId: box,
            componentProductId: cup,
            quantity: const Value(5)),
      ]);

      await voidIt(id);

      expect(await stockOf(bean), 50);
      expect(await stockOf(cup), 50, reason: 'never in the sale');
    });

    test('capped sale: 5 sold with 3 in stock deducts 3, a void restores 3',
        () async {
      final p = await seedProduct(db, sku: 'P', stock: 3);
      final id = await sell(db, audit, [line(p, qty: 5)]);
      final after = await product(db, p);
      expect(after.stockQuantity, 0);
      expect(after.isOutOfStock, isTrue);
      expect((await rowsOf(id, 'sale')).single.delta, -3,
          reason: 'placeOrder caps the deduction at what was there');

      final r = await voidIt(id);

      expect(await stockOf(p), 3, reason: 'not 5: only 3 left the shelf');
      expect((r.products, r.units), (1, 3));
      expect((await rowsOf(id, 'void')).single.delta, 3);
    });

    test('a partial refund with restock is capped at what is owed', () async {
      final p = await seedProduct(db, sku: 'P', stock: 3);
      final id = await sell(db, audit, [line(p, qty: 5)]); // total 25

      await refund(id, 10); // partial, restock

      expect(await stockOf(p), 3, reason: 'capped at the 3 deducted');
      expect((await rowsOf(id, 'return')).single.delta, 3);
      expect((await db.select(db.returns).get()).single.restock, isTrue);
      // A void afterwards finds nothing owed.
      await voidIt(id);
      expect(await stockOf(p), 3);
      expect(await rowsOf(id, 'void'), isEmpty);
    });

    test('a second refund does not restock again', () async {
      final p = await seedProduct(db, sku: 'P', stock: 10);
      final id = await sell(db, audit, [line(p, qty: 4)]); // total 20
      await refund(id, 5);
      expect(await stockOf(p), 10);

      final second = await refund(id, 5);
      expect(second.restocked.any, isFalse, reason: 'nothing left owed');
      expect(await stockOf(p), 10);
      expect((await rowsOf(id, 'return')).single.delta, 4);
      expect((await db.select(db.returns).get()).map((r) => r.restock),
          [true, false]);
    });

    test('a refund without restock leaves it all owed to a later void',
        () async {
      final p = await seedProduct(db, sku: 'P', stock: 10);
      final id = await sell(db, audit, [line(p, qty: 4)]);
      await refund(id, 5, restock: false);
      expect(await stockOf(p), 6);
      await voidIt(id);
      expect(await stockOf(p), 10);
    });

    test('Stock tracking switched off since: still restored', () async {
      final p = await seedProduct(db, sku: 'P', stock: 10);
      final v = await sell(db, audit, [line(p, qty: 3)]);
      final r = await sell(db, audit, [line(p, qty: 2)]);
      expect(await stockOf(p), 5);

      await voidIt(v, trackStock: false);
      await refund(r, 10, trackStock: false);

      expect(await stockOf(p), 10);
      expect((await rowsOf(v, 'void')).single.delta, 3);
      expect((await rowsOf(r, 'return')).single.delta, 2);
    });

    test('a product untracked since is refused by restock(), and not logged',
        () async {
      final tea = await seedProduct(db, sku: 'TEA', stock: 10);
      final cake = await seedProduct(db, sku: 'CAKE', stock: 10);
      final id = await sell(db, audit, [line(tea, qty: 3), line(cake)]);
      // The owner switches "Track stock" off on the tea: stock 0, no flag.
      await db.productsDao.updateProduct(
          tea,
          const ProductsCompanion(
              stockQuantity: Value(0), isOutOfStock: Value(false)));

      await voidIt(id);

      expect(await stockOf(tea), 0, reason: 'stays untracked');
      expect(await stockOf(cake), 10);
      final voids = await rowsOf(id, 'void');
      expect(voids.map((a) => (a.productId, a.delta)), [(cake, 1)],
          reason: 'only what restock() put back is logged');
    });

    test('a product that no longer exists is skipped, without an FK crash',
        () async {
      final tea = await seedProduct(db, sku: 'TEA', stock: 10);
      final cake = await seedProduct(db, sku: 'CAKE', stock: 10);
      final id = await sell(db, audit, [line(tea, qty: 3), line(cake)]);
      await db.customStatement('PRAGMA foreign_keys = OFF');
      await db.customStatement('DELETE FROM products WHERE id = $tea');
      await db.customStatement('PRAGMA foreign_keys = ON');
      expect(await db.inventoryDao.stockToRestock(id), {tea: 3, cake: 1});

      await voidIt(id);

      expect(await stockOf(cake), 10);
      expect((await rowsOf(id, 'void')).map((a) => a.productId), [cake]);
      expect((await db.ordersDao.getById(id))!.status, 'voided');
    });

    test('a sale made while tracking was off restocks nothing', () async {
      final p = await seedProduct(db, sku: 'P', stock: 10);
      final id = await sell(db, audit, [line(p, qty: 3)], trackStock: false);
      await refund(id, 15);
      expect(await stockOf(p), 10);
      expect((await db.select(db.returns).get()).single.restock, isFalse,
          reason: 'nothing was owed, so nothing restocked');
    });
  });

  /// A pre-v16 order (stock_linked NULL): 3 × [productId], with no rows.
  Future<int> legacyOrder(int productId, {String prefix = ''}) async {
    final id = await db.ordersDao.insertOrder(OrdersCompanion.insert(
        subtotal: 15,
        total: 15,
        paymentMethod: 'cash',
        invoicePrefix: Value(prefix)));
    await db.ordersDao.insertItems([
      OrderItemsCompanion.insert(
          orderId: id,
          productId: productId,
          productName: 'P',
          unitPrice: 5,
          quantity: 3,
          lineTotal: 15),
    ]);
    expect((await db.ordersDao.getById(id))!.stockLinked, isNull);
    return id;
  }

  group('legacy order, not imported: by lines while tracking is on', () {
    for (final track in [true, false]) {
      test('void, tracking ${track ? 'on' : 'off'}', () async {
        final p = await seedProduct(db, sku: 'P', stock: 7);
        final id = await legacyOrder(p);
        await voidIt(id, trackStock: track);
        expect(await stockOf(p), track ? 10 : 7);
      });

      test('refund with restock, tracking ${track ? 'on' : 'off'}', () async {
        final p = await seedProduct(db, sku: 'P', stock: 7);
        final id = await legacyOrder(p);
        await refund(id, 15, trackStock: track);
        expect(await stockOf(p), track ? 10 : 7);
        expect((await db.select(db.returns).get()).single.restock, track);
      });
    }

    test('a restocking refund then a void restocks once', () async {
      final p = await seedProduct(db, sku: 'P', stock: 7);
      final id = await legacyOrder(p);
      await refund(id, 5);
      await voidIt(id);
      expect(await stockOf(p), 10);
    });
  });

  group('legacy IMP order the till placed (audit order/place): by lines', () {
    Future<int> placedImp(int p) async {
      final id = await legacyOrder(p, prefix: kImportedInvoicePrefix);
      await audit.orderPlaced(id, total: 15, paymentMethod: 'cash');
      return id;
    }

    for (final track in [true, false]) {
      test('void, tracking ${track ? 'on' : 'off'}', () async {
        final p = await seedProduct(db, sku: 'P', stock: 7);
        final id = await placedImp(p);
        final r = await voidIt(id, trackStock: track);
        expect(await stockOf(p), track ? 10 : 7);
        expect(r.units, track ? 3 : 0);
      });

      test('refund with restock, tracking ${track ? 'on' : 'off'}', () async {
        final p = await seedProduct(db, sku: 'P', stock: 7);
        final id = await placedImp(p);
        await refund(id, 15, trackStock: track);
        expect(await stockOf(p), track ? 10 : 7);
      });
    }

    test('a place entry far from the order time does not count', () async {
      final p = await seedProduct(db, sku: 'P', stock: 7);
      final id = await legacyOrder(p, prefix: kImportedInvoicePrefix);
      await db.auditDao.log(AuditLogCompanion.insert(
          entityType: 'order',
          entityId: Value(id),
          action: 'place',
          createdAt: Value(DateTime.now().subtract(const Duration(days: 30)))));
      await voidIt(id);
      expect(await stockOf(p), 7, reason: 'still an import');
    });
  });

  group('legacy order with a lowercase "imp" prefix: the normal rule', () {
    for (final track in [true, false]) {
      test('void, tracking ${track ? 'on' : 'off'}', () async {
        final p = await seedProduct(db, sku: 'P', stock: 7);
        final id = await legacyOrder(p, prefix: 'imp');
        await voidIt(id, trackStock: track);
        expect(await stockOf(p), track ? 10 : 7);
      });
    }
  });

  group('legacy CSV import (IMP): never restocked', () {
    test('void restocks nothing, tracking on', () async {
      final p = await seedProduct(db, sku: 'P', stock: 7);
      final id = await legacyOrder(p, prefix: kImportedInvoicePrefix);
      await voidIt(id);
      expect(await stockOf(p), 7);
      expect(await db.inventoryDao.getAdjustmentsForOrder(id), isEmpty);
      expect((await db.ordersDao.getById(id))!.status, 'voided');
    });

    test('refund asking to restock restocks nothing', () async {
      final p = await seedProduct(db, sku: 'P', stock: 7);
      final id = await legacyOrder(p, prefix: kImportedInvoicePrefix);
      await refund(id, 15);
      expect(await stockOf(p), 7);
      expect((await db.select(db.returns).get()).single.restock, isFalse);
    });
  });
}
