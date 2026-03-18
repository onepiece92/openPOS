import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/cart_notifier.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/customers/domain/customers_provider.dart';

// ── Hive box provider ─────────────────────────────────────────────────────────

final heldOrdersBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>('held_orders');
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class HeldOrdersNotifier extends Notifier<List<HeldOrder>> {
  Box<dynamic> get _box => ref.read(heldOrdersBoxProvider);

  @override
  List<HeldOrder> build() => _loadAll();

  List<HeldOrder> _loadAll() {
    return _box.values
        .map((raw) {
          try {
            return HeldOrder.fromJson(
                jsonDecode(raw as String) as Map<String, dynamic>);
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
    String? label,
    String? customerName,
    int? customerId,
    double orderDiscount = 0.0,
    bool orderDiscountIsPercent = false,
  }) {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final ticket = HeldOrder(
      id: id,
      label: label ?? customerName ?? 'Ticket #${state.length + 1}',
      createdAt: now,
      items: items,
      customerName: customerName,
      customerId: customerId,
      orderDiscount: orderDiscount,
      orderDiscountIsPercent: orderDiscountIsPercent,
    );
    _box.put(id, jsonEncode(ticket.toJson()));
    state = _loadAll();
    return ticket;
  }

  /// Holds the current cart + session state as a ticket in one call.
  HeldOrder holdCurrentCart() {
    final cart = ref.read(cartProvider);
    final session = ref.read(cartSessionProvider);
    final customerName = ref.read(cartCustomerNameProvider);
    return hold(
      cart,
      customerName: customerName,
      customerId: session.customerId,
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
