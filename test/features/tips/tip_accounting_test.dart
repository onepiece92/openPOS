import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/cart/data/place_order.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/returns/domain/process_return.dart';
import 'package:pos_app/features/returns/domain/void_order.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

void main() {
  // The figures test opens a second, control database on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuditService audit;
  late int pid;
  final from = DateTime(2020);
  final to = DateTime(2100);

  setUp(() async {
    db = openInMemoryDatabase();
    audit = AuditService(db);
    pid = await seedProduct(db, sku: 'T', stock: 100, price: 100);
  });
  tearDown(() => db.close());

  /// A 100.00 sale (VAT 13 inside, so a total of 100) with [tip].
  Future<int> sale({double tip = 0, String method = 'cash'}) {
    final items = [line(pid, price: 100)];
    return placeOrder(
      db,
      audit,
      cart: items,
      summary: const CartSummary(
        subtotal: 100,
        orderDiscount: 0,
        loyaltyDiscount: 0,
        taxLines: [],
        taxAmount: 0,
        total: 100,
        taxEnabled: false,
        pointsToEarn: 0,
      ),
      session: CartSession(ticketNumber: '#1', openedAt: DateTime(2026, 1, 1)),
      paymentMethod: method,
      tenderedAmount: 100 + tip,
      tipAmount: tip,
    );
  }

  Future<double> netTips() => db.ordersDao.netTipsForPeriod(from, to);
  Future<List<Return>> returnsOf(int id) =>
      (db.select(db.returns)..where((r) => r.orderId.equals(id))).get();

  group('placeOrder', () {
    test('writes tip_amount; total stays tip-free; change counts the tip',
        () async {
      final id = await sale(tip: 15);
      final o = (await db.ordersDao.getById(id))!;
      expect(o.tipAmount, 15);
      expect(o.total, 100);
      expect(o.tenderedAmount, 115);
      expect(o.changeAmount, 0);
    });

    test('no tip, and a negative one, store 0', () async {
      expect((await db.ordersDao.getById(await sale()))!.tipAmount, 0);
      final id = await placeOrder(db, audit,
          cart: [line(pid)],
          summary: CartSummary.zero,
          session: CartSession(
              ticketNumber: '#2', openedAt: DateTime(2026, 1, 1)),
          paymentMethod: 'cash',
          tenderedAmount: 0,
          tipAmount: -5);
      expect((await db.ordersDao.getById(id))!.tipAmount, 0);
    });
  });

  group('refunds', () {
    test('partial refund keeps the tip by default', () async {
      final id = await sale(tip: 15);
      await processReturn(db, audit,
          orderId: id, amount: 40, restock: false);
      expect((await returnsOf(id)).single.tipAmount, 0);
      expect(await netTips(), 15);
    });

    test('partial refund with "also refund tip" returns the whole tip left',
        () async {
      final id = await sale(tip: 15);
      await processReturn(db, audit,
          orderId: id, amount: 40, restock: false, refundTip: true);
      expect((await returnsOf(id)).single.tipAmount, 15);
      expect(await netTips(), 0);
      // A later partial refund cannot return it a second time.
      await processReturn(db, audit,
          orderId: id, amount: 10, restock: false, refundTip: true);
      expect((await returnsOf(id)).last.tipAmount, 0);
    });

    test('refundable amount stays the goods only', () async {
      final id = await sale(tip: 15);
      final order = (await db.ordersDao.getById(id))!;
      expect(await refundableAmount(db, order), 100);
      await processReturn(db, audit,
          orderId: id, amount: 40, restock: false, refundTip: true);
      expect(await refundableAmount(db, order), 60);
    });

    test('the refund that completes the amount returns the remaining tip',
        () async {
      final id = await sale(tip: 15);
      await processReturn(db, audit,
          orderId: id, amount: 40, restock: false);
      await processReturn(db, audit,
          orderId: id, amount: 60, restock: false);
      final rs = await returnsOf(id);
      expect(rs.first.tipAmount, 0);
      expect(rs.last.tipAmount, 15);
      expect((await db.ordersDao.getById(id))!.status, 'refunded');
      expect(await netTips(), 0);
    });

    test('a single full refund returns the tip', () async {
      final id = await sale(tip: 15);
      await processReturn(db, audit,
          orderId: id, amount: 100, restock: false);
      expect((await returnsOf(id)).single.tipAmount, 15);
      expect(await netTips(), 0);
    });

    test('refund of an untipped order writes tip 0', () async {
      final id = await sale();
      await processReturn(db, audit,
          orderId: id, amount: 100, restock: false, refundTip: true);
      expect((await returnsOf(id)).single.tipAmount, 0);
    });
  });

  group('voids', () {
    test('a void removes the tip from tip totals', () async {
      final keep = await sale(tip: 5);
      final gone = await sale(tip: 20);
      expect(await netTips(), 25);
      await voidOrder(db, audit, orderId: gone, reason: 'mistake');
      expect(await netTips(), 5);
      expect((await db.ordersDao.getById(keep))!.status, 'completed');
    });

    test('a void after a tip refund does not subtract it twice', () async {
      final a = await sale(tip: 20);
      final b = await sale(tip: 5);
      await processReturn(db, audit,
          orderId: a, amount: 10, restock: false, refundTip: true);
      expect(await netTips(), 5);
      await voidOrder(db, audit, orderId: a, reason: 'x');
      expect(await netTips(), 5, reason: 'voided order and its refund are out');
      expect((await db.ordersDao.getById(b))!.tipAmount, 5);
    });
  });

  group('figures', () {
    test('tips never change revenue, VAT, cost or the payment mix', () async {
      Future<List<Object>> figures() async => [
            await db.ordersDao.totalRevenueForPeriod(from, to),
            await db.ordersDao.vatCollectedForPeriod(from, to),
            (await db.ordersDao.costOfGoodsForPeriod(from, to)).cost,
            [
              for (final r
                  in await db.ordersDao.paymentBreakdownForPeriod(from, to))
                '${r['method']}:${r['count']}:${r['total']}'
            ],
            (await db.ordersDao.completedOrdersInPeriod(from, to))
                .map((o) => o.total)
                .toList(),
          ];

      await sale();
      await sale(method: 'card');
      final before = await figures();
      expect(before.first, 200);

      await sale(tip: 17.5);
      await sale(tip: 4, method: 'card');
      final withTips = await figures();
      // Two more 100 sales: compare against the same sales with no tips.
      final control = openInMemoryDatabase();
      addTearDown(control.close);
      final cAudit = AuditService(control);
      final cp = await seedProduct(control, sku: 'T', stock: 100, price: 100);
      for (final m in ['cash', 'card', 'cash', 'card']) {
        await placeOrder(
          control,
          cAudit,
          cart: [line(cp, price: 100)],
          summary: const CartSummary(
            subtotal: 100,
            orderDiscount: 0,
            loyaltyDiscount: 0,
            taxLines: [],
            taxAmount: 0,
            total: 100,
            taxEnabled: false,
            pointsToEarn: 0,
          ),
          session:
              CartSession(ticketNumber: '#c', openedAt: DateTime(2026, 1, 1)),
          paymentMethod: m,
          tenderedAmount: 100,
        );
      }
      expect([
        await control.ordersDao.totalRevenueForPeriod(from, to),
        await control.ordersDao.vatCollectedForPeriod(from, to),
        (await control.ordersDao.costOfGoodsForPeriod(from, to)).cost,
      ], [withTips[0], withTips[1], withTips[2]]);
      expect(withTips[0], 400);
      expect(await netTips(), 21.5);
      expect(
          [
            for (final r
                in await control.ordersDao.paymentBreakdownForPeriod(from, to))
              '${r['method']}:${r['count']}:${r['total']}'
          ],
          withTips[3]);
    });
  });
}
