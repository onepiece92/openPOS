import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/cart/data/place_order.dart';
import 'package:pos_app/features/cart/data/ticket_sequence.dart';
import 'package:pos_app/features/cart/domain/cart_calculator.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// Loyalty redemption belongs to one customer on one ticket, and never burns
/// more points than the order can use.
void main() {
  CartItem item(double price) => CartItem(
        productId: 1,
        name: 'Item',
        unitPrice: price,
        quantity: 1,
        isTaxable: false,
      );

  CartSession session({int? customerId, int redeem = 0}) => CartSession(
        ticketNumber: '#0001',
        openedAt: DateTime(2026, 1, 1),
        customerId: customerId,
        loyaltyPointsToRedeem: redeem,
      );

  group('calculator', () {
    test('no customer means no loyalty discount', () {
      final s = CartCalculator.compute(
        items: [item(100)],
        session: session(redeem: 30),
        selectedRates: const [],
        loyaltyEnabled: true,
        loyaltyPointValue: 1,
      );
      expect(s.loyaltyDiscount, 0);
      expect(s.total, 100);
    });
  });

  group('placing the order', () {
    late AppDatabase db;
    setUp(() => db = openInMemoryDatabase());
    tearDown(() => db.close());

    test('charges the customer the capped points, not the typed ones',
        () async {
      final customer = await seedCustomer(db, points: 500);
      final p = await seedProduct(db, sku: 'A', price: 10);
      // A stale session asks for 500 points on a 10.00 order.
      final stale = session(customerId: customer, redeem: 500);
      final summary = CartCalculator.compute(
        items: [item(10)],
        session: stale,
        selectedRates: const [],
        loyaltyEnabled: true,
        loyaltyPointValue: 1,
        customerLoyaltyPoints: 500,
      );
      final orderId = await placeOrder(
        db,
        AuditService(db),
        cart: [line(p, price: 10)],
        summary: summary,
        session: stale,
        paymentMethod: 'cash',
        tenderedAmount: 0,
      );

      expect(await points(db, customer), 490);
      final order = (await db.ordersDao.getById(orderId))!;
      expect(order.pointsRedeemed, 10);
      expect(order.loyaltyDiscount, 10);
    });
  });

  group('session', () {
    late Directory tmp;
    late ProviderContainer c;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('pos_loyalty_');
      Hive.init(tmp.path);
      final box = await Hive.openBox<dynamic>('held_orders');
      await Hive.openBox<dynamic>('settings');
      c = ProviderContainer(
          overrides: [heldOrdersBoxProvider.overrideWithValue(box)]);
    });
    tearDown(() async {
      c.dispose();
      await Hive.close();
      await tmp.delete(recursive: true);
    });

    CartSessionNotifier n() => c.read(cartSessionProvider.notifier);
    int redeem() => c.read(cartSessionProvider).loyaltyPointsToRedeem;

    test('switching customer clears the redemption', () {
      n().setCustomer(1);
      n().setLoyaltyPoints(40);
      n().setCustomer(2);
      expect(redeem(), 0);
    });

    test('removing the customer clears the redemption', () {
      n().setCustomer(1);
      n().setLoyaltyPoints(40);
      n().setCustomer(null);
      expect(redeem(), 0);
    });

    test('re-selecting the same customer keeps the redemption', () {
      n().setCustomer(1);
      n().setLoyaltyPoints(40);
      n().setCustomer(1);
      expect(redeem(), 40);
    });
  });
}
