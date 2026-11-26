import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// Resuming a held ticket drops what no longer exists: products (deleted,
/// or gone after a factory reset / backup restore), the customer, the table.
void main() {
  late Directory tmp;
  late Box<dynamic> box;
  late AppDatabase db;
  late ProviderContainer c;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_resume_check_');
    Hive.init(tmp.path);
    box = await Hive.openBox<dynamic>('held_orders');
    await Hive.openBox<dynamic>('settings');
    db = openInMemoryDatabase();
    c = ProviderContainer(overrides: [
      heldOrdersBoxProvider.overrideWithValue(box),
      databaseProvider.overrideWithValue(db),
    ]);
  });

  tearDown(() async {
    c.dispose();
    await db.close();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  CartItem item(int id) => CartItem(
        productId: id,
        name: 'P$id',
        unitPrice: 10.0,
        quantity: 1,
        isTaxable: false,
      );

  HeldOrder park(List<int> productIds, {int? customerId, int? tableId}) =>
      c.read(heldOrdersProvider.notifier).hold(
        [for (final id in productIds) item(id)],
        ticketNumber: '#00${box.length + 1}',
        customerName: customerId == null ? null : 'Asha',
        customerId: customerId,
        tableId: tableId,
      );

  Future<int> table() =>
      db.into(db.tables).insert(TablesCompanion.insert(name: 'T1'));

  test('nothing missing: the ticket comes back as it was', () async {
    final a = await seedProduct(db, sku: 'A');
    final cust = await seedCustomer(db);
    final t = await table();
    final held = park([a], customerId: cust, tableId: t);
    final before = box.get(held.id);

    final check =
        await c.read(heldOrdersProvider.notifier).checkForResume(held);

    expect(check.changed, isFalse);
    expect(check.message, isNull);
    expect(identical(check.ticket, held), isTrue);
    expect(box.get(held.id), before);
  });

  test('a product deleted while on the ticket is dropped (one item)', () async {
    final a = await seedProduct(db, sku: 'A');
    final b = await seedProduct(db, sku: 'B');
    final held = park([a, b]);
    await db.productsDao.softDelete(b);

    final check =
        await c.read(heldOrdersProvider.notifier).checkForResume(held);

    expect(check.ticket.items.map((i) => i.productId), [a]);
    expect(check.message, '1 item no longer exists and was removed');
    // Saved back: the next resume finds nothing to remove.
    final saved = HeldOrder.fromJson(
        jsonDecode(box.get(held.id) as String) as Map<String, dynamic>);
    expect(saved.items.map((i) => i.productId), [a]);
    expect(saved.ticketNumber, held.ticketNumber);
    expect(c.read(heldOrdersProvider).single.items, hasLength(1));
    final again =
        await c.read(heldOrdersProvider.notifier).checkForResume(saved);
    expect(again.changed, isFalse);
  });

  test('after a factory reset: every line, the customer and the table go',
      () async {
    final a = await seedProduct(db, sku: 'A');
    final b = await seedProduct(db, sku: 'B');
    final cust = await seedCustomer(db);
    final t = await table();
    final held = park([a, b], customerId: cust, tableId: t);
    await db.eraseAllData();

    final check =
        await c.read(heldOrdersProvider.notifier).checkForResume(held);

    expect(check.ticket.items, isEmpty);
    expect(check.ticket.customerId, isNull);
    expect(check.ticket.customerName, isNull);
    expect(check.ticket.tableId, isNull);
    expect(check.message, '2 items no longer exist and were removed');
  });

  test('after restoring a backup without these ids: dropped too', () async {
    final a = await seedProduct(db, sku: 'A');
    // Ids from another database: no such product, customer or table.
    final held = park([a, 404, 405], customerId: 77, tableId: 88);

    final check =
        await c.read(heldOrdersProvider.notifier).checkForResume(held);

    expect(check.ticket.items.map((i) => i.productId), [a]);
    expect(check.ticket.customerId, isNull);
    expect(check.ticket.tableId, isNull);
    expect(check.message, '2 items no longer exist and were removed');
  });

  test('only the customer gone: cleared, no item message', () async {
    final a = await seedProduct(db, sku: 'A');
    final cust = await seedCustomer(db);
    final held = park([a], customerId: cust);
    await (db.delete(db.customers)..where((x) => x.id.equals(cust))).go();

    final check =
        await c.read(heldOrdersProvider.notifier).checkForResume(held);

    expect(check.changed, isTrue);
    expect(check.ticket.customerId, isNull);
    expect(check.ticket.items, hasLength(1));
    expect(check.message, isNull);
  });

  test('deleting a product: how many held tickets it is on, and the warning',
      () async {
    final a = await seedProduct(db, sku: 'A');
    final b = await seedProduct(db, sku: 'B');
    park([a, b]);
    park([a]);
    final archived = park([a]);
    c.read(heldOrdersProvider.notifier).archive(archived.id);
    final n = c.read(heldOrdersProvider.notifier);

    expect(n.ticketsWithProduct(a), 3);
    expect(n.ticketsWithProduct(b), 1);
    expect(n.ticketsWithProduct(999), 0);
    expect(
        productOnHeldTicketsWarning(3),
        'This product is on 3 held tickets. It will be removed from them '
        'when they are resumed.');
    expect(
        productOnHeldTicketsWarning(1),
        'This product is on 1 held ticket. It will be removed from it when '
        'it is resumed.');
    expect(productOnHeldTicketsWarning(0), isNull);
  });

  test('a cleaned ticket keeps everything else it was parked with', () {
    final t = HeldOrder(
      id: 'x',
      ticketNumber: '#0009',
      label: 'Window',
      createdAt: DateTime(2026, 1, 1),
      items: [item(1), item(2)],
      tableId: 3,
      orderDiscount: 5,
      taxRateIds: const [4],
    );
    final r = checkHeldOrder(t,
        liveProductIds: {1}, customerExists: false, tableExists: true);
    expect(r.ticket.label, 'Window');
    expect(r.ticket.tableId, 3);
    expect(r.ticket.orderDiscount, 5);
    expect(r.ticket.taxRateIds, [4]);
    expect(r.removedLines, 1);
  });
}
