import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/backup/data/backup_repository.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';

import '../../_support/test_db.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory tmp;

  setUp(() async => tmp = await Directory.systemTemp.createTemp('pos_tipbk_'));
  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  Future<int> sale(AppDatabase db, int pid, {required double tip}) async {
    final id = await db.ordersDao.insertOrder(OrdersCompanion.insert(
      subtotal: 100,
      total: 100,
      paymentMethod: 'cash',
      tipAmount: Value(tip),
      createdAt: Value(DateTime(2026, 3, 1, 10, tip.toInt())),
    ));
    await db.ordersDao.insertItems([
      OrderItemsCompanion.insert(
          orderId: id,
          productId: pid,
          productName: 'Tea',
          unitPrice: 100,
          quantity: 1,
          lineTotal: 100),
    ]);
    return id;
  }

  test('CSV: Tip column follows Total; export then import keeps tips',
      () async {
    final src = openInMemoryDatabase();
    final dst = openInMemoryDatabase();
    addTearDown(src.close);
    addTearDown(dst.close);
    final pid = await src.productsDao
        .upsert(ProductsCompanion.insert(sku: 'TEA', name: 'Tea', price: 100));
    await dst.productsDao
        .upsert(ProductsCompanion.insert(sku: 'TEA', name: 'Tea', price: 100));
    await sale(src, pid, tip: 12.5);
    await sale(src, pid, tip: 0);

    final file = File(p.join(tmp.path, 'orders.csv'));
    await BackupRepository(src).writeOrdersCsv(file);
    final csv = await file.readAsString();
    final header = csv.split('\r\n').first.split(',');
    expect(header[header.indexOf('Total') + 1], 'Tip');

    final report = await BackupRepository(dst).importOrdersReport(csv);
    expect(report.added, 2);
    final tips = (await dst.select(dst.orders).get())
        .map((o) => o.tipAmount)
        .toList()
      ..sort();
    expect(tips, [0, 12.5]);
    expect((await dst.select(dst.orders).get()).every((o) => o.total == 100),
        isTrue);
  });

  test('CSV import without a Tip column gives every order tip 0', () async {
    final dst = openInMemoryDatabase();
    addTearDown(dst.close);
    await dst.productsDao
        .upsert(ProductsCompanion.insert(sku: 'TEA', name: 'Tea', price: 100));
    const csv = 'Order ID,Status,Subtotal,Tax Total,Discount,Total,'
        'Payment Method,Tendered,Change,Customer Name,Notes,Created At,'
        'Item Product ID,Item Name,Item SKU,Item Price,Item Qty,'
        'Item Discount,Item Tax,Item Total\r\n'
        '7,completed,100,0,0,100,cash,100,0,,,2026-03-01T10:00:00.000,'
        '1,Tea,TEA,100,1,0,0,100\r\n';
    final report = await BackupRepository(dst).importOrdersReport(csv);
    expect(report.added, 1);
    final o = (await dst.select(dst.orders).getSingle());
    expect(o.invoicePrefix, 'IMP');
    expect(o.tipAmount, 0);
  });

  test('a full backup carries tips (and refunded tips) through restore',
      () async {
    final live = await Directory(p.join(tmp.path, 'live')).create();
    final back = await Directory(p.join(tmp.path, 'back')).create();
    File dbIn(Directory d) => File(p.join(d.path, 'pos_database.db'));
    String hiveIn(Directory d) => p.join(d.path, 'settings.hive');

    final db = AppDatabase(NativeDatabase(dbIn(live)));
    final pid = await db.productsDao
        .upsert(ProductsCompanion.insert(sku: 'TEA', name: 'Tea', price: 100));
    final id = await sale(db, pid, tip: 9);
    await db.ordersDao.insertReturn(ReturnsCompanion.insert(
        orderId: id, amount: 10, tipAmount: const Value(4)));
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    await db.close();
    Hive.init(live.path);
    final box = await Hive.openBox<dynamic>('settings');
    await box.put('business_name', 'Shop');
    await box.flush();
    await Hive.close();

    const svc = SnapshotService();
    const schema = AppDatabase.currentSchemaVersion;
    final zip = await svc.create(
      dbFile: dbIn(live),
      hiveBoxFiles: {'settings': hiveIn(live)},
      outDir: Directory(p.join(tmp.path, 'out')),
      schemaVersion: schema,
      receiptsDir: Directory(p.join(live.path, 'receipts')),
    );
    await svc.restore(
      zip: zip,
      dbFile: dbIn(back),
      hiveBoxFiles: {'settings': hiveIn(back)},
      currentSchemaVersion: schema,
      receiptsDir: Directory(p.join(back.path, 'receipts')),
    );

    final restored = AppDatabase(NativeDatabase(dbIn(back)));
    addTearDown(restored.close);
    expect((await restored.select(restored.orders).getSingle()).tipAmount, 9);
    expect((await restored.select(restored.returns).getSingle()).tipAmount, 4);
    expect(
        await restored.ordersDao
            .netTipsForPeriod(DateTime(2020), DateTime(2100)),
        5);
  });
}
