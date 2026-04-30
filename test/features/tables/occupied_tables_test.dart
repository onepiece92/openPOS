import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/cart_notifier.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/cart/domain/held_orders_notifier.dart';
import 'package:pos_app/features/tables/domain/tables_provider.dart';

ProviderContainer _container({
  List<HeldOrder> heldOrders = const [],
  CartSession? session,
}) {
  return ProviderContainer(
    overrides: [
      activeHeldOrdersProvider.overrideWithValue(heldOrders),
      if (session != null)
        cartSessionProvider.overrideWith(_FixedSessionNotifier.new),
    ],
  );
}

class _FixedSessionNotifier extends CartSessionNotifier {
  // Fall back to fresh() — we override per-test by calling setTable directly.
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
        label: 'A',
        createdAt: DateTime(2026),
        items: const <CartItem>[],
        tableId: 7,
      ),
      HeldOrder(
        id: '2',
        label: 'B',
        createdAt: DateTime(2026),
        items: const <CartItem>[],
      ), // no table
      HeldOrder(
        id: '3',
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
    final c = _container(session: CartSession.fresh());
    c.read(cartSessionProvider.notifier).setTable(42);
    expect(c.read(occupiedTableIdsProvider), {42});
    c.dispose();
  });

  test('unions held orders + cart session tableId', () {
    final held = [
      HeldOrder(
        id: '1',
        label: 'A',
        createdAt: DateTime(2026),
        items: const <CartItem>[],
        tableId: 7,
      ),
    ];
    final c = _container(heldOrders: held, session: CartSession.fresh());
    c.read(cartSessionProvider.notifier).setTable(42);
    expect(c.read(occupiedTableIdsProvider), {7, 42});
    c.dispose();
  });
}
