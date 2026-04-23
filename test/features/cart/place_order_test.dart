import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/cart_notifier.dart';
import 'package:pos_app/features/cart/domain/place_order.dart';

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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<int> seedProduct({
    required String sku,
    required String name,
    double price = 10.0,
    int stock = 10,
    bool composite = false,
  }) {
    return db.productsDao.upsert(
      ProductsCompanion.insert(
        sku: sku,
        name: name,
        price: price,
        stockQuantity: Value(stock),
        isComposite: Value(composite),
      ),
    );
  }

  CartItem makeItem(int productId, {int qty = 1, double price = 5.0}) =>
      CartItem(
        productId: productId,
        name: 'Item $productId',
        unitPrice: price,
        quantity: qty,
        isTaxable: false,
      );

  CartSession makeSession({int? customerId, int redeem = 0}) => CartSession(
        ticketNumber: '#0001',
        openedAt: DateTime(2026, 1, 1),
        customerId: customerId,
        loyaltyPointsToRedeem: redeem,
      );

  CartSummary makeSummary({
    required double subtotal,
    List<TaxLine> taxLines = const [],
    double taxAmount = 0,
    bool taxEnabled = false,
    int pointsToEarn = 0,
  }) =>
      CartSummary(
        subtotal: subtotal,
        orderDiscount: 0,
        loyaltyDiscount: 0,
        taxLines: taxLines,
        taxAmount: taxAmount,
        total: subtotal + taxAmount,
        taxEnabled: taxEnabled,
        pointsToEarn: pointsToEarn,
      );

  // ── Tests ──────────────────────────────────────────────────────────────────

  test('happy path: order, items, stock deduction, audit log all persist',
      () async {
    final productId =
        await seedProduct(sku: 'COFFEE', name: 'Coffee', stock: 10);

    final orderId = await placeOrder(
      db,
      audit,
      cart: [makeItem(productId, qty: 2, price: 5.0)],
      summary: makeSummary(subtotal: 10.0),
      session: makeSession(),
      paymentMethod: 'cash',
      tenderedAmount: 10.0,
    );

    expect(orderId, greaterThan(0));

    final order = await db.ordersDao.getById(orderId);
    expect(order, isNotNull);
    expect(order!.total, 10.0);
    expect(order.paymentMethod, 'cash');

    final items = await db.ordersDao.getItems(orderId);
    expect(items, hasLength(1));
    expect(items.first.quantity, 2);

    final product = await db.productsDao.getById(productId);
    expect(product!.stockQuantity, 8,
        reason: 'stock should deduct from 10 to 8');

    final adjustments =
        await db.inventoryDao.getAdjustmentsForProduct(productId);
    expect(adjustments, hasLength(1));
    expect(adjustments.first.delta, -2);
    expect(adjustments.first.reasonCode, 'sale');
    expect(adjustments.first.notes, contains('Order #$orderId'));

    final auditRows = await db.select(db.auditLog).get();
    expect(auditRows, hasLength(1));
    expect(auditRows.first.entityType, 'order');
    expect(auditRows.first.entityId, orderId);
    expect(auditRows.first.action, 'place');
  });

  test('rollback: mid-transaction failure leaves DB untouched', () async {
    final productId =
        await seedProduct(sku: 'COFFEE', name: 'Coffee', stock: 10);

    // Force a foreign-key failure: tax_rate_id=9999 doesn't exist.
    const summaryWithBadTax = CartSummary(
      subtotal: 10,
      orderDiscount: 0,
      loyaltyDiscount: 0,
      taxLines: [
        TaxLine(
          taxRateId: 9999,
          name: 'VAT',
          rate: 0.13,
          amount: 1.30,
          isInclusive: false,
          taxableAmount: 10,
        ),
      ],
      taxAmount: 1.30,
      total: 11.30,
      taxEnabled: true,
      pointsToEarn: 0,
    );

    await expectLater(
      placeOrder(
        db,
        audit,
        cart: [makeItem(productId, qty: 2, price: 5.0)],
        summary: summaryWithBadTax,
        session: makeSession(),
        paymentMethod: 'cash',
        tenderedAmount: 20.0,
      ),
      throwsA(anything),
    );

    // Nothing persisted.
    final orders = await db.select(db.orders).get();
    expect(orders, isEmpty, reason: 'order row must roll back');

    final orderItems = await db.select(db.orderItems).get();
    expect(orderItems, isEmpty, reason: 'items must roll back');

    final adjustments = await db.select(db.stockAdjustments).get();
    expect(adjustments, isEmpty, reason: 'audit log must roll back');

    final product = await db.productsDao.getById(productId);
    expect(product!.stockQuantity, 10,
        reason: 'stock must be untouched by a failed transaction');
  });

  test('composite product deducts components, not the composite', () async {
    final espressoId =
        await seedProduct(sku: 'ESP', name: 'Espresso Shot', stock: 100);
    final milkId =
        await seedProduct(sku: 'MLK', name: 'Milk', stock: 50);
    final latteId = await seedProduct(
        sku: 'LAT', name: 'Latte', stock: 0, composite: true);

    await db.productsDao.replaceComponents(latteId, [
      ProductComponentsCompanion.insert(
        compositeProductId: latteId,
        componentProductId: espressoId,
        quantity: const Value(1),
      ),
      ProductComponentsCompanion.insert(
        compositeProductId: latteId,
        componentProductId: milkId,
        quantity: const Value(1),
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
          quantity: 3,
          isTaxable: false,
        ),
      ],
      summary: makeSummary(subtotal: 15.0),
      session: makeSession(),
      paymentMethod: 'cash',
      tenderedAmount: 15.0,
    );

    expect(orderId, greaterThan(0));

    // Composite itself is not deducted.
    final latte = await db.productsDao.getById(latteId);
    expect(latte!.stockQuantity, 0, reason: 'composite stock stays unlimited');

    // Components are deducted.
    final espresso = await db.productsDao.getById(espressoId);
    expect(espresso!.stockQuantity, 97, reason: '3 lattes × 1 shot = 3');

    final milk = await db.productsDao.getById(milkId);
    expect(milk!.stockQuantity, 47, reason: '3 lattes × 1 milk = 3');

    // Audit log has one row per component, with composite context in notes.
    final espressoLog =
        await db.inventoryDao.getAdjustmentsForProduct(espressoId);
    expect(espressoLog, hasLength(1));
    expect(espressoLog.first.notes, contains('via Latte'));

    final latteLog = await db.inventoryDao.getAdjustmentsForProduct(latteId);
    expect(latteLog, isEmpty,
        reason: 'composite itself is not audit-logged separately');
  });
}
