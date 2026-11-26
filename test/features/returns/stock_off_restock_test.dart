import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/orders/presentation/order_detail_screen.dart'
    show voidDialogText;
import 'package:pos_app/features/returns/domain/process_return.dart';
import 'package:pos_app/features/returns/domain/void_order.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// A sale made while Stock tracking was off deducted nothing, so its void
/// or refund puts nothing back (its own rows owe nothing). With tracking on,
/// what the sale took comes back.
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
  Future<List<StockAdjustment>> log() => db.select(db.stockAdjustments).get();

  /// Stock 10; a sale of 3 made with tracking OFF (nothing deducted).
  Future<(int, int)> soldWhileOff() async {
    final p = await seedProduct(db, sku: 'A', stock: 10);
    final order =
        await sell(db, audit, [line(p, qty: 3)], trackStock: false);
    expect(await stockOf(p), 10);
    return (p, order);
  }

  group('Stock tracking off', () {
    test('void leaves stock and the adjustment log unchanged', () async {
      final (p, order) = await soldWhileOff();
      await voidOrder(db, audit,
          orderId: order, reason: 'x', trackStock: false);
      expect(await stockOf(p), 10);
      expect(await log(), isEmpty);
      expect((await db.ordersDao.getById(order))!.status, 'voided');
    });

    test('refund with "restock" asked for leaves them unchanged too',
        () async {
      final (p, order) = await soldWhileOff();
      await processReturn(db, audit,
          orderId: order, amount: 15, restock: true, trackStock: false);
      expect(await stockOf(p), 10);
      expect(await log(), isEmpty);
      final ret = (await db.select(db.returns).get()).single;
      expect(ret.restock, isFalse, reason: 'recorded as not restocked');
    });
  });

  group('Stock tracking on: unchanged', () {
    test('void restocks', () async {
      final p = await seedProduct(db, sku: 'A', stock: 10);
      final order = await sell(db, audit, [line(p, qty: 3)]);
      expect(await stockOf(p), 7);
      await voidOrder(db, audit, trackStock: true, orderId: order, reason: 'x');
      expect(await stockOf(p), 10);
      expect((await log()).map((a) => a.reasonCode), contains('void'));
    });

    test('refund with restock restocks', () async {
      final p = await seedProduct(db, sku: 'A', stock: 10);
      final order = await sell(db, audit, [line(p, qty: 3)]);
      await processReturn(db, audit,
          orderId: order, amount: 15, restock: true, trackStock: true);
      expect(await stockOf(p), 10);
    });
  });

  group('void dialog text says only what applies', () {
    test('stock and points', () {
      expect(
          voidDialogText(restocks: true, points: true),
          'This marks the order as voided, reverses every stock deduction '
          'and reverses the loyalty points redeemed and earned on it. '
          'Composite components are restocked automatically.');
    });
    test('stock tracking off, no points', () {
      expect(voidDialogText(restocks: false, points: false),
          'This marks the order as voided.');
    });
    test('stock tracking off, with points', () {
      expect(
          voidDialogText(restocks: false, points: true),
          'This marks the order as voided and reverses the loyalty points '
          'redeemed and earned on it.');
    });
    test('stock only', () {
      expect(
          voidDialogText(restocks: true, points: false),
          'This marks the order as voided and reverses every stock deduction. '
          'Composite components are restocked automatically.');
    });
  });
}
