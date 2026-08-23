import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/features/cart/data/ticket_sequence.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';

/// A held ticket keeps its number for life: resuming it, editing it and saving
/// it again must rewrite the same row rather than mint a new ticket.
void main() {
  late Directory tmp;
  late Box<dynamic> box;

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [heldOrdersBoxProvider.overrideWithValue(box)],
      );

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_held_');
    Hive.init(tmp.path);
    box = await Hive.openBox<dynamic>('held_orders');
    // main() opens every kSnapshotHiveBoxes entry; the cart's tax defaults
    // read the settings box, so mirror that here.
    await Hive.openBox<dynamic>('settings');
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  CartItem item(int id, {int qty = 1}) => CartItem(
        productId: id,
        name: 'P$id',
        unitPrice: 10.0,
        quantity: qty,
        isTaxable: true,
      );

  test('the counter climbs and never reuses a number', () {
    final c = makeContainer();
    addTearDown(c.dispose);
    final seq = c.read(ticketSequenceProvider);
    expect(seq.next(), '#0001');
    expect(seq.next(), '#0002');
    expect(seq.next(), '#0003');
  });

  test('the counter survives a cold reopen of the box', () {
    final first = makeContainer();
    expect(first.read(ticketSequenceProvider).next(), '#0001');
    first.dispose();

    // Same box, brand new container — the number must not restart.
    final second = makeContainer();
    addTearDown(second.dispose);
    expect(second.read(ticketSequenceProvider).next(), '#0002');
  });

  test('resume → add item → save keeps the same ticket number and id', () {
    final c = makeContainer();
    addTearDown(c.dispose);
    final cart = c.read(cartProvider.notifier);
    final held = c.read(heldOrdersProvider.notifier);

    cart.addItem(item(1));
    final original = held.holdCurrentCart();
    cart.clear();

    expect(c.read(heldOrdersProvider), hasLength(1));

    // Resume it the way the held-tickets sheet does.
    cart.clearItems();
    for (final i in original.items) {
      cart.addItem(i);
    }
    c.read(cartSessionProvider.notifier).resumeTicket(original);

    // Edit and save again.
    cart.addItem(item(2));
    final saved = held.holdCurrentCart();

    expect(c.read(heldOrdersProvider), hasLength(1),
        reason: 'saving an edit must not create a second ticket');
    expect(saved.ticketNumber, original.ticketNumber);
    expect(saved.id, original.id);
    expect(saved.label, original.label);
    expect(saved.createdAt, original.createdAt,
        reason: 'the ticket must hold its place in the list');
    expect(saved.items, hasLength(2));
  });

  test('a new cart after saving gets the next number, not a reused one', () {
    final c = makeContainer();
    addTearDown(c.dispose);
    final cart = c.read(cartProvider.notifier);
    final held = c.read(heldOrdersProvider.notifier);

    cart.addItem(item(1));
    final first = held.holdCurrentCart();
    cart.clear();

    cart.addItem(item(2));
    final second = held.holdCurrentCart();

    expect(second.ticketNumber, isNot(first.ticketNumber));
    expect(c.read(heldOrdersProvider).map((t) => t.ticketNumber).toSet(),
        hasLength(2));
  });

  test('archiving does not let a later ticket reuse a number', () {
    final c = makeContainer();
    addTearDown(c.dispose);
    final cart = c.read(cartProvider.notifier);
    final held = c.read(heldOrdersProvider.notifier);

    cart.addItem(item(1));
    final first = held.holdCurrentCart();
    cart.clear();
    cart.addItem(item(2));
    final second = held.holdCurrentCart();
    cart.clear();

    // The old length-based label counter went backwards here.
    held.archive(first.id);
    cart.addItem(item(3));
    final third = held.holdCurrentCart();

    expect({first.ticketNumber, second.ticketNumber, third.ticketNumber},
        hasLength(3));
    expect(third.label, isNot(second.label));
  });

  test('tickets written before the counter existed keep a stable number', () {
    // A legacy row: no ticketNumber key.
    box.put('1700000000123', '{"id":"1700000000123","label":"Walk-in",'
        '"createdAt":"2026-04-22T10:00:00.000","items":[]}');

    final c = makeContainer();
    addTearDown(c.dispose);
    final legacy = c.read(heldOrdersProvider).single;
    expect(legacy.ticketNumber, '#0123');

    // The counter must clear the high-water mark it just found.
    expect(c.read(ticketSequenceProvider).next(), '#0124');
  });
}
