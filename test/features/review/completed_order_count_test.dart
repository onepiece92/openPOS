import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/app_version.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/backup/data/backup_repository.dart';
import 'package:pos_app/features/review/domain/review_policy.dart';
import 'package:pos_app/features/review/review_providers.dart';

import '../../_support/query_recorder.dart';

/// The review reminder's "20 sales" is the number of completed orders in the
/// database, not a counter bumped by the receipt screen.
void main() {
  late AppDatabase db;
  late QueryRecorder recorder;

  setUp(() {
    recorder = QueryRecorder();
    db = AppDatabase(NativeDatabase.memory().interceptWith(recorder));
  });
  tearDown(() => db.close());

  Future<int> order({String status = 'completed', String prefix = ''}) =>
      db.ordersDao.insertOrder(OrdersCompanion.insert(
        subtotal: 10,
        total: 10,
        paymentMethod: 'cash',
        status: Value(status),
        invoicePrefix: Value(prefix),
      ));

  test('counts completed orders only', () async {
    expect(await db.ordersDao.completedOrderCount(upTo: 20), 0);
    await order();
    await order();
    await order(status: 'held');
    await order(status: 'voided');
    await order(status: 'refunded');
    expect(await db.ordersDao.completedOrderCount(upTo: 20), 2);
  });

  test('a partly refunded order still counts; fully refunded does not',
      () async {
    final partly = await order();
    final fully = await order();
    await db.ordersDao.insertReturn(ReturnsCompanion.insert(
        orderId: partly, amount: 4, reason: const Value('damaged')));
    await db.ordersDao.refundOrder(fully);
    expect((await db.ordersDao.getById(partly))!.status, 'completed');
    expect(await db.ordersDao.completedOrderCount(upTo: 20), 1);
  });

  test('imported orders count like any other completed order', () async {
    await order(prefix: BackupRepository.importedOrderPrefix);
    await order();
    expect(await db.ordersDao.completedOrderCount(upTo: 20), 2);
  });

  test('stops counting at the limit, and the scan is bounded by LIMIT',
      () async {
    for (var i = 0; i < 30; i++) {
      await order();
    }
    recorder.selects.clear();
    expect(await db.ordersDao.completedOrderCount(upTo: 20), 20);
    expect(await db.ordersDao.completedOrderCount(upTo: 100), 30);

    final q = recorder.selects.first;
    expect(q.sql, contains('LIMIT ?'));
    final plan = await db.customSelect(
      'EXPLAIN QUERY PLAN ${q.sql}',
      variables: [for (final a in q.args) Variable(a)],
    ).get();
    final steps = [for (final r in plan) r.read<String>('detail')];
    // No index covers status: the plan is a rowid walk of orders inside
    // the LIMITed subquery, which ends at the 20th match.
    expect(steps.join(' | '), contains('SCAN orders'));
    // ignore: avoid_print
    print('completedOrderCount plan: ${steps.join(' | ')}');
  });

  test('the provider wires the database count and the full app version',
      () async {
    final tmp = await Directory.systemTemp.createTemp('pos_review_wire_');
    Hive.init(tmp.path);
    final box = await Hive.openBox<dynamic>('settings');
    addTearDown(() async {
      await Hive.close();
      await tmp.delete(recursive: true);
    });
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      settingsBoxProvider.overrideWithValue(box),
    ]);
    addTearDown(container.dispose);

    final c = container.read(reviewControllerProvider);
    final pubspecVersion = File('pubspec.yaml')
        .readAsLinesSync()
        .singleWhere((l) => l.startsWith('version:'))
        .substring('version:'.length)
        .trim();
    expect(c.appVersion, kAppVersionFull);
    expect(c.appVersion, pubspecVersion);

    for (var i = 0; i < kReviewMinCompletedSales + 5; i++) {
      await order();
    }
    await order(status: 'voided');
    expect(await c.completedSales(), kReviewMinCompletedSales,
        reason: 'counted from orders, capped at the threshold');
  });
}
