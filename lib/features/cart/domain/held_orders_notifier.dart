import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';

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
  HeldOrder hold(List<CartItem> items, {String? label, String? customerName}) {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final ticket = HeldOrder(
      id: id,
      label: label ?? customerName ?? 'Ticket #${state.length + 1}',
      createdAt: now,
      items: items,
      customerName: customerName,
    );
    _box.put(id, jsonEncode(ticket.toJson()));
    state = _loadAll();
    return ticket;
  }

  /// Removes a held ticket by id.
  void delete(String id) {
    _box.delete(id);
    state = _loadAll();
  }

  /// Removes all held tickets.
  void deleteAll() {
    _box.clear();
    state = [];
  }
}

final heldOrdersProvider =
    NotifierProvider<HeldOrdersNotifier, List<HeldOrder>>(
        HeldOrdersNotifier.new);
