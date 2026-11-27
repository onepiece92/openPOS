import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/utils/money.dart';
import 'package:pos_app/features/cart/data/ticket_sequence.dart';
import 'package:pos_app/features/cart/domain/cart_calculator.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/cart_session.dart';
import 'package:pos_app/features/cart/domain/cart_summary.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/cart/domain/stock_cap.dart';
import 'package:pos_app/features/customers/domain/customers_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

// Domain types moved to features/cart/domain; re-exported so existing
// `import 'cart_notifier.dart'` call sites keep resolving them.
export 'package:pos_app/features/cart/domain/cart_session.dart';
export 'package:pos_app/features/cart/domain/cart_summary.dart';

// ─── Cart session (ticket metadata) ──────────────────────────────────────────

class CartSessionNotifier extends Notifier<CartSession> {
  @override
  CartSession build() => CartSession.fresh(_nextTicketNumber());

  /// Burns one value off the persisted counter. Numbers only ever climb, so an
  /// abandoned cart leaves a gap rather than letting a later ticket reuse it.
  String _nextTicketNumber() => ref.read(ticketSequenceProvider).next();

  /// Points are redeemed from one customer's balance, so a redemption never
  /// survives the customer being changed or removed.
  void setCustomer(int? id) {
    if (id == state.customerId) return;
    state = id == null
        ? state.copyWith(clearCustomer: true, loyaltyPointsToRedeem: 0)
        : state.copyWith(customerId: id, loyaltyPointsToRedeem: 0);
  }
  void setTable(int? id) => id == null
      ? state = state.copyWith(clearTable: true)
      : state = state.copyWith(tableId: id);
  void setOrderDiscount(double amount, {required bool isPercent}) =>
      state = state.copyWith(
          orderDiscount: amount, orderDiscountIsPercent: isPercent);
  void setTaxEnabled(bool enabled) =>
      state = state.copyWith(taxEnabled: enabled);
  void setLoyaltyPoints(int points) =>
      state = state.copyWith(loyaltyPointsToRedeem: points.clamp(0, 999999));
  void reset() => state = CartSession.fresh(_nextTicketNumber());

  /// Puts back a session taken before a clear (its number included), for
  /// "Undo" on Clear cart. No counter value is consumed.
  void restore(CartSession session) => state = session;

  /// Rebinds the cart to an existing held ticket, adopting its number and
  /// metadata so a later save updates that ticket rather than minting a new
  /// one. No counter value is consumed — the ticket already owns its number.
  ///
  /// The tax switch and selected rate come back with it, so the total is
  /// what it was when the ticket was parked (a ticket parked with several
  /// rates, from before carts were limited to one, keeps its first). Tickets saved before tax state
  /// was stored carry none: they resume with tax on and whatever rates are
  /// currently selected (the store default after a clearItems).
  void resumeTicket(HeldOrder ticket) {
    state = CartSession(
      ticketNumber: ticket.ticketNumber,
      openedAt: ticket.createdAt,
      heldTicketId: ticket.id,
      customerId: ticket.customerId,
      tableId: ticket.tableId,
      orderDiscount: ticket.orderDiscount,
      orderDiscountIsPercent: ticket.orderDiscountIsPercent,
      taxEnabled: ticket.taxEnabled,
    );
    final rateIds = ticket.taxRateIds;
    if (rateIds != null) {
      ref.read(selectedTaxRatesProvider.notifier).restore(rateIds);
    }
  }
}

final cartSessionProvider =
    NotifierProvider<CartSessionNotifier, CartSession>(CartSessionNotifier.new);

// ─── Selected tax rates ───────────────────────────────────────────────────────

/// The tax rate applied to the cart. A sale carries one rate, so the list
/// holds at most one id (it stays a list because held tickets and the
/// calculator are written in terms of "the selected rates").
class SelectedTaxRatesNotifier extends Notifier<List<int>> {
  @override
  List<int> build() {
    final defaultId = ref.watch(defaultTaxIdProvider);
    return defaultId != null ? [defaultId] : [];
  }

  /// Makes [id] the cart's rate, replacing whichever was selected.
  void select(int id) => state = [id];

  /// No tax rate on this cart.
  void clear() => state = [];

  /// Reinstates the rate a held ticket was parked with. Tickets saved when
  /// a cart could carry several rates come back with the first of them.
  void restore(List<int> ids) => state = ids.isEmpty ? [] : [ids.first];

  void reset() {
    final defaultId = ref.read(defaultTaxIdProvider);
    state = defaultId != null ? [defaultId] : [];
  }
}

final selectedTaxRatesProvider =
    NotifierProvider<SelectedTaxRatesNotifier, List<int>>(
        SelectedTaxRatesNotifier.new);

// ─── Cart notifier ────────────────────────────────────────────────────────────

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  /// Adds one main-unit of [p] (merging into the main-unit line if present).
  /// Returns false when stock doesn't allow it.
  bool addProduct(Product p) => addItem(CartItem(
        productId: p.id,
        name: p.name,
        unitPrice: p.price,
        quantity: 1,
        isTaxable: p.isTaxable,
      ));

  /// Adds one *secondary* unit of [p] (e.g. one dozen) as its own line.
  /// Price is the main-unit price × conversion, rounded to money.
  /// Returns false when stock doesn't allow it.
  bool addProductInSecondaryUnit(Product p) {
    final label = p.secondaryUnit;
    if (label == null || label.isEmpty) return false;
    return addItem(CartItem(
      productId: p.id,
      name: p.name,
      unitPrice: roundMoney(p.price * p.conversionRate),
      quantity: 1,
      isTaxable: p.isTaxable,
      unitLabel: label,
      unitsPerQty: p.conversionRate,
    ));
  }

  /// Sets a line's quantity. Returns false — leaving the cart untouched —
  /// when raising it would take the product past its stock. Lowering a
  /// quantity is always allowed.
  bool setQuantity(int productId, int qty, {String unitLabel = ''}) {
    if (qty <= 0) {
      remove(productId, unitLabel: unitLabel);
      return true;
    }
    for (final item in state) {
      if (item.sameLine(productId, unitLabel) &&
          qty > item.quantity &&
          !_fitsStock(item.copyWith(quantity: qty))) {
        return false;
      }
    }
    state = [
      for (final item in state)
        if (item.sameLine(productId, unitLabel))
          item.withQuantity(qty)
        else
          item,
    ];
    return true;
  }

  /// True when the cart can hold [line] (at its new quantity) alongside the
  /// product's other lines. Stock is counted in main units, so 2 dozen and
  /// 3 pcs of the same product weigh 27 against the cap. Products the POS
  /// catalog doesn't know (not loaded yet, hidden) are not capped.
  bool _fitsStock(CartItem line) {
    // Stock tracking off: nothing is capped (and the catalog isn't read).
    if (!ref.read(featureOnProvider(Feature.stockTracking))) return true;
    final products = ref.read(productsStreamProvider).valueOrNull ?? const [];
    final product =
        products.where((p) => p.id == line.productId).firstOrNull;
    if (product == null) return true;
    final cap = stockCapFor(product);
    if (cap == null) return true;
    var committed = line.mainUnitQty;
    for (final other in state) {
      if (other.productId == line.productId &&
          !other.sameLine(line.productId, line.unitLabel)) {
        committed += other.mainUnitQty;
      }
    }
    return committed <= cap;
  }

  void remove(int productId, {String unitLabel = ''}) {
    state =
        state.where((i) => !i.sameLine(productId, unitLabel)).toList();
  }

  /// Sets a line's flat discount, capped at the line's gross amount (unit
  /// price × quantity) — not at what a previous discount left of it.
  /// [setQuantity] re-applies the cap when the line shrinks.
  void setDiscount(int productId, double discount, {String unitLabel = ''}) {
    state = [
      for (final item in state)
        if (item.sameLine(productId, unitLabel))
          item.withDiscount(discount)
        else
          item,
    ];
  }

  /// Adds a [CartItem], merging into the matching (product, unit) line.
  /// Returns false — leaving the cart untouched — when the product's stock
  /// can't cover the resulting quantity.
  bool addItem(CartItem item) {
    final existing =
        state.indexWhere((i) => i.sameLine(item.productId, item.unitLabel));
    final merged = existing >= 0
        ? state[existing]
            .copyWith(quantity: state[existing].quantity + item.quantity)
        : item;
    if (!_fitsStock(merged)) return false;
    _put(existing, merged);
    return true;
  }

  /// Puts a saved line back as it was, without the stock check: resuming a
  /// held ticket must not silently drop lines because stock moved while it
  /// was parked. The line still can't be raised past stock afterwards.
  void restoreItem(CartItem item) {
    final existing =
        state.indexWhere((i) => i.sameLine(item.productId, item.unitLabel));
    _put(
        existing,
        existing >= 0
            ? state[existing]
                .copyWith(quantity: state[existing].quantity + item.quantity)
            : item);
  }

  void _put(int index, CartItem line) {
    if (index >= 0) {
      state = [...state]..[index] = line;
    } else {
      state = [...state, line];
    }
  }

  /// Empties the line items but leaves the ticket identity alone. Used when
  /// resuming a held ticket, which rebinds the session itself right after.
  void clearItems() {
    state = [];
    ref.read(selectedTaxRatesProvider.notifier).reset();
  }

  /// Ends the ticket entirely: empties the cart and opens a fresh session
  /// (which takes the next number off the counter).
  void clear() {
    clearItems();
    ref.read(cartSessionProvider.notifier).reset();
  }

  /// Everything [clear] throws away: lines, session (number, held ticket,
  /// customer, table, discounts, tax switch, points) and the tax rate.
  CartSnapshot snapshot() => CartSnapshot(
        items: [...state],
        session: ref.read(cartSessionProvider),
        taxRateIds: [...ref.read(selectedTaxRatesProvider)],
      );

  /// Puts back exactly the cart [s] was taken from, replacing what is in
  /// the cart now.
  void restoreSnapshot(CartSnapshot s) {
    state = [...s.items];
    ref.read(cartSessionProvider.notifier).restore(s.session);
    ref.read(selectedTaxRatesProvider.notifier).restore(s.taxRateIds);
  }

  int get itemCount => state.fold(0, (sum, i) => sum + i.quantity);
}

/// A cart as it was before Clear cart, for "Undo" ([CartNotifier.snapshot]).
class CartSnapshot {
  const CartSnapshot(
      {required this.items, required this.session, required this.taxRateIds});
  final List<CartItem> items;
  final CartSession session;
  final List<int> taxRateIds;
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

// ─── Cart summary provider (derived) ─────────────────────────────────────────

/// Thin Riverpod shell around [CartCalculator.compute] — all math lives there.
///
/// Switched-off features are not watched at all: with Taxes off the tax
/// rates stream never starts (the sale has no tax — the selected rate is
/// kept, so a held ticket gets its tax back once Taxes is on again), and
/// with Loyalty off (or Customers off) the customer list is not read.
final cartSummaryProvider = Provider<CartSummary>((ref) {
  final taxes = ref.watch(featureOnProvider(Feature.taxes));
  final loyalty = ref.watch(featureOnProvider(Feature.loyalty));
  final List<TaxRate> selectedRates;
  if (taxes) {
    final selectedIds = ref.watch(selectedTaxRatesProvider);
    final allRates = ref.watch(taxRatesStreamProvider).valueOrNull ?? const [];
    selectedRates = [
      for (final id in selectedIds) ...allRates.where((r) => r.id == id),
    ];
  } else {
    selectedRates = const [];
  }
  return CartCalculator.compute(
    items: ref.watch(cartProvider),
    session: ref.watch(cartSessionProvider),
    selectedRates: selectedRates,
    loyaltyEnabled: loyalty,
    loyaltyEarnRate: loyalty ? ref.watch(loyaltyEarnRateProvider) : 0,
    loyaltyPointValue: loyalty ? ref.watch(loyaltyPointValueProvider) : 0,
    customerLoyaltyPoints:
        loyalty ? ref.watch(cartCustomerProvider)?.loyaltyPoints ?? 0 : 0,
  );
});
