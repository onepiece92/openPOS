import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/data/place_order.dart';
import 'package:pos_app/features/returns/domain/void_order.dart';

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

  Future<int> seedProduct({
    required String sku,
    required String name,
    int stock = 10,
    bool composite = false,
  }) =>
      db.productsDao.upsert(
        ProductsCompanion.insert(
          sku: sku,
          name: name,
          price: 5.0,
          stockQuantity: Value(stock),
          isComposite: Value(composite),
        ),
      );

  Future<int> placeSimple(int productId, {int qty = 2}) => placeOrder(
        db,
        audit,
        cart: [
          CartItem(
            productId: productId,
            name: 'Item',
            unitPrice: 5.0,
            quantity: qty,
            isTaxable: false,
          ),
        ],
        summary: CartSummary(
          subtotal: 5.0 * qty,
          orderDiscount: 0,
          loyaltyDiscount: 0,
          taxLines: const [],
          taxAmount: 0,
          total: 5.0 * qty,
          taxEnabled: false,
          pointsToEarn: 0,
        ),
        session: CartSession(
          ticketNumber: '#0001',
          openedAt: DateTime(2026, 1, 1),
          customerId: null,
          loyaltyPointsToRedeem: 0,
        ),
        paymentMethod: 'cash',
        tenderedAmount: 5.0 * qty,
      );

  test('void reverses stock, flips status, writes audit entry', () async {
    final productId = await seedProduct(sku: 'COFFEE', name: 'Coffee', stock: 10);
    final orderId = await placeSimple(productId, qty: 3);

    expect((await db.productsDao.getById(productId))!.stockQuantity, 7);

    await voidOrder(db, audit, orderId: orderId, reason: 'wrong order');

    // Stock fully restored
    expect((await db.productsDao.getById(productId))!.stockQuantity, 10);

    // Status flipped
    expect((await db.ordersDao.getById(orderId))!.status, 'voided');

    // Audit log: place + void
    final auditRows = await db.select(db.auditLog).get();
    expect(auditRows, hasLength(2));
    expect(auditRows.last.action, 'void');
    expect(auditRows.last.entityId, orderId);

    // Stock adjustment with reason 'void'
    final adjustments =
        await db.inventoryDao.getAdjustmentsForProduct(productId);
    expect(adjustments, hasLength(2));
    expect(adjustments.firstWhere((a) => a.reasonCode == 'void').delta, 3);
  });

  test('void of composite order restocks components', () async {
    final espressoId = await seedProduct(sku: 'ESP', name: 'Espresso', stock: 100);
    final milkId = await seedProduct(sku: 'MLK', name: 'Milk', stock: 50);
    final latteId =
        await seedProduct(sku: 'LAT', name: 'Latte', stock: 0, composite: true);

    await db.productsDao.replaceComponents(latteId, [
      ProductComponentsCompanion.insert(
        compositeProductId: latteId,
        componentProductId: espressoId,
      ),
      ProductComponentsCompanion.insert(
        compositeProductId: latteId,
        componentProductId: milkId,
      ),
    ]);

    final orderId = await placeOrder(
      db,
      audit,
      cart: [
        CartItem(
          productId: latteId,
          name: 'Latte',
          unitPrice: 5.0,
          quantity: 2,
          isTaxable: false,
        ),
      ],
      summary: const CartSummary(
        subtotal: 10.0,
        orderDiscount: 0,
        loyaltyDiscount: 0,
        taxLines: [],
        taxAmount: 0,
        total: 10.0,
        taxEnabled: false,
        pointsToEarn: 0,
      ),
      session: CartSession(
        ticketNumber: '#0001',
        openedAt: DateTime(2026, 1, 1),
        customerId: null,
        loyaltyPointsToRedeem: 0,
      ),
      paymentMethod: 'cash',
      tenderedAmount: 10.0,
    );

    expect((await db.productsDao.getById(espressoId))!.stockQuantity, 98);
    expect((await db.productsDao.getById(milkId))!.stockQuantity, 48);

    await voidOrder(db, audit, orderId: orderId, reason: 'kitchen mistake');

    expect((await db.productsDao.getById(espressoId))!.stockQuantity, 100);
    expect((await db.productsDao.getById(milkId))!.stockQuantity, 50);
    expect((await db.productsDao.getById(latteId))!.stockQuantity, 0);
  });

  test('voiding an already-voided order throws and persists nothing extra',
      () async {
    final productId = await seedProduct(sku: 'COFFEE', name: 'Coffee', stock: 10);
    final orderId = await placeSimple(productId, qty: 2);

    await voidOrder(db, audit, orderId: orderId, reason: 'first void');

    // Snapshot state after first void
    final auditCountAfterFirst = (await db.select(db.auditLog).get()).length;

    expect(
      () => voidOrder(db, audit, orderId: orderId, reason: 'second void'),
      throwsStateError,
    );

    // No new audit row
    expect(
      (await db.select(db.auditLog).get()).length,
      auditCountAfterFirst,
    );
  });

  test('void on missing order throws and persists nothing', () async {
    expect(
      () => voidOrder(db, audit, orderId: 9999, reason: 'ghost'),
      throwsStateError,
    );

    expect(await db.select(db.auditLog).get(), isEmpty);
  });
}
