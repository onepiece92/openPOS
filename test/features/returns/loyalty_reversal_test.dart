import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/returns/domain/process_return.dart';
import 'package:pos_app/features/returns/domain/void_order.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// Void / full refund hand back redeemed points and take back earned ones.
void main() {
  late AppDatabase db;
  late AuditService audit;
  late int p;

  setUp(() async {
    db = openInMemoryDatabase();
    audit = AuditService(db);
    p = await seedProduct(db, sku: 'A', stock: 100, price: 50);
  });
  tearDown(() => db.close());

  /// 100 pts → redeem 30 (worth 30), earn 7 → balance 77, total 70.
  Future<(int customer, int order)> loyaltySale() async {
    final c = await seedCustomer(db, points: 100);
    final o = await sell(db, audit, [line(p, qty: 2, price: 50)],
        customerId: c,
        pointsRedeemed: 30,
        loyaltyDiscount: 30,
        pointsToEarn: 7);
    expect(await points(db, c), 77);
    return (c, o);
  }

  test('void returns redeemed points and removes earned points', () async {
    final (c, o) = await loyaltySale();
    await voidOrder(db, audit, orderId: o, reason: 't');
    expect(await points(db, c), 100);
  });

  test('full refund returns redeemed points and removes earned points',
      () async {
    final (c, o) = await loyaltySale();
    await processReturn(db, audit, orderId: o, amount: 70, restock: false);
    expect(await points(db, c), 100);
  });

  test('partial refund leaves loyalty alone', () async {
    final (c, o) = await loyaltySale();
    await processReturn(db, audit, orderId: o, amount: 20, restock: false);
    expect(await points(db, c), 77);
  });

  test('partial refunds that add up to the total reverse loyalty once',
      () async {
    final (c, o) = await loyaltySale();
    await processReturn(db, audit, orderId: o, amount: 20, restock: false);
    await processReturn(db, audit, orderId: o, amount: 50, restock: false);
    expect(await points(db, c), 100);
  });

  test('taking back earned points never drives the balance negative',
      () async {
    final c = await seedCustomer(db, points: 0);
    final o = await sell(db, audit, [line(p, qty: 1, price: 50)],
        customerId: c, pointsToEarn: 5);
    // The customer spends the earned points elsewhere before the void.
    await db.customersDao.redeemLoyaltyPoints(c, 4);
    expect(await points(db, c), 1);

    await voidOrder(db, audit, orderId: o, reason: 't');
    expect(await points(db, c), 0);
  });

  test('an order without a customer voids cleanly', () async {
    final o = await sell(db, audit, [line(p)]);
    await voidOrder(db, audit, orderId: o, reason: 't');
    expect((await db.ordersDao.getById(o))!.status, 'voided');
  });
}
