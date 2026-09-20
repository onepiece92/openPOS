import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/printing/domain/auto_print.dart';
import 'package:pos_app/features/orders/domain/order_number.dart';
import 'package:pos_app/features/printing/domain/receipt_printer.dart';

import '../../_support/test_db.dart';

/// End-to-end auto-print against a fake [ReceiptPrinter]: load order →
/// assemble the job → hand it to the port. No plugin, no Bluetooth. What
/// each driver makes of the job (ESC/POS bytes, or an image for Star) is
/// covered by the render tests.
class FakeReceiptPrinter implements ReceiptPrinter {
  final printed = <({PrinterTarget target, ReceiptPrintJob job})>[];
  Object? failWith;

  @override
  Stream<List<DiscoveredPrinter>> get devices => const Stream.empty();
  @override
  Future<void> startScan() async {}
  @override
  Future<void> stopScan() async {}

  @override
  Future<void> printReceipt(PrinterTarget target, ReceiptPrintJob job) async {
    if (failWith != null) throw failWith!;
    printed.add((target: target, job: job));
  }

  @override
  Future<void> printTestPage(
    PrinterTarget target, {
    required String storeName,
    required int paperMm,
  }) async {
    if (failWith != null) throw failWith!;
  }
}

void main() {
  // Settings/Hive and the currency formatter need the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late Box<dynamic> box;
  late AppDatabase db;
  late FakeReceiptPrinter printer;

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        settingsBoxProvider.overrideWithValue(box),
        receiptPrinterProvider.overrideWithValue(printer),
      ]);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_print_');
    Hive.init(tmp.path);
    box = await Hive.openBox<dynamic>('settings');
    db = openInMemoryDatabase();
    printer = FakeReceiptPrinter();
  });

  tearDown(() async {
    await db.close();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  Future<int> seedOrder() async {
    final productId = await db.productsDao.upsert(
      ProductsCompanion.insert(sku: 'ESP', name: 'Espresso', price: 5),
    );
    final id = await db.ordersDao.insertOrder(OrdersCompanion.insert(
      invoiceNo: const Value(7),
      subtotal: 10,
      total: 10,
      paymentMethod: 'cash',
    ));
    await db.ordersDao.insertItems([
      OrderItemsCompanion.insert(
        orderId: id,
        productId: productId,
        productName: 'Espresso',
        unitPrice: 5,
        quantity: 2,
        lineTotal: 10,
      ),
    ]);
    return id;
  }

  test('no paired printer → success no-op, nothing printed', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final err =
        await c.read(autoPrintServiceProvider).printOrder(await seedOrder());
    expect(err, isNull);
    expect(printer.printed, isEmpty);
  });

  test('prints the receipt with store name, bill number and items', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c.read(settingsProvider.notifier).setStoreProfile(name: 'Test Shop');
    await c
        .read(settingsProvider.notifier)
        .setPrinterDevice(address: 'AA:BB', name: 'Rongta', driver: 'escpos');

    final err =
        await c.read(autoPrintServiceProvider).printOrder(await seedOrder());

    expect(err, isNull);
    expect(printer.printed, hasLength(1));
    final sent = printer.printed.single;
    expect(sent.target.address, 'AA:BB');
    expect(sent.job.data.businessName, 'Test Shop');
    expect(sent.job.data.order.billNo, '#7',
        reason: 'receipt must show the invoice number, not the row id');
    expect(sent.job.data.items.single.productName, 'Espresso');
    expect(sent.job.data.customer, isNull, reason: 'walk-in sale');
    expect(sent.job.paperMm, 80);
  });

  test('first print is the original; reprint is marked COPY and counted',
      () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c
        .read(settingsProvider.notifier)
        .setPrinterDevice(address: 'AA:BB', name: 'Rongta', driver: 'escpos');
    final orderId = await seedOrder();
    final svc = c.read(autoPrintServiceProvider);

    expect(await svc.printOrder(orderId), isNull);
    expect(printer.printed[0].job.isCopy, isFalse,
        reason: 'first print is the original');

    expect(await svc.printOrder(orderId), isNull);
    expect(printer.printed[1].job.isCopy, isTrue,
        reason: 'every print after the first is a marked copy');

    expect((await db.ordersDao.getById(orderId))!.printCount, 2);
  });

  test('transport failure surfaces as a short error string', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c
        .read(settingsProvider.notifier)
        .setPrinterDevice(address: 'AA:BB', name: 'Rongta', driver: 'escpos');
    printer.failWith = StateError('connect timeout');

    final err =
        await c.read(autoPrintServiceProvider).printOrder(await seedOrder());
    expect(err, contains('Printer:'));
    expect(err, contains('connect timeout'));
  });

  test('missing order reports without touching the printer', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c
        .read(settingsProvider.notifier)
        .setPrinterDevice(address: 'AA:BB', name: 'Rongta', driver: 'escpos');
    final err = await c.read(autoPrintServiceProvider).printOrder(999);
    expect(err, 'Order not found for printing');
    expect(printer.printed, isEmpty);
  });
}
