import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/data/place_order.dart';

import '../../_support/test_db.dart';

void main() {
  late AppDatabase db;
  late AuditService audit;

  setUp(() {
    db = openInMemoryDatabase();
    audit = AuditService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('placeOrder persists tableId on the order row', () async {
    final productId = await db.productsDao.upsert(
      ProductsCompanion.insert(
        sku: 'COFFEE',
        name: 'Coffee',
        price: 5.0,
        stockQuantity: const Value(10),
      ),
    );
    final tableId = await db.tablesDao.upsert(
      TablesCompanion.insert(name: 'T1', capacity: const Value(4)),
    );

    final orderId = await placeOrder(
      db,
      audit,
      cart: [
        CartItem(
          productId: productId,
          name: 'Coffee',
          unitPrice: 5.0,
          quantity: 1,
          isTaxable: false,
        ),
      ],
      summary: const CartSummary(
        subtotal: 5.0,
        orderDiscount: 0,
        loyaltyDiscount: 0,
        taxLines: [],
        taxAmount: 0,
        total: 5.0,
        taxEnabled: false,
        pointsToEarn: 0,
      ),
      session: CartSession(
        ticketNumber: '#0001',
        openedAt: DateTime(2026, 1, 1),
        tableId: tableId,
      ),
      paymentMethod: 'cash',
      tenderedAmount: 5.0,
    );

    final order = await db.ordersDao.getById(orderId);
    expect(order, isNotNull);
    expect(order!.tableId, tableId);
  });

  test('placeOrder leaves tableId null when session has no table', () async {
    final productId = await db.productsDao.upsert(
      ProductsCompanion.insert(
        sku: 'COFFEE',
        name: 'Coffee',
        price: 5.0,
        stockQuantity: const Value(10),
      ),
    );

    final orderId = await placeOrder(
      db,
      audit,
      cart: [
        CartItem(
          productId: productId,
          name: 'Coffee',
          unitPrice: 5.0,
          quantity: 1,
          isTaxable: false,
        ),
      ],
      summary: const CartSummary(
        subtotal: 5.0,
        orderDiscount: 0,
        loyaltyDiscount: 0,
        taxLines: [],
        taxAmount: 0,
        total: 5.0,
        taxEnabled: false,
        pointsToEarn: 0,
      ),
      session: CartSession(
        ticketNumber: '#0001',
        openedAt: DateTime(2026, 1, 1),
      ),
      paymentMethod: 'cash',
      tenderedAmount: 5.0,
    );

    final order = await db.ordersDao.getById(orderId);
    expect(order!.tableId, isNull);
  });
}
