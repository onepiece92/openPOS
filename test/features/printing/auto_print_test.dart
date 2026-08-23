import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/printing/domain/auto_print.dart';
import 'package:pos_app/features/printing/domain/receipt_printer.dart';

import '../../_support/test_db.dart';

/// End-to-end auto-print against a fake [ReceiptPrinter]: load order →
/// render ESC/POS → hand bytes to the port. No plugin, no Bluetooth.
class FakeReceiptPrinter implements ReceiptPrinter {
  final printed = <({String address, String name, List<int> bytes})>[];
  Object? failWith;

  @override
  Stream<List<DiscoveredPrinter>> get devices => const Stream.empty();
  @override
  Future<void> startScan() async {}
  @override
  Future<void> stopScan() async {}

  @override
  Future<void> printBytes({
    required String address,
    required String name,
    required List<int> bytes,
  }) async {
    if (failWith != null) throw failWith!;
    printed.add((address: address, name: name, bytes: bytes));
  }
}

void main() {
  // renderReceiptBytes loads the ESC/POS capability profile via rootBundle.
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

  /// ESC/POS output embeds text as raw bytes — ASCII substrings are findable.
  bool bytesContain(List<int> bytes, String text) {
    final needle = text.codeUnits;
    for (var i = 0; i + needle.length <= bytes.length; i++) {
      var match = true;
      for (var j = 0; j < needle.length; j++) {
        if (bytes[i + j] != needle[j]) {
          match = false;
          break;
        }
      }
      if (match) return true;
    }
    return false;
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
        .setPrinterDevice(address: 'AA:BB', name: 'Rongta');

    final err =
        await c.read(autoPrintServiceProvider).printOrder(await seedOrder());

    expect(err, isNull);
    expect(printer.printed, hasLength(1));
    final job = printer.printed.single;
    expect(job.address, 'AA:BB');
    expect(bytesContain(job.bytes, 'Test Shop'), isTrue);
    expect(bytesContain(job.bytes, 'Bill #7'), isTrue,
        reason: 'receipt must show the invoice number, not the row id');
    expect(bytesContain(job.bytes, 'Espresso'), isTrue);
    expect(bytesContain(job.bytes, 'Walk-in'), isTrue);
  });

  test('first print is the original; reprint is marked COPY and counted',
      () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c
        .read(settingsProvider.notifier)
        .setPrinterDevice(address: 'AA:BB', name: 'Rongta');
    final orderId = await seedOrder();
    final svc = c.read(autoPrintServiceProvider);

    expect(await svc.printOrder(orderId), isNull);
    expect(bytesContain(printer.printed[0].bytes, 'COPY OF ORIGINAL'), isFalse,
        reason: 'first print is the original');

    expect(await svc.printOrder(orderId), isNull);
    expect(bytesContain(printer.printed[1].bytes, 'COPY OF ORIGINAL'), isTrue,
        reason: 'every print after the first is a marked copy');

    expect((await db.ordersDao.getById(orderId))!.printCount, 2);
  });

  test('transport failure surfaces as a short error string', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c
        .read(settingsProvider.notifier)
        .setPrinterDevice(address: 'AA:BB', name: 'Rongta');
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
        .setPrinterDevice(address: 'AA:BB', name: 'Rongta');
    final err = await c.read(autoPrintServiceProvider).printOrder(999);
    expect(err, 'Order not found for printing');
    expect(printer.printed, isEmpty);
  });
}
