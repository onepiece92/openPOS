import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/returns/domain/process_return.dart';
import 'package:pos_app/features/returns/domain/void_order.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// A partial refund reduces revenue by the refunded amount only; an order
/// becomes `refunded` only once fully refunded.
void main() {
  late AppDatabase db;
  late AuditService audit;
  late int p;
  final from = DateTime(2000);
  final to = DateTime(2100);

  setUp(() async {
    db = openInMemoryDatabase();
    audit = AuditService(db);
    p = await seedProduct(db, sku: 'A', stock: 100, price: 10);
  });
  tearDown(() => db.close());

  Future<int> sale100({String method = 'cash'}) =>
      sell(db, audit, [line(p, qty: 10, price: 10)], paymentMethod: method);
  Future<String> status(int o) async => (await db.ordersDao.getById(o))!.status;
  Future<void> refund(int o, double amount, {bool restock = false}) =>
      processReturn(db, audit, orderId: o, amount: amount, restock: restock);

  group('status', () {
    test('partial refund keeps the order completed', () async {
      final o = await sale100();
      await refund(o, 30);
      expect(await status(o), 'completed');
    });

    test('full refund marks the order refunded', () async {
      final o = await sale100();
      await refund(o, 100);
      expect(await status(o), 'refunded');
    });

    test('partial refunds adding up to the total mark it refunded', () async {
      final o = await sale100();
      await refund(o, 30);
      await refund(o, 70);
      expect(await status(o), 'refunded');
    });
  });

  group('validation', () {
    test('zero and negative amounts are rejected', () async {
      final o = await sale100();
      await expectLater(refund(o, 0), throwsA(anything));
      await expectLater(refund(o, -5), throwsA(anything));
      expect(await db.select(db.returns).get(), isEmpty);
      expect(await status(o), 'completed');
    });

    test('an amount above the order total is rejected', () async {
      final o = await sale100();
      await expectLater(refund(o, 100.01), throwsA(anything));
      expect(await db.select(db.returns).get(), isEmpty);
    });

    test('cumulative refunds may not exceed the order total', () async {
      final o = await sale100();
      await refund(o, 60);
      await expectLater(refund(o, 40.01), throwsA(anything));
      expect(await db.select(db.returns).get(), hasLength(1));
      expect(await status(o), 'completed');
    });
  });

  group('guards', () {
    test('a fully refunded order cannot be refunded again', () async {
      final o = await sale100();
      await refund(o, 100);
      await expectLater(refund(o, 1), throwsA(anything));
      expect(await db.select(db.returns).get(), hasLength(1));
    });

    test('a voided order cannot be refunded', () async {
      final o = await sale100();
      await voidOrder(db, audit, orderId: o, reason: 't');
      await expectLater(refund(o, 10), throwsA(anything));
      expect(await db.select(db.returns).get(), isEmpty);
    });

    test('an order cannot be voided twice', () async {
      final o = await sale100();
      await voidOrder(db, audit, orderId: o, reason: 't');
      await expectLater(
          voidOrder(db, audit, orderId: o, reason: 't'), throwsStateError);
      expect((await product(db, p)).stockQuantity, 100);
    });

    test('a fully refunded order cannot be voided', () async {
      final o = await sale100();
      await refund(o, 100, restock: true);
      await expectLater(
          voidOrder(db, audit, orderId: o, reason: 't'), throwsStateError);
      expect(await status(o), 'refunded');
      expect((await product(db, p)).stockQuantity, 100,
          reason: 'stock must not be restored a second time');
    });

    test('stock is restored at most once across refunds and a void',
        () async {
      final o = await sale100();
      expect((await product(db, p)).stockQuantity, 90);
      await refund(o, 30, restock: true);
      expect((await product(db, p)).stockQuantity, 100);

      await expectLater(refund(o, 30, restock: true), throwsA(anything));
      await voidOrder(db, audit, orderId: o, reason: 't');
      expect((await product(db, p)).stockQuantity, 100);
    });
  });

  group('reports are net of refunds', () {
    test('revenue', () async {
      final a = await sale100();
      await sale100();
      await refund(a, 30);
      expect(await db.ordersDao.totalRevenueForPeriod(from, to), 170);
    });

    test('a fully refunded order contributes nothing', () async {
      final a = await sale100();
      await sale100();
      await refund(a, 100);
      expect(await db.ordersDao.totalRevenueForPeriod(from, to), 100);
      expect(await db.ordersDao.completedOrdersInPeriod(from, to),
          hasLength(1));
    });

    test('a voided order contributes nothing even if partly refunded',
        () async {
      final a = await sale100();
      await refund(a, 30);
      await voidOrder(db, audit, orderId: a, reason: 't');
      expect(await db.ordersDao.totalRevenueForPeriod(from, to), 0);
    });

    test('chart rows carry the net amount on the sale date', () async {
      final a = await sale100();
      await refund(a, 30);
      final rows = await db.ordersDao.completedOrdersInPeriod(from, to);
      expect(rows.single.total, 70);
      expect(rows.single.createdAt,
          (await db.ordersDao.getById(a))!.createdAt);
    });

    test('payment breakdown', () async {
      final a = await sale100(method: 'card');
      await sale100(method: 'card');
      await sale100(method: 'cash');
      await refund(a, 30);
      final rows = await db.ordersDao.paymentBreakdownForPeriod(from, to);
      final card = rows.firstWhere((r) => r['method'] == 'card');
      final cash = rows.firstWhere((r) => r['method'] == 'cash');
      expect(card['total'], 170);
      expect(card['count'], 2);
      expect(cash['total'], 100);
    });

    test('legacy rows: a "refunded" order whose refund was partial counts net',
        () async {
      // Before this change every refund flipped the order to `refunded`.
      final a = await sale100();
      await db.ordersDao.insertReturn(
          ReturnsCompanion.insert(orderId: a, amount: 30));
      await db.ordersDao.refundOrder(a);
      expect(await db.ordersDao.totalRevenueForPeriod(from, to), 70);
    });

    test('legacy rows: a refund larger than the order never goes negative',
        () async {
      final a = await sale100();
      await db.ordersDao.insertReturn(
          ReturnsCompanion.insert(orderId: a, amount: 250));
      await db.ordersDao.refundOrder(a);
      expect(await db.ordersDao.totalRevenueForPeriod(from, to), 0);
      expect(await db.ordersDao.completedOrdersInPeriod(from, to), isEmpty);
    });
  });
}
