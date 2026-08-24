import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/cart/data/place_order.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';

import '../../_support/test_db.dart';

/// Secondary-unit selling: cart line identity, pricing, stock math and the
/// order_items snapshot.
void main() {
  Product product({
    int id = 1,
    double price = 10,
    String unit = 'pc',
    String? secondaryUnit = 'dozen',
    double conversionRate = 12,
  }) =>
      Product(
        id: id,
        sku: 'P$id',
        name: 'Eggs',
        price: price,
        purchasePrice: 0,
        unit: unit,
        secondaryUnit: secondaryUnit,
        conversionRate: conversionRate,
        stockQuantity: 100,
        isTaxable: true,
        isComposite: false,
        isHiddenInPos: false,
        isOutOfStock: false,
        isActive: true,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  group('cart lines', () {
    late ProviderContainer c;
    setUp(() => c = ProviderContainer());
    tearDown(() => c.dispose());
    CartNotifier n() => c.read(cartProvider.notifier);
    List<CartItem> cart() => c.read(cartProvider);

    test('main and secondary units are separate lines with separate prices',
        () {
      final p = product();
      n().addProduct(p);
      n().addProductInSecondaryUnit(p);
      n().addProduct(p);
      n().addProductInSecondaryUnit(p);

      expect(cart(), hasLength(2));
      final main = cart().firstWhere((i) => !i.isSecondaryUnit);
      final dozen = cart().firstWhere((i) => i.isSecondaryUnit);
      expect(main.quantity, 2);
      expect(main.unitPrice, 10);
      expect(dozen.quantity, 2);
      expect(dozen.unitLabel, 'dozen');
      expect(dozen.unitPrice, 120); // 10 × 12, rounded money
      expect(dozen.unitsPerQty, 12);
      expect(dozen.mainUnitQty, 24);
    });

    test('setQuantity / remove touch only the addressed line', () {
      final p = product();
      n().addProduct(p);
      n().addProductInSecondaryUnit(p);

      n().setQuantity(p.id, 5); // main line
      expect(cart().firstWhere((i) => !i.isSecondaryUnit).quantity, 5);
      expect(cart().firstWhere((i) => i.isSecondaryUnit).quantity, 1);

      n().setQuantity(p.id, 3, unitLabel: 'dozen');
      expect(cart().firstWhere((i) => i.isSecondaryUnit).quantity, 3);

      n().remove(p.id, unitLabel: 'dozen');
      expect(cart(), hasLength(1));
      expect(cart().single.isSecondaryUnit, isFalse);
    });

    test('addProductInSecondaryUnit is a no-op without a secondary unit', () {
      n().addProductInSecondaryUnit(product(secondaryUnit: null));
      expect(cart(), isEmpty);
    });

    test('held-order json round-trips the unit fields (and legacy defaults)',
        () {
      final ticket = HeldOrder(
        id: 't1',
        ticketNumber: '#0001',
        label: 'T',
        createdAt: DateTime(2026),
        items: [
          CartItem(
            productId: 1,
            name: 'Eggs',
            unitPrice: 120,
            quantity: 2,
            isTaxable: true,
            unitLabel: 'dozen',
            unitsPerQty: 12,
          ),
        ],
      );
      final revived = HeldOrder.fromJson(ticket.toJson());
      expect(revived.items.single.unitLabel, 'dozen');
      expect(revived.items.single.unitsPerQty, 12);

      // A ticket saved before units existed loads as main-unit lines.
      final legacy = ticket.toJson();
      (legacy['items'] as List).forEach((i) {
        (i as Map).remove('unitLabel');
        i.remove('unitsPerQty');
      });
      final old = HeldOrder.fromJson(legacy);
      expect(old.items.single.unitLabel, '');
      expect(old.items.single.unitsPerQty, 1.0);
    });
  });

  group('placeOrder with a secondary-unit line', () {
    late AppDatabase db;
    late AuditService audit;
    setUp(() {
      db = openInMemoryDatabase();
      audit = AuditService(db);
    });
    tearDown(() => db.close());

    test('deducts qty × conversion from stock and snapshots the unit',
        () async {
      final productId = await db.productsDao.upsert(ProductsCompanion.insert(
        sku: 'EGG',
        name: 'Eggs',
        price: 10,
        unit: const Value('pc'),
        secondaryUnit: const Value('dozen'),
        conversionRate: const Value(12),
        stockQuantity: const Value(100),
      ));
      final line = CartItem(
        productId: productId,
        name: 'Eggs',
        unitPrice: 120,
        quantity: 2, // 2 dozen
        isTaxable: false,
        unitLabel: 'dozen',
        unitsPerQty: 12,
      );
      final orderId = await placeOrder(
        db,
        audit,
        cart: [line],
        summary: const CartSummary(
          subtotal: 240,
          orderDiscount: 0,
          loyaltyDiscount: 0,
          taxLines: [],
          taxAmount: 0,
          total: 240,
          taxEnabled: false,
          pointsToEarn: 0,
        ),
        session: CartSession(ticketNumber: '#1', openedAt: DateTime(2026)),
        paymentMethod: 'cash',
        tenderedAmount: 240,
      );

      final stock = (await db.productsDao.getById(productId))!.stockQuantity;
      expect(stock, 76, reason: '100 − 2×12');

      final item = (await db.ordersDao.getItems(orderId)).single;
      expect(item.productName, 'Eggs (dozen)');
      expect(item.unitLabel, 'dozen');
      expect(item.unitsPerQty, 12);
      expect(item.quantity, 2);
      expect(item.unitPrice, 120);
      expect(item.lineTotal, 240);

      final adj =
          await db.inventoryDao.getAdjustmentsForProduct(productId);
      expect(adj.single.delta, -24);
    });
  });
}
