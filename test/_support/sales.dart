import 'package:drift/drift.dart' show Value;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/cart/data/place_order.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';

/// Shared fixtures for sale / void / refund tests.

Future<int> seedProduct(
  AppDatabase db, {
  required String sku,
  int stock = 10,
  bool outOfStock = false,
  bool composite = false,
  double price = 5.0,
}) =>
    db.productsDao.upsert(
      ProductsCompanion.insert(
        sku: sku,
        name: sku,
        price: price,
        stockQuantity: Value(stock),
        isOutOfStock: Value(outOfStock),
        isComposite: Value(composite),
      ),
    );

Future<int> seedCustomer(AppDatabase db, {int points = 0}) =>
    db.customersDao.upsert(
      CustomersCompanion.insert(
        name: 'Asha',
        loyaltyPoints: Value(points),
      ),
    );

CartItem line(
  int productId, {
  int qty = 1,
  double price = 5.0,
  String unitLabel = '',
  double unitsPerQty = 1.0,
}) =>
    CartItem(
      productId: productId,
      name: 'Item $productId',
      unitPrice: price,
      quantity: qty,
      isTaxable: false,
      unitLabel: unitLabel,
      unitsPerQty: unitsPerQty,
    );

/// Places a sale of [items]; total = Σ line subtotals − [loyaltyDiscount].
Future<int> sell(
  AppDatabase db,
  AuditService audit,
  List<CartItem> items, {
  int? customerId,
  int pointsRedeemed = 0,
  double loyaltyDiscount = 0,
  int pointsToEarn = 0,
  String paymentMethod = 'cash',
  bool trackStock = true,
  String? saleKey,
}) {
  final subtotal = items.fold(0.0, (s, i) => s + i.lineSubtotal);
  final total = subtotal - loyaltyDiscount;
  return placeOrder(
    db,
    audit,
    cart: items,
    summary: CartSummary(
      subtotal: subtotal,
      orderDiscount: 0,
      loyaltyDiscount: loyaltyDiscount,
      taxLines: const [],
      taxAmount: 0,
      total: total,
      taxEnabled: false,
      pointsToEarn: pointsToEarn,
      pointsRedeemed: pointsRedeemed,
    ),
    session: CartSession(
      ticketNumber: '#0001',
      openedAt: DateTime(2026, 1, 1),
      customerId: customerId,
      loyaltyPointsToRedeem: pointsRedeemed,
    ),
    paymentMethod: paymentMethod,
    tenderedAmount: total,
    trackStock: trackStock,
    saleKey: saleKey,
  );
}

Future<Product> product(AppDatabase db, int id) async =>
    (await db.productsDao.getById(id))!;

Future<int> points(AppDatabase db, int customerId) async =>
    (await db.customersDao.getById(customerId))!.loyaltyPoints;
