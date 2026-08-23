import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/cart/data/ticket_sequence.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';
import 'package:pos_app/features/tables/domain/tables_provider.dart';

ProviderContainer _container({
  List<HeldOrder> heldOrders = const [],
  CartSession? session,
}) {
  return ProviderContainer(
    overrides: [
      // cartSessionProvider draws its ticket number from the persisted
      // counter; these tests care only about tableId, so keep Hive out of it.
      ticketSequenceProvider.overrideWithValue(_MemorySequence()),
      activeHeldOrdersProvider.overrideWithValue(heldOrders),
      if (session != null)
        cartSessionProvider.overrideWith(_FixedSessionNotifier.new),
    ],
  );
}

class _MemorySequence implements TicketSequence {
  int _n = 0;
  @override
  String next() => formatTicketNumber(++_n);
}

class _FixedSessionNotifier extends CartSessionNotifier {
  // Bypasses the persisted ticket counter, which would need an open Hive box.
  // These tests only care about tableId; we set it per-test via setTable.
  @override
  CartSession build() =>
      CartSession(ticketNumber: '#0001', openedAt: DateTime(2026));
}

void main() {
  test('empty when no held orders and no cart table', () {
    final c = _container();
    expect(c.read(occupiedTableIdsProvider), isEmpty);
    c.dispose();
  });

  test('includes held order tableIds (skipping nulls)', () {
    final held = [
      HeldOrder(
        id: '1',
        ticketNumber: '#0001',
        label: 'A',
        createdAt: DateTime(2026),
        items: const <CartItem>[],
        tableId: 7,
      ),
      HeldOrder(
        id: '2',
        ticketNumber: '#0002',
        label: 'B',
        createdAt: DateTime(2026),
        items: const <CartItem>[],
      ), // no table
      HeldOrder(
        id: '3',
        ticketNumber: '#0003',
        label: 'C',
        createdAt: DateTime(2026),
        items: const <CartItem>[],
        tableId: 9,
      ),
    ];
    final c = _container(heldOrders: held);
    expect(c.read(occupiedTableIdsProvider), {7, 9});
    c.dispose();
  });

  test('includes the active cart session tableId', () {
    final c = _container(session: CartSession.fresh('#0001'));
    c.read(cartSessionProvider.notifier).setTable(42);
    expect(c.read(occupiedTableIdsProvider), {42});
    c.dispose();
  });

  test('unions held orders + cart session tableId', () {
    final held = [
      HeldOrder(
        id: '1',
        ticketNumber: '#0001',
        label: 'A',
        createdAt: DateTime(2026),
        items: const <CartItem>[],
        tableId: 7,
      ),
    ];
    final c = _container(heldOrders: held, session: CartSession.fresh('#0001'));
    c.read(cartSessionProvider.notifier).setTable(42);
    expect(c.read(occupiedTableIdsProvider), {7, 42});
    c.dispose();
  });
}
