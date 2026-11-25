import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/reports/domain/report_data.dart';
import 'package:pos_app/features/returns/domain/process_return.dart';
import 'package:pos_app/features/returns/domain/void_order.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';
import '../../_support/features.dart';

/// Preset report periods must include sales made a moment ago.
void main() {
  late AppDatabase db;
  late AuditService audit;

  setUp(() {
    db = openInMemoryDatabase();
    audit = AuditService(db);
  });
  tearDown(() => db.close());

  for (final period in ReportPeriod.values) {
    test('${period.label}: a sale made just now is inside the period',
        () async {
      final p = await seedProduct(db, sku: 'A');
      await sell(db, audit, [line(p, qty: 2)]);

      expect(period.to.isBefore(DateTime.now()), isFalse,
          reason: 'the period must reach at least to "now"');
      expect(
          await db.ordersDao.totalRevenueForPeriod(period.from, period.to), 10);
      expect(await db.ordersDao.completedOrdersInPeriod(period.from, period.to),
          hasLength(1));
    });
  }

  test('the period key is stable across calls', () {
    for (final period in ReportPeriod.values) {
      final a = ReportQuery(from: period.from, to: period.to, label: 'x');
      final b = ReportQuery(from: period.from, to: period.to, label: 'x');
      expect(a, b);
    }
  });

  test('report refreshes after a void and after a refund', () async {
    final c = ProviderContainer(
        overrides: [allFeaturesOn, databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    const period = ReportPeriod.today;
    ReportQuery query() =>
        ReportQuery(from: period.from, to: period.to, label: period.label);
    Future<double> revenue() async {
      await pumpEventQueue();
      return (await c.read(reportProvider(query()).future)).revenue;
    }

    final p = await seedProduct(db, sku: 'A');
    final a = await sell(db, audit, [line(p, qty: 2)]);
    final b = await sell(db, audit, [line(p, qty: 4)]);
    final sub = c.listen(reportProvider(query()), (_, __) {});
    addTearDown(sub.close);
    expect(await revenue(), 30);

    await processReturn(db, audit, orderId: b, amount: 5, restock: false);
    expect(await revenue(), 25);

    await voidOrder(db, audit, orderId: a, reason: 't');
    expect(await revenue(), 15);
  });

  test('report picks up a sale placed after it was first loaded', () async {
    final c = ProviderContainer(
        overrides: [allFeaturesOn, databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    const period = ReportPeriod.today;
    ReportQuery query() =>
        ReportQuery(from: period.from, to: period.to, label: period.label);

    final sub = c.listen(reportProvider(query()), (_, __) {});
    addTearDown(sub.close);
    expect((await c.read(reportProvider(query()).future)).revenue, 0);

    final p = await seedProduct(db, sku: 'A');
    await sell(db, audit, [line(p, qty: 2)]);
    await pumpEventQueue();

    final after = await c.read(reportProvider(query()).future);
    expect(after.revenue, 10);
    expect(after.orderCount, 1);
  });
}
