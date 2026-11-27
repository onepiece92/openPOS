import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// Paying a resumed held ticket writes the order (Drift) and then deletes
/// the ticket (Hive). A kill between the two must never leave a ticket that
/// can be charged a second time; a kill before the sale must keep it.
void main() {
  late Directory tmp;
  late Box<dynamic> box;
  late AppDatabase db;
  late ProviderContainer c;
  late int productId;

  ProviderContainer container() => ProviderContainer(overrides: [
        heldOrdersBoxProvider.overrideWithValue(box),
        databaseProvider.overrideWithValue(db),
      ]);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_paid_once_');
    Hive.init(tmp.path);
    box = await Hive.openBox<dynamic>('held_orders');
    db = openInMemoryDatabase();
    productId = await seedProduct(db, sku: 'TEA', stock: 10);
    c = container();
  });

  tearDown(() async {
    c.dispose();
    await db.close();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  HeldOrder park() => c
      .read(heldOrdersProvider.notifier)
      .hold([line(productId, qty: 2)], ticketNumber: '#0001');

  /// The app is killed and started again: the box is closed and reopened
  /// from its file, and a new container (new notifier) reads it.
  Future<void> relaunch() async {
    c.dispose();
    await box.close();
    box = await Hive.openBox<dynamic>('held_orders');
    c = container();
  }

  Future<int> orderCount() async => (await db.select(db.orders).get()).length;

  test(
      'killed after the sale is saved, before the ticket is deleted: '
      'the ticket is gone on relaunch and cannot be sold again', () async {
    final ticket = park();
    final key =
        await c.read(heldOrdersProvider.notifier).beginPayment(ticket.id);
    expect(key, isNotNull);
    await sell(db, AuditService(db), [line(productId, qty: 2)], saleKey: key);
    // Killed here: paymentDone never runs.

    await relaunch();

    // Never offered, not even before the check has run.
    expect(c.read(heldOrdersProvider), isEmpty);
    final removed =
        await c.read(heldOrdersProvider.notifier).settlePaidTickets();
    expect(removed, 1);
    expect(box.containsKey(ticket.id), isFalse);
    expect(c.read(heldOrdersProvider), isEmpty);

    // A stale copy of the ticket (an open list) cannot be resumed.
    final check =
        await c.read(heldOrdersProvider.notifier).checkForResume(ticket);
    expect(check.paid, isTrue);
    expect(check.message, kTicketPaidMessage);
    expect(await orderCount(), 1, reason: 'one sale, one order');
    expect((await product(db, productId)).stockQuantity, 8,
        reason: 'stock taken once');
  });

  test('killed after the sale: resuming settles the ticket before loading',
      () async {
    final ticket = park();
    final key =
        await c.read(heldOrdersProvider.notifier).beginPayment(ticket.id);
    await sell(db, AuditService(db), [line(productId, qty: 2)], saleKey: key);

    await relaunch();
    // Resumed before the launch check had a chance to run.
    final check =
        await c.read(heldOrdersProvider.notifier).checkForResume(ticket);
    expect(check.paid, isTrue);
    expect(box.containsKey(ticket.id), isFalse);
    expect(await orderCount(), 1);
  });

  test(
      'killed before the sale is saved: the ticket is resumable again and '
      'no order exists', () async {
    final ticket = park();
    await c.read(heldOrdersProvider.notifier).beginPayment(ticket.id);
    // Killed here: the sale's transaction never committed.

    await relaunch();
    final removed =
        await c.read(heldOrdersProvider.notifier).settlePaidTickets();
    expect(removed, 0);
    expect(c.read(heldOrdersProvider).map((t) => t.id), [ticket.id]);
    final check =
        await c.read(heldOrdersProvider.notifier).checkForResume(ticket);
    expect(check.paid, isFalse);
    expect(check.busy, isFalse);
    expect(check.ticket.items.single.quantity, 2);
    expect(await orderCount(), 0);
  });

  test('a sale that fails lists the ticket again', () async {
    final ticket = park();
    final n = c.read(heldOrdersProvider.notifier);
    await n.beginPayment(ticket.id);
    expect(c.read(heldOrdersProvider), isEmpty, reason: 'hidden while paid');
    await n.paymentFailed(ticket.id);
    expect(c.read(heldOrdersProvider).map((t) => t.id), [ticket.id]);
  });

  test('a ticket being paid is not resumed and not settled away', () async {
    final ticket = park();
    final n = c.read(heldOrdersProvider.notifier);
    await n.beginPayment(ticket.id);
    expect((await n.checkForResume(ticket)).busy, isTrue);
    expect(await n.settlePaidTickets(), 0);
    expect(box.containsKey(ticket.id), isTrue);
    await n.paymentDone(ticket.id);
    expect(box.containsKey(ticket.id), isFalse);
  });

  test('saving the ticket again while it is paid keeps the mark', () async {
    final ticket = park();
    final n = c.read(heldOrdersProvider.notifier);
    final key = await n.beginPayment(ticket.id);
    n.update(ticket.id, items: [line(productId, qty: 3)]);
    await sell(db, AuditService(db), [line(productId, qty: 2)], saleKey: key);

    await relaunch();
    expect(await c.read(heldOrdersProvider.notifier).settlePaidTickets(), 1);
    expect(box.containsKey(ticket.id), isFalse);
  });

  test('a ticket deleted elsewhere is "no longer available", not "paid"',
      () async {
    final ticket = park();
    c.read(heldOrdersProvider.notifier).delete(ticket.id);
    final check =
        await c.read(heldOrdersProvider.notifier).checkForResume(ticket);
    expect(check.paid, isFalse);
    expect(check.gone, isTrue);
    expect(check.message, kTicketGoneMessage);
    expect(kTicketGoneMessage, 'This ticket is no longer available.');
  });
}
