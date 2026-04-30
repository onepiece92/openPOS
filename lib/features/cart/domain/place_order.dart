import 'package:drift/drift.dart' show Value;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/cart_notifier.dart';

/// Atomically commits a completed sale. Returns the new order ID.
///
/// All DB writes run inside a single transaction — if any step fails,
/// nothing persists (no phantom orders, stock untouched, loyalty intact).
/// Throws on any failure; caller is responsible for UI error handling.
Future<int> placeOrder(
  AppDatabase db,
  AuditService audit, {
  required List<CartItem> cart,
  required CartSummary summary,
  required CartSession session,
  required String paymentMethod,
  required double tenderedAmount,
}) {
  return db.transaction(() async {
    final id = await db.ordersDao.insertOrder(
      OrdersCompanion.insert(
        subtotal: summary.subtotal,
        taxTotal: Value(summary.taxAmount),
        discountTotal: Value(summary.orderDiscount),
        total: summary.total,
        paymentMethod: paymentMethod,
        tenderedAmount: paymentMethod == 'cash'
            ? Value(tenderedAmount)
            : const Value.absent(),
        changeAmount: paymentMethod == 'cash'
            ? Value((tenderedAmount - summary.total).clamp(0, double.infinity))
            : const Value.absent(),
        customerId: session.customerId != null
            ? Value(session.customerId!)
            : const Value.absent(),
        tableId: session.tableId != null
            ? Value(session.tableId!)
            : const Value.absent(),
      ),
    );

    await db.ordersDao.insertItems([
      for (final item in cart)
        OrderItemsCompanion.insert(
          orderId: id,
          productId: item.productId,
          productName: item.name,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          discount: Value(item.lineDiscount),
          lineTotal: item.lineSubtotal,
        ),
    ]);

    if (summary.taxEnabled && summary.taxLines.isNotEmpty) {
      await db.ordersDao.insertTaxLines([
        for (final line in summary.taxLines)
          if (line.amount > 0)
            OrderTaxesCompanion.insert(
              orderId: id,
              taxRateId: line.taxRateId,
              taxRateName: line.name,
              taxRatePercent: line.rate,
              taxableAmount: line.taxableAmount,
              taxAmount: line.amount,
            ),
      ]);
    }

    for (final item in cart) {
      final product = await db.productsDao.getById(item.productId);
      if (product != null && product.isComposite) {
        final components = await db.productsDao.getComponents(item.productId);
        for (final comp in components) {
          final deduct = comp.quantity * item.quantity;
          await db.productsDao.deductStock(comp.componentProductId, deduct);
          await db.inventoryDao.logAdjustment(
            StockAdjustmentsCompanion.insert(
              productId: comp.componentProductId,
              delta: -deduct,
              reasonCode: 'sale',
              notes: Value('Order #$id (via ${item.name})'),
            ),
          );
        }
      } else {
        await db.productsDao.deductStock(item.productId, item.quantity);
        await db.inventoryDao.logAdjustment(
          StockAdjustmentsCompanion.insert(
            productId: item.productId,
            delta: -item.quantity,
            reasonCode: 'sale',
            notes: Value('Order #$id'),
          ),
        );
      }
    }

    if (session.customerId != null) {
      if (session.loyaltyPointsToRedeem > 0) {
        await db.customersDao.redeemLoyaltyPoints(
            session.customerId!, session.loyaltyPointsToRedeem);
      }
      if (summary.pointsToEarn > 0) {
        await db.customersDao
            .addLoyaltyPoints(session.customerId!, summary.pointsToEarn);
      }
    }

    await audit.orderPlaced(
      id,
      total: summary.total,
      paymentMethod: paymentMethod,
    );

    return id;
  });
}
