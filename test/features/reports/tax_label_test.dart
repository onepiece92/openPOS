import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/reports/domain/report_data.dart';
import 'package:pos_app/features/reports/presentation/widgets/dashboard_body.dart';

import '../../_support/test_db.dart';
import '../../_support/features.dart';

/// The dashboard names tax the way the shop does ("Sales Tax", "GST",
/// "VAT") and falls back to the generic "Tax" when that is ambiguous.
void main() {
  group('resolveTaxLabel', () {
    String label(List<String> onOrders, List<String> rates) =>
        resolveTaxLabel(namesOnOrders: onOrders, activeRateNames: rates);

    test('one name on the period\'s orders wins', () {
      expect(label(['Sales Tax'], ['Sales Tax', 'City Tax']), 'Sales Tax');
      expect(label([' VAT ', 'VAT'], []), 'VAT');
    });
    test('several names on the orders → Tax', () {
      expect(label(['VAT', 'Service Charge'], ['VAT']), 'Tax');
    });
    test('no taxed orders: the shop\'s single tax rate', () {
      expect(label([], ['GST']), 'GST');
    });
    test('no taxed orders and several or no rates → Tax', () {
      expect(label([], ['GST', 'PST']), 'Tax');
      expect(label([], []), 'Tax');
      expect(label([], ['  ']), 'Tax');
    });
  });

  group('reportProvider', () {
    late AppDatabase db;
    late ProviderContainer c;
    final query = ReportQuery(
        from: DateTime(2026, 1, 1), to: DateTime(2026, 12, 31), label: 'x');

    setUp(() {
      db = openInMemoryDatabase();
      c = ProviderContainer(
          overrides: [allFeaturesOn, databaseProvider.overrideWithValue(db)]);
    });
    tearDown(() async {
      c.dispose();
      await db.close();
    });

    Future<int> rate(String name, {bool active = true}) =>
        db.taxDao.upsertRate(TaxRatesCompanion.insert(
            name: name, rate: 0.1, isActive: Value(active)));

    Future<void> taxedOrder(int rateId, String name,
        {DateTime? at, String status = 'completed'}) async {
      final o = await db.ordersDao.insertOrder(OrdersCompanion.insert(
        subtotal: 100,
        taxTotal: const Value(10),
        total: 110,
        paymentMethod: 'cash',
        status: Value(status),
        createdAt: Value(at ?? DateTime(2026, 6, 1)),
      ));
      await db.ordersDao.insertTaxLines([
        OrderTaxesCompanion.insert(
          orderId: o,
          taxRateId: rateId,
          taxRateName: name,
          taxRatePercent: 0.1,
          taxableAmount: 100,
          taxAmount: 10,
        ),
      ]);
    }

    Future<String> label() async =>
        (await c.read(reportProvider(query).future)).taxLabel;

    test('uses the name on the period\'s orders', () async {
      final r = await rate('Sales Tax');
      await rate('Unused Levy');
      await taxedOrder(r, 'Sales Tax');
      await taxedOrder(r, 'Sales Tax');
      expect(await label(), 'Sales Tax');
    });

    test('two names in the period → Tax; orders outside it do not count',
        () async {
      final a = await rate('VAT');
      final b = await rate('Service Charge');
      await taxedOrder(a, 'VAT');
      await taxedOrder(b, 'Service Charge', at: DateTime(2025, 6, 1));
      expect(await label(), 'VAT');

      await taxedOrder(b, 'Service Charge');
      c.invalidate(reportProvider(query));
      expect(await label(), 'Tax');
    });

    test('voided orders do not decide the name', () async {
      final a = await rate('VAT');
      final b = await rate('Old Tax', active: false);
      await taxedOrder(a, 'VAT');
      await taxedOrder(b, 'Old Tax', status: 'voided');
      expect(await label(), 'VAT');
    });

    test('nothing sold: the single active rate, else Tax', () async {
      expect(await label(), 'Tax');

      await rate('GST');
      await rate('Retired', active: false);
      c.invalidate(reportProvider(query));
      expect(await label(), 'GST');

      await rate('PST');
      c.invalidate(reportProvider(query));
      expect(await label(), 'Tax');
    });
  });

  group('dashboard text', () {
    ReportData data(String? taxLabel) =>
        taxLabel == null ? _report() : _report(taxLabel: taxLabel);

    Future<void> pump(WidgetTester tester, ReportData data) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: DashboardBody(
              data: data,
              symbol: 'Rs',
              cs: Theme.of(context).colorScheme,
              periodLabel: 'Today',
              isCustomRange: false,
            ),
          ),
        ),
      ));
    }

    testWidgets('tiles, top-products note and profit formula use the name',
        (tester) async {
      await pump(tester, data('Sales Tax'));
      expect(find.text('Sales Tax Collected'), findsOneWidget);
      expect(find.text('Revenue (incl. Sales Tax)'), findsOneWidget);
      expect(find.textContaining('sales excl. Sales Tax,'), findsOneWidget);
      expect(find.textContaining('Net profit = sales excl. Sales Tax '),
          findsOneWidget);
      expect(find.textContaining('VAT'), findsNothing);
    });

    testWidgets('a VAT shop reads exactly as before', (tester) async {
      await pump(tester, data('VAT'));
      expect(find.text('VAT Collected'), findsOneWidget);
      expect(find.text('Revenue (incl. VAT)'), findsOneWidget);
    });

    testWidgets('falls back to the generic word', (tester) async {
      await pump(tester, data(null));
      expect(find.text('Tax Collected'), findsOneWidget);
      expect(find.text('Revenue (incl. Tax)'), findsOneWidget);
      expect(find.textContaining('VAT'), findsNothing);
    });
  });
}

ReportData _report({String taxLabel = ReportData.genericTaxLabel}) =>
    ReportData(
      revenue: 113,
      vatCollected: 13,
      costOfGoods: 40,
      soldLines: 1,
      uncostedLines: 0,
      expenses: 10,
      orderCount: 1,
      topProducts: const [
        TopProduct(productId: 1, name: 'Tea', qty: 1, sales: 100),
      ],
      payBreakdown: const [PayRow(method: 'cash', count: 1, total: 113)],
      chartTitle: 'Hourly Sales',
      chartDates: const ['12am', '2am'],
      chartTotals: const [0, 113],
      chartHighlightIndex: 1,
      taxLabel: taxLabel,
    );
