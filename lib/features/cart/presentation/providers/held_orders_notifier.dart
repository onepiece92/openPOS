import 'dart:async';
import 'dart:convert';
import 'dart:math';

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

  /// Tickets being paid in this run (between [beginPayment] and
  /// [paymentDone] / [paymentFailed]); [settlePaidTickets] leaves them be.
  final Set<String> _paying = {};

  @override
  List<HeldOrder> build() {
    // A ticket still marked as being paid is left over from a run that
    // ended mid-sale: settle it before it is ever offered again.
    if (_box.keys.any((k) => _payingKeyOf(k) != null)) {
      Future.microtask(() async {
        try {
          await settlePaidTickets();
        } catch (_) {/* tried again on resume and next launch */}
      });
    }
    return _loadAll();
  }

  Map<String, dynamic>? _raw(Object? key) {
    if (key == kTicketSeqKey) return null;
    final value = _box.get(key);
    if (value is! String) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String? _payingKeyOf(Object? key) {
    final paying = _raw(key)?[_kPayingField];
    return paying is Map ? paying['key'] as String? : null;
  }

  HeldOrder? _ticket(String id) {
    final raw = _raw(id);
    if (raw == null) return null;
    try {
      return HeldOrder.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  /// Writes [ticket], keeping a payment marker the stored copy carries (a
  /// ticket saved again while it is being paid must stay marked).
  Future<void> _write(HeldOrder ticket) {
    final json = ticket.toJson();
    final paying = _raw(ticket.id)?[_kPayingField];
    if (paying != null) json[_kPayingField] = paying;
    return _box.put(ticket.id, jsonEncode(json));
  }

  List<HeldOrder> _loadAll() {
    return _box
        .toMap()
        .entries
        .where((e) => e.key != kTicketSeqKey)
        .map((e) {
          try {
            final json = jsonDecode(e.value as String) as Map<String, dynamic>;
            // Being paid, or paid before a kill and not yet settled: never
            // listed, so it cannot be resumed and charged again.
            if (json[_kPayingField] != null) return null;
            return HeldOrder.fromJson(json);
          } catch (_) {
            return null;
          }
        })
        .whereType<HeldOrder>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ── Paying a held ticket ────────────────────────────────────────────────
  //
  // Paying a resumed ticket is two stores: the order goes to the database
  // and the ticket leaves Hive. A kill between them must not leave a ticket
  // that can be sold again, so:
  //  1. [beginPayment] writes a random sale key on the ticket and flushes it
  //     to disk before the sale. A marked ticket is not listed.
  //  2. `placeOrder` records the same key with the order (in the audit
  //     entry of the sale's own transaction).
  //  3. [paymentDone] deletes the ticket (awaited); [paymentFailed] removes
  //     the mark.
  // A mark found later (a kill between 1 and 3) is settled by
  // [settlePaidTickets]: an order with the key exists → the ticket is
  // deleted; none → the sale never happened and the mark is removed.

  /// Marks ticket [id] as being paid; returns the sale key to hand to
  /// `placeOrder`, or null when there is no such ticket. Throws when the
  /// mark cannot be written — the sale must not go ahead then.
  Future<String?> beginPayment(String id) async {
    final raw = _raw(id);
    if (raw == null) return null;
    final rnd = Random.secure();
    final key = [
      for (var i = 0; i < 16; i++)
        rnd.nextInt(256).toRadixString(16).padLeft(2, '0')
    ].join();
    raw[_kPayingField] = {
      'key': key,
      'at': DateTime.now().toUtc().toIso8601String(),
    };
    _paying.add(id);
    try {
      await _box.put(id, jsonEncode(raw));
      await _box.flush();
    } catch (_) {
      _paying.remove(id);
      rethrow;
    }
    state = _loadAll();
    return key;
  }

  /// The sale for ticket [id] is saved: the ticket is deleted.
  Future<void> paymentDone(String id) async {
    try {
      await _box.delete(id);
      await _box.flush();
    } finally {
      _paying.remove(id);
      state = _loadAll();
    }
  }

  /// The sale for ticket [id] was not saved: the ticket is listed again.
  Future<void> paymentFailed(String id) async {
    try {
      final raw = _raw(id);
      if (raw != null && raw.remove(_kPayingField) != null) {
        await _box.put(id, jsonEncode(raw));
      }
    } finally {
      _paying.remove(id);
      state = _loadAll();
    }
  }

  /// Settles tickets left marked by a run that ended mid-sale (see above).
  /// Returns how many were deleted as already paid. A ticket whose order
  /// cannot be looked up stays hidden until the next try.
  Future<int> settlePaidTickets() async {
    var removed = 0;
    for (final id in _box.keys.toList()) {
      if (id is! String || _paying.contains(id)) continue;
      final raw = _raw(id);
      final paying = raw?[_kPayingField];
      if (paying is! Map) continue;
      final bool sold;
      try {
        sold = await _soldWith(paying);
      } catch (_) {
        continue;
      }
      if (_paying.contains(id)) continue; // paid again meanwhile
      if (sold) {
        await _box.delete(id);
        removed++;
      } else {
        raw!.remove(_kPayingField);
        await _box.put(id, jsonEncode(raw));
      }
    }
    await _box.flush();
    state = _loadAll();
    return removed;
  }

  Future<bool> _soldWith(Map<dynamic, dynamic> paying) {
    final key = paying['key'] as String;
    final at = DateTime.tryParse(paying['at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return ref.read(databaseProvider).auditDao.hasSaleKey(key, at.toLocal());
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
    _write(ticket);
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
    // From the box, not the list: a ticket being paid is not listed.
    final existing = _ticket(id) ?? state.firstWhere((t) => t.id == id);
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
    _write(updated);
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
        : (existingId == null ? null : _ticket(existingId)?.customerName);
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
  /// no lines is left as it is (see [ResumeCheck.emptied]). A changed ticket is saved back, so it is cleaned only once.
  /// When the database cannot be read the ticket is returned unchanged
  /// (payment still refuses dead ids, see `placeOrder`).
  ///
  /// A ticket marked as being paid (see [beginPayment]) is never resumed: it
  /// is settled first — deleted when its sale was saved — and the result
  /// says [ResumeCheck.paid] or [ResumeCheck.busy].
  Future<ResumeCheck> checkForResume(HeldOrder ticket) async {
    final paying = _raw(ticket.id)?[_kPayingField];
    if (!_box.containsKey(ticket.id)) {
      // Deleted meanwhile — sold (and settled) or removed by hand.
      state = _loadAll();
      return ResumeCheck(ticket, paid: true);
    }
    if (paying is Map) {
      if (_paying.contains(ticket.id)) return ResumeCheck(ticket, busy: true);
      await settlePaidTickets();
      if (!_box.containsKey(ticket.id)) return ResumeCheck(ticket, paid: true);
      if (_raw(ticket.id)?[_kPayingField] != null) {
        return ResumeCheck(ticket, busy: true); // could not be checked
      }
    }
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
      parts.add("SELECT CASE is_active WHEN 1 THEN 'x' ELSE 'y' END AS k, id "
          'FROM tax_rates WHERE id IN (${List.filled(rateIds.length, '?').join(', ')})');
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
    final offRates = <int>{};
    var customer = false, table = false;
    for (final r in rows) {
      switch (r.read<String>('k')) {
        case 'p':
          live.add(r.read<int>('id'));
        case 'x':
          liveRates.add(r.read<int>('id'));
        case 'y':
          offRates.add(r.read<int>('id'));
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
        liveTaxRateIds: liveRates,
        offTaxRateIds: offRates);
    // An emptied ticket is left untouched: a soft-deleted product can be
    // reactivated, and the cashier decides whether to delete it.
    if (!check.emptied && check.changed && _box.containsKey(ticket.id)) {
      // Like every write here: the box updates in memory at once.
      unawaited(_write(check.ticket));
      state = _loadAll();
    }
    return check;
  }

  /// Whether ticket [id] is still stored and not being (or already) paid:
  /// a cart may be bound to it again.
  bool isResumable(String id) =>
      _box.containsKey(id) && _raw(id)?[_kPayingField] == null;

  /// How many held tickets have a line for [productId] (one scan of the
  /// in-memory list). Used to warn before a product is deleted.
  int ticketsWithProduct(int productId) =>
      heldTicketsWithProduct(state, productId);

  /// Archives a held ticket by id.
  void archive(String id) {
    final ticket = state.firstWhere((t) => t.id == id);
    final archived = ticket.copyWith(archivedAt: DateTime.now());
    _write(archived);
    state = _loadAll();
  }

  /// Unarchives a ticket (moves it back to active).
  void unarchive(String id) {
    final ticket = state.firstWhere((t) => t.id == id);
    final restored = ticket.copyWith(clearArchived: true);
    _write(restored);
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
      _write(archived);
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

/// Field of a stored ticket that marks it as being paid: `{key, at}`.
const _kPayingField = 'paying';

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
