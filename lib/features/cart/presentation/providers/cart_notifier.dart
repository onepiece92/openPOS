import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/cart/data/ticket_sequence.dart';
import 'package:pos_app/features/cart/domain/cart_calculator.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/cart_session.dart';
import 'package:pos_app/features/cart/domain/cart_summary.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
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

  void setCustomer(int? id) => id == null
      ? state = state.copyWith(clearCustomer: true)
      : state = state.copyWith(customerId: id);
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

  /// Rebinds the cart to an existing held ticket, adopting its number and
  /// metadata so a later save updates that ticket rather than minting a new
  /// one. No counter value is consumed — the ticket already owns its number.
  void resumeTicket(HeldOrder ticket) => state = CartSession(
        ticketNumber: ticket.ticketNumber,
        openedAt: ticket.createdAt,
        heldTicketId: ticket.id,
        customerId: ticket.customerId,
        tableId: ticket.tableId,
        orderDiscount: ticket.orderDiscount,
        orderDiscountIsPercent: ticket.orderDiscountIsPercent,
      );
}

final cartSessionProvider =
    NotifierProvider<CartSessionNotifier, CartSession>(CartSessionNotifier.new);

// ─── Selected tax rates ───────────────────────────────────────────────────────

class SelectedTaxRatesNotifier extends Notifier<List<int>> {
  @override
  List<int> build() {
    final defaultId = ref.watch(defaultTaxIdProvider);
    return defaultId != null ? [defaultId] : [];
  }

  void add(int id) {
    if (!state.contains(id)) state = [...state, id];
  }

  void remove(int id) => state = state.where((x) => x != id).toList();

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

  void addProduct(Product p) {
    final existing = state.indexWhere((i) => i.productId == p.id);
    if (existing >= 0) {
      final updated = [...state];
      updated[existing] =
          updated[existing].copyWith(quantity: updated[existing].quantity + 1);
      state = updated;
    } else {
      state = [
        ...state,
        CartItem(
          productId: p.id,
          name: p.name,
          unitPrice: p.price,
          quantity: 1,
          isTaxable: p.isTaxable,
        ),
      ];
    }
  }

  void setQuantity(int productId, int qty) {
    if (qty <= 0) {
      remove(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.productId == productId) item.copyWith(quantity: qty) else item,
    ];
  }

  void remove(int productId) {
    state = state.where((i) => i.productId != productId).toList();
  }

  void setDiscount(int productId, double discount) {
    state = [
      for (final item in state)
        if (item.productId == productId)
          item.copyWith(lineDiscount: discount.clamp(0, item.lineSubtotal))
        else
          item,
    ];
  }

  /// Adds a [CartItem] directly — used when resuming a held order.
  void addItem(CartItem item) {
    final existing = state.indexWhere((i) => i.productId == item.productId);
    if (existing >= 0) {
      final updated = [...state];
      updated[existing] = updated[existing]
          .copyWith(quantity: updated[existing].quantity + item.quantity);
      state = updated;
    } else {
      state = [...state, item];
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

  int get itemCount => state.fold(0, (sum, i) => sum + i.quantity);
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

// ─── Cart summary provider (derived) ─────────────────────────────────────────

/// Thin Riverpod shell around [CartCalculator.compute] — all math lives there.
final cartSummaryProvider = Provider<CartSummary>((ref) {
  final selectedIds = ref.watch(selectedTaxRatesProvider);
  final allRates = ref.watch(taxRatesStreamProvider).valueOrNull ?? const [];
  return CartCalculator.compute(
    items: ref.watch(cartProvider),
    session: ref.watch(cartSessionProvider),
    selectedRates: [
      for (final id in selectedIds) ...allRates.where((r) => r.id == id),
    ],
    loyaltyEnabled: ref.watch(loyaltyEnabledProvider),
    loyaltyEarnRate: ref.watch(loyaltyEarnRateProvider),
    loyaltyPointValue: ref.watch(loyaltyPointValueProvider),
  );
});
