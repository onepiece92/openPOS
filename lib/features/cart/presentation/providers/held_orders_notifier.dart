import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/features/cart/data/ticket_sequence.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/customers/domain/customers_provider.dart';

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
    final customerName = ref.read(cartCustomerNameProvider);
    final existingId = session.heldTicketId;

    if (existingId != null && _box.containsKey(existingId)) {
      return update(
        existingId,
        items: cart,
        customerName: customerName,
        customerId: session.customerId,
        tableId: session.tableId,
        orderDiscount: session.orderDiscount,
        orderDiscountIsPercent: session.orderDiscountIsPercent,
      );
    }

    return hold(
      cart,
      ticketNumber: session.ticketNumber,
      customerName: customerName,
      customerId: session.customerId,
      tableId: session.tableId,
      orderDiscount: session.orderDiscount,
      orderDiscountIsPercent: session.orderDiscountIsPercent,
    );
  }

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
