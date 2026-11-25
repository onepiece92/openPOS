import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart' show Product;
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

/// A held ticket must come back with the tax state it was parked with.
void main() {
  late Directory tmp;
  late Box<dynamic> box;
  late ProviderContainer c;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_held_tax_');
    Hive.init(tmp.path);
    box = await Hive.openBox<dynamic>('held_orders');
    await Hive.openBox<dynamic>('settings');
    c = ProviderContainer(overrides: [
      heldOrdersBoxProvider.overrideWithValue(box),
      productsStreamProvider
          .overrideWith((ref) => Stream.value(const <Product>[])),
    ]);
  });

  tearDown(() async {
    c.dispose();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  CartItem item(int id) => CartItem(
        productId: id,
        name: 'P$id',
        unitPrice: 10.0,
        quantity: 1,
        isTaxable: true,
      );

  /// Resume the way the held-tickets sheet does.
  void resume(HeldOrder ticket) {
    final cart = c.read(cartProvider.notifier);
    cart.clearItems();
    for (final i in ticket.items) {
      cart.restoreItem(i);
    }
    c.read(cartSessionProvider.notifier).resumeTicket(ticket);
  }

  test('tax switched off survives hold → resume', () {
    c.read(cartProvider.notifier).addItem(item(1));
    c.read(cartSessionProvider.notifier).setTaxEnabled(false);
    final ticket = c.read(heldOrdersProvider.notifier).holdCurrentCart();
    c.read(cartProvider.notifier).clear();
    expect(c.read(cartSessionProvider).taxEnabled, isTrue);

    resume(c.read(heldOrdersProvider).single);

    expect(ticket.id, c.read(cartSessionProvider).heldTicketId);
    expect(c.read(cartSessionProvider).taxEnabled, isFalse);
  });

  test('choosing a rate replaces the previous one: one rate per cart', () {
    final rates = c.read(selectedTaxRatesProvider.notifier);
    rates.select(7);
    expect(c.read(selectedTaxRatesProvider), [7]);
    rates.select(9);
    expect(c.read(selectedTaxRatesProvider), [9]);
    rates.clear();
    expect(c.read(selectedTaxRatesProvider), isEmpty);
  });

  test('the selected tax rate survives hold → resume', () {
    c.read(cartProvider.notifier).addItem(item(1));
    c.read(selectedTaxRatesProvider.notifier).select(9);
    c.read(heldOrdersProvider.notifier).holdCurrentCart();
    c.read(cartProvider.notifier).clear();
    expect(c.read(selectedTaxRatesProvider), isEmpty);

    resume(c.read(heldOrdersProvider).single);

    expect(c.read(selectedTaxRatesProvider), [9]);
  });

  test('a ticket parked with several rates still loads, and resumes with '
      'the first', () {
    // Exactly what a build that allowed several rates per cart wrote.
    box.put(
        '#0008',
        jsonEncode({
          'id': '#0008',
          'ticketNumber': '#0008',
          'label': 'Ticket #0008',
          'createdAt': DateTime(2026, 1, 1).toIso8601String(),
          'taxRateIds': [7, 9],
          'items': [
            {
              'productId': 1,
              'name': 'P1',
              'unitPrice': 10.0,
              'quantity': 2,
              'isTaxable': true,
              'lineDiscount': 0.0,
            }
          ],
        }));
    final ticket = c.read(heldOrdersProvider).single;
    expect(ticket.taxRateIds, [7, 9], reason: 'the ticket itself is untouched');

    resume(ticket);
    expect(c.read(selectedTaxRatesProvider), [7]);
    expect(c.read(cartProvider).single.quantity, 2);

    // Saving it again writes the single rate it now carries.
    c.read(heldOrdersProvider.notifier).holdCurrentCart();
    expect(c.read(heldOrdersProvider).single.taxRateIds, [7]);
  });

  test('a ticket held with every rate removed resumes with none', () {
    c.read(cartProvider.notifier).addItem(item(1));
    c.read(heldOrdersProvider.notifier).holdCurrentCart();
    c.read(cartProvider.notifier).clear();
    // Something else is selected by the time the ticket comes back.
    c.read(selectedTaxRatesProvider.notifier).select(3);

    resume(c.read(heldOrdersProvider).single);

    expect(c.read(selectedTaxRatesProvider), isEmpty);
  });

  test('tax state survives a save of the resumed ticket and a cold reload',
      () {
    c.read(cartProvider.notifier).addItem(item(1));
    c.read(cartSessionProvider.notifier).setTaxEnabled(false);
    c.read(selectedTaxRatesProvider.notifier).select(7);
    c.read(heldOrdersProvider.notifier).holdCurrentCart();
    c.read(cartProvider.notifier).clear();

    resume(c.read(heldOrdersProvider).single);
    c.read(cartProvider.notifier).addItem(item(2));
    c.read(heldOrdersProvider.notifier).holdCurrentCart(); // update in place
    c.read(heldOrdersProvider.notifier).archive(
        c.read(heldOrdersProvider).single.id); // copyWith path

    // Straight off disk, as after an app restart.
    final raw = jsonDecode(box.values.whereType<String>().single)
        as Map<String, dynamic>;
    final reloaded = HeldOrder.fromJson(raw);
    expect(reloaded.items, hasLength(2));
    expect(reloaded.taxEnabled, isFalse);
    expect(reloaded.taxRateIds, [7]);
  });

  test('tickets saved before tax state was stored still load, with the '
      'old behaviour', () {
    // Exactly what an older build wrote: no tax fields at all.
    box.put(
        '#0007',
        jsonEncode({
          'id': '#0007',
          'ticketNumber': '#0007',
          'label': 'Ticket #0007',
          'createdAt': DateTime(2026, 1, 1).toIso8601String(),
          'items': [
            {
              'productId': 1,
              'name': 'P1',
              'unitPrice': 10.0,
              'quantity': 2,
              'isTaxable': true,
              'lineDiscount': 0.0,
            }
          ],
        }));
    final ticket = c.read(heldOrdersProvider).single;
    expect(ticket.items.single.quantity, 2);

    c.read(cartSessionProvider.notifier).setTaxEnabled(false);
    c.read(selectedTaxRatesProvider.notifier).select(3);
    resume(ticket);

    // Old behaviour: tax on, rates back to the store default (none here).
    expect(c.read(cartSessionProvider).taxEnabled, isTrue);
    expect(c.read(selectedTaxRatesProvider), isEmpty);
  });
}
