import 'package:drift/drift.dart' show Value;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/core/utils/money.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';

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
  String invoicePrefix = '',
}) {
  return db.transaction(() async {
    // Read once: needed for the cost snapshot and again for stock below.
    final products = <int, Product?>{};
    for (final item in cart) {
      products[item.productId] ??=
          await db.productsDao.getById(item.productId);
    }
    final unitCosts = <int, double?>{
      for (final entry in products.entries)
        entry.key: await _unitCostNow(db, entry.value),
    };
    // Tax is an invoice-level figure, so a line has no tax of its own —
    // each taxable line stores its share, and the shares sum to the total.
    final lineTax = prorateMoney(
      summary.taxEnabled ? summary.taxAmount : 0,
      [for (final item in cart) item.isTaxable ? item.lineSubtotal : 0.0],
    );

    // Gap-free: computed inside the transaction, never reused (voids keep it).
    final invoiceNo =
        await db.ordersDao.nextInvoiceNo(prefix: invoicePrefix);
    final id = await db.ordersDao.insertOrder(
      OrdersCompanion.insert(
        invoiceNo: Value(invoiceNo),
        invoicePrefix: Value(invoicePrefix),
        subtotal: summary.subtotal,
        taxTotal: Value(summary.taxAmount),
        discountTotal: Value(summary.orderDiscount),
        discountValue: Value(session.orderDiscount),
        discountIsPercent: Value(session.orderDiscountIsPercent),
        total: summary.total,
        paymentMethod: paymentMethod,
        tenderedAmount: paymentMethod == 'cash'
            ? Value(tenderedAmount)
            : const Value.absent(),
        changeAmount: paymentMethod == 'cash'
            ? Value(roundMoney(
                (tenderedAmount - summary.total).clamp(0, double.infinity)))
            : const Value.absent(),
        customerId: session.customerId != null
            ? Value(session.customerId!)
            : const Value.absent(),
        tableId: session.tableId != null
            ? Value(session.tableId!)
            : const Value.absent(),
        // The summary's figure, not the session's: it is what the discount
        // was actually computed from (capped by balance and order total).
        pointsRedeemed: Value(summary.pointsRedeemed),
        loyaltyDiscount: Value(summary.loyaltyDiscount),
        // Points go to a customer; a walk-in sale earns none, so none are
        // recorded against it.
        pointsEarned:
            Value(session.customerId != null ? summary.pointsToEarn : 0),
      ),
    );

    await db.ordersDao.insertItems([
      for (final (index, item) in cart.indexed)
        OrderItemsCompanion.insert(
          orderId: id,
          productId: item.productId,
          // Suffix the sold unit so receipts and history read naturally
          // ("Eggs (dozen)"); the raw label/conversion are snapshot too.
          productName: item.isSecondaryUnit
              ? '${item.name} (${item.unitLabel})'
              : item.name,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          unitLabel: Value(item.unitLabel),
          unitsPerQty: Value(item.unitsPerQty),
          discount: Value(item.lineDiscount),
          taxAmount: Value(lineTax[index]),
          lineTotal: item.lineSubtotal,
          // What a main unit cost today — the product's price may change
          // tomorrow, the profit on this sale must not.
          unitCost: Value(unitCosts[item.productId]),
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
              isInclusive: Value(line.isInclusive),
            ),
      ]);
    }

    // The adjustment log records what actually left the shelf: nothing for
    // untracked products, and never more than was in stock.
    Future<void> deduct(int productId, int units, String note) async {
      final taken = await db.productsDao.deductStock(productId, units);
      if (taken == 0) return;
      await db.inventoryDao.logAdjustment(
        StockAdjustmentsCompanion.insert(
          productId: productId,
          delta: -taken,
          reasonCode: 'sale',
          notes: Value(note),
        ),
      );
    }

    for (final item in cart) {
      final product = products[item.productId];
      // Stock is tracked in main units — a secondary-unit line deducts
      // quantity × conversion (e.g. 2 dozen → 24 pcs).
      final mainUnits = item.mainUnitQty;
      if (product != null && product.isComposite) {
        final components = await db.productsDao.getComponents(item.productId);
        for (final comp in components) {
          await deduct(comp.componentProductId, comp.quantity * mainUnits,
              'Order #$invoiceNo (via ${item.name})');
        }
      } else {
        await deduct(item.productId, mainUnits, 'Order #$invoiceNo');
      }
    }

    if (session.customerId != null) {
      if (summary.pointsRedeemed > 0) {
        await db.customersDao.redeemLoyaltyPoints(
            session.customerId!, summary.pointsRedeemed);
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

/// What one main unit of [product] costs the shop right now, or null when
/// that is not known: no purchase price, or — for a composite, which costs
/// the sum of its components — a component without one. Null rather than a
/// partial figure, so reports can say "no cost recorded" instead of quietly
/// overstating the profit.
Future<double?> _unitCostNow(AppDatabase db, Product? product) async {
  if (product == null) return null;
  if (!product.isComposite) {
    return product.purchasePrice > 0 ? product.purchasePrice : null;
  }
  final components = await db.productsDao.getComponents(product.id);
  if (components.isEmpty) return null;
  var cost = 0.0;
  for (final comp in components) {
    final part = await db.productsDao.getById(comp.componentProductId);
    if (part == null || part.purchasePrice <= 0) return null;
    cost += comp.quantity * part.purchasePrice;
  }
  return roundMoney(cost);
}
