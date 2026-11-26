import 'package:drift/drift.dart' show Value;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/tables/orders_table.dart';
import 'package:pos_app/features/orders/domain/order_number.dart';

/// The two halves of undoing a sale, shared by `voidOrder` and
/// `processReturn`. Call inside the caller's transaction.

/// What a void or refund of an order would put back on the shelf.
///
/// The rule, decided per order:
/// * **Stock-linked** (`stock_linked` set, every sale since schema v16):
///   exactly what its own stock_adjustments rows still owe
///   (`InventoryDao.stockToRestock`) — bundles as the components taken,
///   whatever the recipe or the Stock tracking switch says now.
/// * **CSV import** (legacy, prefix [kImportedInvoicePrefix]): nothing.
///   The import never deducted stock.
/// * **Other legacy orders**: every line, re-derived as `placeOrder`
///   deducts it, only while Stock tracking is on now and no earlier refund
///   restocked it. Demo-data orders land here too and never deducted, so
///   they can over-restock; demo data is debug-only from 1.1.0.
class RestockPlan {
  const RestockPlan._({this.owed, this.byLines = false});

  /// Nothing to put back.
  static const none = RestockPlan._();

  /// productId → units still owed, for a stock-linked order; else null.
  final Map<int, int>? owed;

  /// A legacy order restocked from its lines.
  final bool byLines;

  /// Whether a restock would put anything back: drives "Restock items" and
  /// the void text.
  bool get any => byLines || (owed?.isNotEmpty ?? false);
}

/// The [RestockPlan] for [order] from what has already been read: [owed]
/// is `stockToRestock`'s answer, [restocked] whether an earlier refund
/// restocked it (only consulted for a legacy order).
RestockPlan planRestock(
  Order order, {
  required Map<int, int>? owed,
  required bool trackStock,
  required bool restocked,
}) {
  if (owed != null) return RestockPlan._(owed: owed);
  if (order.invoicePrefix == kImportedInvoicePrefix) return RestockPlan.none;
  if (!trackStock || restocked) return RestockPlan.none;
  return const RestockPlan._(byLines: true);
}

/// Reads and decides [order]'s [RestockPlan]. Call inside the void / refund
/// transaction, so nothing can change what is owed before it is restocked.
Future<RestockPlan> readRestockPlan(
  AppDatabase db,
  Order order, {
  required bool trackStock,
}) async {
  final owed = await db.inventoryDao.stockToRestock(order.id);
  final legacyLines = owed == null &&
      order.invoicePrefix != kImportedInvoicePrefix &&
      trackStock;
  return planRestock(
    order,
    owed: owed,
    trackStock: trackStock,
    restocked: legacyLines && await db.ordersDao.hasRestockedReturn(order.id),
  );
}

/// Carries out [plan] for [order]. Every unit goes back through
/// `ProductsDao.restock`, which refuses a product that is gone or no longer
/// tracked; the adjustment log (with the order id) gets a row only for
/// what it actually put back.
Future<void> applyRestock(
  AppDatabase db,
  Order order,
  RestockPlan plan, {
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
        orderId: Value(order.id),
      ),
    );
  }

  final label = '$note ${order.billNo}';
  final owed = plan.owed;
  if (owed != null) {
    for (final MapEntry(key: productId, value: units) in owed.entries) {
      await addBack(productId, units, label);
    }
    return;
  }
  if (!plan.byLines) return;

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
