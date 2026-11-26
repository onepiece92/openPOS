import 'package:drift/drift.dart' show Value;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/orders/domain/order_number.dart';

/// The two halves of undoing a sale, shared by `voidOrder` and
/// `processReturn`. Call inside the caller's transaction.

/// Puts every line of [order] back into stock, mirroring `placeOrder`:
/// quantities are converted to main units with the line's `units_per_qty`
/// snapshot, and composite products restock their components.
///
/// Only what is tracked is restored — see [ProductsDao.restock] — and the
/// adjustment log gets a row only for stock that actually moved.
///
/// Callers decide WHETHER to restock: see the interim rule in `voidOrder`
/// and `processReturn` (and its two known wrong cases).
// INTERIM rule (until schema v16): restock only while Stock tracking is
// on NOW. It is wrong in both mixed cases:
// * sold with tracking ON, voided/refunded with it OFF: nothing is put
//   back, so stock stays LOW by the quantity sold;
// * sold with tracking OFF, voided/refunded with it ON: the sale deducted
//   nothing, yet it is restocked, so stock is OVER-restocked.
// TODO(schema v16): stock_adjustments gets order_id; replace this with
// the stock_linked + stockToRestock rule — restock exactly what THIS
// sale's own 'sale' rows deducted, whatever the switch says now. This
// branch is not merged to main on its own.
Future<void> restockOrderItems(
  AppDatabase db,
  Order order, {
  required String reasonCode,
  required String note,
}) async {
  Future<void> addBack(int productId, int units, String notes) async {
    final added = await db.productsDao.restock(productId, units);
    if (added == 0) return;
    await db.inventoryDao.logAdjustment(
      StockAdjustmentsCompanion.insert(
        productId: productId,
        delta: added,
        reasonCode: reasonCode,
        notes: Value(notes),
      ),
    );
  }

  final label = '$note ${order.billNo}';
  final items = await db.ordersDao.getItems(order.id);
  for (final item in items) {
    // Same rounding as CartItem.mainUnitQty, which drove the deduction.
    final mainUnits = (item.quantity * item.unitsPerQty).round();
    final product = await db.productsDao.getById(item.productId);
    if (product != null && product.isComposite) {
      final components = await db.productsDao.getComponents(item.productId);
      for (final comp in components) {
        await addBack(comp.componentProductId, comp.quantity * mainUnits,
            '$label (via ${item.productName})');
      }
    } else {
      await addBack(item.productId, mainUnits, label);
    }
  }
}

/// Undoes the loyalty side of [order]: the customer gets back the points
/// they redeemed on it and loses the points they earned on it. The balance
/// never goes below zero (they may have spent the earned points since).
Future<void> reverseLoyalty(AppDatabase db, Order order) async {
  final customerId = order.customerId;
  if (customerId == null) return;
  if (order.pointsRedeemed > 0) {
    await db.customersDao.addLoyaltyPoints(customerId, order.pointsRedeemed);
  }
  if (order.pointsEarned > 0) {
    // redeemLoyaltyPoints clamps at zero.
    await db.customersDao.redeemLoyaltyPoints(customerId, order.pointsEarned);
  }
}
