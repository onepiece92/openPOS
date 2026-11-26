import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/returns/domain/process_return.dart';
import 'package:pos_app/features/returns/domain/void_order.dart';

import '../../_support/query_recorder.dart';
import '../../_support/sales.dart';

/// The sell screen's "most sold" ranking: units sold in the last 90 days,
/// in main units, read once per visit to the screen.
void main() {
  late AppDatabase db;
  late QueryRecorder recorder;
  late AuditService audit;
  late int tea, eggs;

  setUp(() async {
    recorder = QueryRecorder();
    db = AppDatabase(NativeDatabase.memory().interceptWith(recorder));
    audit = AuditService(db);
    tea = await seedProduct(db, sku: 'TEA', stock: 0);
    eggs = await seedProduct(db, sku: 'EGGS', stock: 0);
  });
  tearDown(() => db.close());

  Future<void> backdate(int orderId, Duration age) =>
      (db.update(db.orders)..where((o) => o.id.equals(orderId))).write(
          OrdersCompanion(createdAt: Value(DateTime.now().subtract(age))));

  Future<Map<int, int>> counts() => db.ordersDao.productSalesCounts(
      since: DateTime.now().subtract(mostSoldWindow));

  test('the window is 90 days', () {
    expect(mostSoldWindow, const Duration(days: 90));
  });

  test('counts only sales inside the window', () async {
    await sell(db, audit, [line(tea, qty: 3)]);
    final recent = await sell(db, audit, [line(tea, qty: 2)]);
    await backdate(recent, const Duration(days: 89));
    final old = await sell(db, audit, [line(tea, qty: 50), line(eggs, qty: 7)]);
    await backdate(old, const Duration(days: 91));

    expect(await counts(), {tea: 5});
  });

  test('counts main units, not sale units: 2 dozen = 24', () async {
    await sell(db, audit, [
      line(eggs, qty: 2, unitLabel: 'dozen', unitsPerQty: 12),
      line(eggs, qty: 3),
      line(tea, qty: 25),
    ]);
    // By sale units tea (25) would outrank eggs (5); in main units eggs win.
    expect(await counts(), {eggs: 27, tea: 25});
  });

  test('voided and fully refunded sales do not count', () async {
    await sell(db, audit, [line(tea, qty: 1)]);
    final voided = await sell(db, audit, [line(tea, qty: 10)]);
    await voidOrder(db, audit, trackStock: true, orderId: voided, reason: 'test');
    final refunded = await sell(db, audit, [line(eggs, qty: 4)]);
    await processReturn(db, audit, trackStock: true,
        orderId: refunded, amount: 20, restock: false);

    expect(await counts(), {tea: 1});
  });

  group('productSalesCountProvider', () {
    test('is read once: later sales and receipt prints do not re-run it; '
        'reopening the screen takes a fresh reading', () async {
      final p = tea;
      final first = await sell(db, audit, [line(p, qty: 2)]);

      final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)]);
      addTearDown(container.dispose);
      int runs() => recorder.selects
          .where((s) => s.sql.contains('AS total_sold'))
          .length;

      // The sell screen opens and watches the provider.
      final screen =
          container.listen(productSalesCountProvider, (_, __) {});
      expect(await container.read(productSalesCountProvider.future), {p: 2});
      expect(runs(), 1);

      // A sale, then its receipt printing (a write to orders).
      await sell(db, audit, [line(p, qty: 5)]);
      await db.ordersDao.incrementPrintCount(first);
      await pumpEventQueue();
      expect(runs(), 1, reason: 'no re-query while the screen stays open');
      expect(container.read(productSalesCountProvider).value, {p: 2},
          reason: 'the ranking holds still mid-shift');

      // Leaving the sell screen drops the reading…
      screen.close();
      await pumpEventQueue();
      expect(container.exists(productSalesCountProvider), isFalse);

      // …and coming back takes a new one.
      container.listen(productSalesCountProvider, (_, __) {});
      expect(await container.read(productSalesCountProvider.future), {p: 7});
      expect(runs(), 2);
    });
  });
}
