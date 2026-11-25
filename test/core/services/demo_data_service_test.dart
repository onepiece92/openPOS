import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/services/demo_data_service.dart';

import '../../_support/query_recorder.dart';

/// Seeding the demo shop is one database transaction: one commit, and all
/// or nothing.
void main() {
  late Directory tmp;
  late AppDatabase db;
  late QueryRecorder recorder;
  late ProviderContainer container;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_demo_');
    Hive.init(tmp.path);
    final box = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
    recorder = QueryRecorder();
    db = AppDatabase(NativeDatabase.memory().interceptWith(recorder));
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      settingsBoxProvider.overrideWithValue(box),
    ]);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  Future<int> count(String table) => db
      .customSelect('SELECT COUNT(*) AS c FROM $table')
      .map((r) => r.read<int>('c'))
      .getSingle();

  test('seeds everything inside a single transaction', () async {
    await db.customSelect('SELECT 1').get(); // open + create first
    recorder.transactionsBegun = 0;

    await container.read(demoDataServiceProvider).seed();

    expect(recorder.transactionsBegun, 1);
    expect(await count('products'), greaterThan(20));
    expect(await count('orders'), greaterThan(0));
    expect(await count('order_items'), greaterThan(0));
  });

  test('a failure part-way leaves nothing behind', () async {
    // A product already holding one of the demo SKUs makes the seed fail
    // once it reaches that row (SKUs are unique).
    await db.productsDao.upsert(
        ProductsCompanion.insert(sku: 'TAR011', name: 'Mine', price: 1));

    await expectLater(
        container.read(demoDataServiceProvider).seed(), throwsA(anything));

    expect(await count('categories'), 0);
    expect(await count('products'), 1);
    expect(await count('orders'), 0);
  });
}
