import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/cart/data/place_order.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/reports/domain/report_data.dart';
import 'package:pos_app/features/reports/presentation/widgets/dashboard_body.dart';
import 'package:pos_app/features/returns/domain/process_return.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

void main() {
  late AppDatabase db;
  late AuditService audit;
  late ProviderContainer c;
  late int pid;

  setUp(() async {
    db = openInMemoryDatabase();
    audit = AuditService(db);
    c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    pid = await seedProduct(db, sku: 'T', stock: 100, price: 100);
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });

  Future<ReportData> report() async {
    const p = ReportPeriod.today;
    final q = ReportQuery(from: p.from, to: p.to, label: 'x');
    final d = await loadReport(db, q, ReportSections.all);
    return d;
  }

  /// 100.00 of goods + 13.00 exclusive VAT = 113.00 total, plus [tip].
  Future<int> taxedSale(double tip) async {
    final rate = await db.taxDao.upsertRate(TaxRatesCompanion.insert(
        name: 'VAT', rate: 0.13, inclusionType: const Value('exclusive')));
    return placeOrder(
      db,
      audit,
      cart: [line(pid, price: 100)],
      summary: CartSummary(
        subtotal: 100,
        orderDiscount: 0,
        loyaltyDiscount: 0,
        taxLines: [
          TaxLine(
              taxRateId: rate,
              name: 'VAT',
              rate: 0.13,
              amount: 13,
              isInclusive: false,
              taxableAmount: 100),
        ],
        taxAmount: 13,
        total: 113,
        taxEnabled: true,
        pointsToEarn: 0,
      ),
      session: CartSession(ticketNumber: '#1', openedAt: DateTime(2026, 1, 1)),
      paymentMethod: 'cash',
      tenderedAmount: 113 + tip,
      tipAmount: tip,
    );
  }

  test('Tips figure is net tips; revenue and VAT do not move with it',
      () async {
    final plain = await taxedSale(0);
    final without = await report();
    expect(without.netTips, 0);

    final tipped = await taxedSale(10);
    final withTip = await report();
    expect(withTip.netTips, 10);
    expect(withTip.revenue, without.revenue + 113);
    expect(withTip.vatCollected, without.vatCollected + 13);
    expect(withTip.profit, withTip.salesExVat - withTip.costOfGoods);

    await processReturn(db, audit,
        orderId: tipped,
        amount: 50,
        restock: false,
        trackStock: true,
        refundTip: true);
    expect((await report()).netTips, 0);
    expect(plain, isNot(tipped));
  });

  Future<void> body(WidgetTester tester, ReportData d, {bool show = false}) =>
      tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: DashboardBody(
        data: d,
        symbol: 'Rs',
        cs: const ColorScheme.light(),
        periodLabel: 'Today',
        isCustomRange: false,
        sections: ReportSections(
            costProfit: true, expenses: true, extras: true, tips: show),
      ))));

  ReportData data({double tips = 0}) => ReportData(
        revenue: 0,
        vatCollected: 0,
        costOfGoods: 0,
        soldLines: 0,
        uncostedLines: 0,
        expenses: 0,
        orderCount: 0,
        topProducts: const [],
        payBreakdown: const [],
        chartTitle: '',
        chartDates: const [],
        chartTotals: const [],
        chartHighlightIndex: 0,
        netTips: tips,
      );

  testWidgets('Tips card: hidden when off and nothing tipped', (tester) async {
    await body(tester, data());
    expect(find.text('Tips'), findsNothing);
  });

  testWidgets('Tips card: shown when tips are on', (tester) async {
    await body(tester, data(), show: true);
    expect(find.text('Tips'), findsOneWidget);
    expect(find.text('Rs 0.00'), findsWidgets);
  });

  testWidgets('Tips card: switched off in Features, it is not built',
      (tester) async {
    await body(tester, data(tips: 21.5));
    expect(find.text('Tips'), findsNothing);
  });

  testWidgets('Tips card: on, it shows the net tips', (tester) async {
    await body(tester, data(tips: 21.5), show: true);
    expect(find.text('Rs 21.50'), findsOneWidget);
  });

  test('loadReport skips the tips query when Tips is off', () async {
    await taxedSale(10);
    const off = ReportSections(
        costProfit: true, expenses: true, extras: true, tips: false);
    const p = ReportPeriod.today;
    final q = ReportQuery(from: p.from, to: p.to, label: 'x');
    expect((await loadReport(db, q, off)).netTips, 0);
    expect((await loadReport(db, q, ReportSections.all)).netTips, 10);
  });
}
