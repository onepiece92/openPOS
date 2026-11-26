import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/cart/data/ticket_sequence.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/customers/domain/customers_provider.dart';
import 'package:pos_app/features/usage/usage_providers.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';

export 'package:pos_app/features/cart/data/ticket_sequence.dart'
    show heldOrdersBoxProvider;

// ── Notifier ──────────────────────────────────────────────────────────────────

class HeldOrdersNotifier extends Notifier<List<HeldOrder>> {
  Box<dynamic> get _box => ref.read(heldOrdersBoxProvider);

  @override
  List<HeldOrder> build() => _loadAll();

  List<HeldOrder> _loadAll() {
    return _box
        .toMap()
        .entries
        .where((e) => e.key != kTicketSeqKey)
        .map((e) {
          try {
            return HeldOrder.fromJson(
                jsonDecode(e.value as String) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<HeldOrder>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Saves the current cart as a held ticket and returns the new [HeldOrder].
  HeldOrder hold(
    List<CartItem> items, {
    required String ticketNumber,
    String? label,
    String? customerName,
    int? customerId,
    int? tableId,
    double orderDiscount = 0.0,
    bool orderDiscountIsPercent = false,
    bool taxEnabled = true,
    List<int>? taxRateIds,
  }) {
    final now = DateTime.now();
    // Keyed by the ticket number, which the counter guarantees is unique and
    // never reissued. A clock-derived key collides when two tickets are saved
    // inside the same millisecond, silently overwriting the first.
    final id = ticketNumber;
    final ticket = HeldOrder(
      id: id,
      ticketNumber: ticketNumber,
      // Derived from the ticket's own number, never from the list length —
      // a length-based counter reuses numbers as soon as one is archived.
      label: label ?? customerName ?? 'Ticket $ticketNumber',
      createdAt: now,
      items: items,
      customerName: customerName,
      customerId: customerId,
      tableId: tableId,
      orderDiscount: orderDiscount,
      orderDiscountIsPercent: orderDiscountIsPercent,
      taxEnabled: taxEnabled,
      taxRateIds: taxRateIds,
    );
    _box.put(id, jsonEncode(ticket.toJson()));
    state = _loadAll();
    return ticket;
  }

  /// Rewrites an existing ticket in place, keeping its id, number, label and
  /// creation time — so editing a ticket never renumbers it and never moves it
  /// in the list.
  HeldOrder update(
    String id, {
    required List<CartItem> items,
    String? customerName,
    int? customerId,
    int? tableId,
    double orderDiscount = 0.0,
    bool orderDiscountIsPercent = false,
    bool taxEnabled = true,
    List<int>? taxRateIds,
  }) {
    final existing = state.firstWhere((t) => t.id == id);
    // Auto-labelled tickets follow their customer; hand-picked labels stick.
    final wasAutoLabelled = existing.label == existing.customerName;
    final updated = HeldOrder(
      id: existing.id,
      ticketNumber: existing.ticketNumber,
      label: wasAutoLabelled && customerName != null
          ? customerName
          : existing.label,
      createdAt: existing.createdAt,
      items: items,
      customerName: customerName,
      customerId: customerId,
      tableId: tableId,
      orderDiscount: orderDiscount,
      orderDiscountIsPercent: orderDiscountIsPercent,
      taxEnabled: taxEnabled,
      taxRateIds: taxRateIds,
      archivedAt: existing.archivedAt,
    );
    _box.put(existing.id, jsonEncode(updated.toJson()));
    state = _loadAll();
    return updated;
  }

  /// Saves the current cart + session state as a ticket in one call. Updates
  /// the ticket the cart was resumed from when there is one, otherwise mints
  /// a new ticket off the persisted counter.
  HeldOrder holdCurrentCart() {
    final cart = ref.read(cartProvider);
    final session = ref.read(cartSessionProvider);
    final existingId = session.heldTicketId;
    // Customers off: the customer list is not read; a resumed ticket keeps
    // the name it was saved with.
    final customerName = ref.read(featureOnProvider(Feature.customers))
        ? ref.read(cartCustomerNameProvider)
        : (existingId == null
            ? null
            : state.where((t) => t.id == existingId).firstOrNull?.customerName);
    // The tax switch and the chosen rates decide the total, so they are
    // parked with the ticket.
    final taxRateIds = [...ref.read(selectedTaxRatesProvider)];

    final HeldOrder held;
    if (existingId != null && _box.containsKey(existingId)) {
      held = update(
        existingId,
        items: cart,
        customerName: customerName,
        customerId: session.customerId,
        tableId: session.tableId,
        orderDiscount: session.orderDiscount,
        orderDiscountIsPercent: session.orderDiscountIsPercent,
        taxEnabled: session.taxEnabled,
        taxRateIds: taxRateIds,
      );
    } else {
      held = hold(
        cart,
        ticketNumber: session.ticketNumber,
        customerName: customerName,
        customerId: session.customerId,
        tableId: session.tableId,
        orderDiscount: session.orderDiscount,
        orderDiscountIsPercent: session.orderDiscountIsPercent,
        taxEnabled: session.taxEnabled,
        taxRateIds: taxRateIds,
      );
    }
    // Counted only once the ticket is saved (update/hold threw otherwise).
    ref.read(usageCounterProvider).record(UsageEvent.ticketHeld);
    return held;
  }

  /// Checks [ticket] against the database before it is resumed, in one
  /// query (primary-key lookups only): lines whose product is gone or was
  /// deleted are dropped, and a customer or table that no longer exists is
  /// cleared; a tax rate that no longer exists is cleared. A ticket left with
  /// no lines is deleted. A changed ticket is saved back, so it is cleaned only once.
  /// When the database cannot be read the ticket is returned unchanged
  /// (payment still refuses dead ids, see `placeOrder`).
  Future<ResumeCheck> checkForResume(HeldOrder ticket) async {
    final productIds = {for (final i in ticket.items) i.productId}.toList();
    final parts = <String>[];
    final args = <Variable<Object>>[];
    if (productIds.isNotEmpty) {
      parts.add("SELECT 'p' AS k, id FROM products "
          'WHERE is_active = 1 AND id IN '
          '(${List.filled(productIds.length, '?').join(', ')})');
      args.addAll(productIds.map(Variable<int>.new));
    }
    if (ticket.customerId != null) {
      parts.add("SELECT 'c' AS k, id FROM customers WHERE id = ?");
      args.add(Variable<int>(ticket.customerId!));
    }
    if (ticket.tableId != null) {
      parts.add("SELECT 't' AS k, id FROM tables WHERE id = ?");
      args.add(Variable<int>(ticket.tableId!));
    }
    final rateIds = ticket.taxRateIds ?? const <int>[];
    if (rateIds.isNotEmpty) {
      parts.add("SELECT 'x' AS k, id FROM tax_rates WHERE is_active = 1 "
          'AND id IN (${List.filled(rateIds.length, '?').join(', ')})');
      args.addAll(rateIds.map(Variable<int>.new));
    }
    if (parts.isEmpty) return ResumeCheck(ticket);
    final List<QueryRow> rows;
    try {
      rows = await ref
          .read(databaseProvider)
          .customSelect(parts.join(' UNION ALL '), variables: args)
          .get();
    } catch (_) {
      return ResumeCheck(ticket);
    }
    final live = <int>{};
    final liveRates = <int>{};
    var customer = false, table = false;
    for (final r in rows) {
      switch (r.read<String>('k')) {
        case 'p':
          live.add(r.read<int>('id'));
        case 'x':
          liveRates.add(r.read<int>('id'));
        case 'c':
          customer = true;
        case 't':
          table = true;
      }
    }
    final check = checkHeldOrder(ticket,
        liveProductIds: live,
        customerExists: customer,
        tableExists: table,
        liveTaxRateIds: liveRates);
    if (check.emptied) {
      // Nothing left to sell: drop the ticket instead of keeping it empty.
      delete(ticket.id);
    } else if (check.changed && _box.containsKey(ticket.id)) {
      // Like every write here: the box updates in memory at once.
      unawaited(_box.put(ticket.id, jsonEncode(check.ticket.toJson())));
      state = _loadAll();
    }
    return check;
  }

  /// How many held tickets have a line for [productId] (one scan of the
  /// in-memory list). Used to warn before a product is deleted.
  int ticketsWithProduct(int productId) =>
      heldTicketsWithProduct(state, productId);

  /// Archives a held ticket by id.
  void archive(String id) {
    final ticket = state.firstWhere((t) => t.id == id);
    final archived = ticket.copyWith(archivedAt: DateTime.now());
    _box.put(id, jsonEncode(archived.toJson()));
    state = _loadAll();
  }

  /// Unarchives a ticket (moves it back to active).
  void unarchive(String id) {
    final ticket = state.firstWhere((t) => t.id == id);
    final restored = ticket.copyWith(clearArchived: true);
    _box.put(id, jsonEncode(restored.toJson()));
    state = _loadAll();
  }

  /// Permanently removes a held ticket by id.
  void delete(String id) {
    _box.delete(id);
    state = _loadAll();
  }

  /// Archives all active tickets.
  void archiveAll() {
    for (final ticket in state.where((t) => !t.isArchived)) {
      final archived = ticket.copyWith(archivedAt: DateTime.now());
      _box.put(ticket.id, jsonEncode(archived.toJson()));
    }
    state = _loadAll();
  }

  /// Permanently removes all archived tickets.
  void deleteAllArchived() {
    for (final ticket in state.where((t) => t.isArchived)) {
      _box.delete(ticket.id);
    }
    state = _loadAll();
  }
}

final heldOrdersProvider =
    NotifierProvider<HeldOrdersNotifier, List<HeldOrder>>(
        HeldOrdersNotifier.new);

/// Only active (non-archived) tickets.
final activeHeldOrdersProvider = Provider<List<HeldOrder>>((ref) {
  return ref.watch(heldOrdersProvider).where((t) => !t.isArchived).toList();
});

/// Only archived tickets.
final archivedHeldOrdersProvider = Provider<List<HeldOrder>>((ref) {
  return ref.watch(heldOrdersProvider).where((t) => t.isArchived).toList();
});
