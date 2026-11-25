import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/backup/presentation/backup_screen.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/cart/presentation/home.dart';
import 'package:pos_app/features/cart/presentation/payment_screen.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';
import 'package:pos_app/features/cart/presentation/widgets/grid_product_tile.dart';
import 'package:pos_app/features/cart/presentation/widgets/order_summary.dart';
import 'package:pos_app/features/cart/presentation/widgets/ticket_header.dart';
import 'package:pos_app/features/customers/domain/customers_provider.dart';
import 'package:pos_app/features/printing/domain/auto_print.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/products/presentation/product_form_screen.dart';
import 'package:pos_app/features/receipts/presentation/receipt_screen.dart';
import 'package:pos_app/features/reports/presentation/widgets/dashboard_body.dart';
import 'package:pos_app/features/reports/presentation/widgets/mini_bar_chart.dart';
import 'package:pos_app/features/reports/domain/report_data.dart';
import 'package:pos_app/features/review/review_providers.dart';
import 'package:pos_app/features/settings/presentation/widgets/tax_section.dart';
import 'package:pos_app/features/tables/domain/tables_provider.dart';

import '../../_support/sales.dart';
import '../../_support/temp_hive.dart';
import '../../_support/test_db.dart';

/// For every switch: with the feature off its widget is not built and the
/// provider behind it is never read (each gated provider is replaced by one
/// that counts its reads); with it on, both happen.
void main() {
  late Box<dynamic> settings;
  late AppDatabase db;
  late Map<String, int> reads;

  setUp(() async {
    settings = await openTempSettingsBox(more: ['held_orders']);
    db = openInMemoryDatabase();
    addTearDown(db.close);
    reads = {};
  });

  /// Counts reads of [name] and returns [value].
  T counted<T>(String name, T value) {
    reads[name] = (reads[name] ?? 0) + 1;
    return value;
  }

  ProviderContainer container(Set<Feature> on,
      {List<Override> extra = const []}) {
    settings
      ..put(kFeaturesKey, FeatureFlags.only(on).toStored())
      ..put(kLoyaltyEnabled, on.contains(Feature.loyalty))
      ..put(kFeaturesIntroSeen, true);
    final c = ProviderContainer(overrides: [
      settingsBoxProvider.overrideWithValue(settings),
      heldOrdersBoxProvider.overrideWithValue(Hive.box('held_orders')),
      databaseProvider.overrideWithValue(db),
      customersStreamProvider.overrideWith(
          (ref) => counted('customers', const Stream<List<Customer>>.empty())),
      tablesStreamProvider.overrideWith(
          (ref) => counted('tables', const Stream<List<PosTable>>.empty())),
      taxRatesStreamProvider.overrideWith(
          (ref) => counted('taxRates', const Stream<List<TaxRate>>.empty())),
      cartCustomerProvider.overrideWith((ref) => counted('cartCustomer', null)),
      activeHeldOrdersProvider
          .overrideWith((ref) => counted('held', const <HeldOrder>[])),
      ...extra,
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<void> pump(WidgetTester tester, ProviderContainer c, Widget w) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 2400);
    addTearDown(tester.view.reset);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => Scaffold(body: w)),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c, child: MaterialApp.router(routerConfig: router)));
    await tester.pump();
  }

  final all = Feature.values.toSet();
  Set<Feature> without(Feature f) => all.difference({f});
  final session = CartSession.fresh('#0001');
  void addLine(ProviderContainer c) => c.read(cartProvider.notifier).restoreItem(
      CartItem(
          productId: 1,
          name: 'Tea',
          unitPrice: 10,
          quantity: 1,
          isTaxable: true));

  group('Customers', () {
    testWidgets('off: no customer row, the customer list is never read',
        (tester) async {
      await pump(tester, container(without(Feature.customers)),
          TicketHeader(session: session));
      expect(find.text('Select customer (optional)'), findsNothing);
      expect(reads['customers'], isNull);
    });
    testWidgets('on: the row is built and watches the list', (tester) async {
      await pump(tester, container(all), TicketHeader(session: session));
      expect(find.text('Select customer (optional)'), findsOneWidget);
      expect(reads['customers'], 1);
    });
    testWidgets('off: no customer button on the checkout bar, no menu item',
        (tester) async {
      final c = container(without(Feature.customers));
      addLine(c);
      await pump(tester, c, const PosBottomBars());
      expect(find.byKey(const ValueKey('checkout-customer')), findsNothing);
      expect(find.byKey(const ValueKey('checkout-save')), findsOneWidget);
    });
  });

  group('Tables (needs Held tickets)', () {
    for (final off in [Feature.tables, Feature.heldTickets]) {
      testWidgets('${off.name} off: no table row; tables never read',
          (tester) async {
        final c = container(without(off));
        addLine(c);
        await pump(tester, c,
            Column(children: [TicketHeader(session: session),
              const PosBottomBars()]));
        expect(find.textContaining('table'), findsNothing);
        expect(find.byKey(const ValueKey('checkout-table')), findsNothing);
        expect(reads['tables'], isNull);
      });
    }
    testWidgets('on: the row watches the tables', (tester) async {
      await pump(tester, container(all), TicketHeader(session: session));
      expect(reads['tables'], 1);
    });
  });

  group('Held tickets', () {
    testWidgets('off: no held-tickets bar (never read) and no Save',
        (tester) async {
      final c = container(without(Feature.heldTickets));
      addLine(c);
      await pump(tester, c, const PosBottomBars());
      expect(find.byKey(const ValueKey('checkout-save')), findsNothing);
      expect(reads['held'], isNull);
    });
    testWidgets('on: the bar watches the held tickets', (tester) async {
      final c = container(all);
      addLine(c);
      await pump(tester, c, const PosBottomBars());
      expect(find.byKey(const ValueKey('checkout-save')), findsOneWidget);
      expect(reads['held'], isNotNull);
    });
  });

  group('Discounts and Taxes on the cart', () {
    final fmt = CurrencyFormatter(symbol: r'$ ', locale: 'en_US');
    Widget summary(ProviderContainer c) =>
        OrderSummary(summary: c.read(cartSummaryProvider), fmt: fmt);

    testWidgets('Discounts off: no "+ Add Discount"', (tester) async {
      final c = container(without(Feature.discounts));
      await pump(tester, c, summary(c));
      expect(find.text('+ Add Discount'), findsNothing);
      expect(find.text('+ Add Tax'), findsOneWidget);
    });
    testWidgets('Discounts off: a discount already on the ticket still shows',
        (tester) async {
      final c = container(without(Feature.discounts));
      addLine(c);
      c.read(cartSessionProvider.notifier).setOrderDiscount(1, isPercent: false);
      await pump(tester, c, summary(c));
      expect(find.byKey(const ValueKey('summary-discount')), findsOneWidget);
    });
    testWidgets('Taxes off: no tax picker, and the tax rates are never read',
        (tester) async {
      final c = container(without(Feature.taxes));
      addLine(c);
      await pump(tester, c, summary(c));
      expect(find.text('+ Add Tax'), findsNothing);
      expect(reads['taxRates'], isNull);
      expect(c.read(cartSummaryProvider).taxLines, isEmpty);
    });
    testWidgets('Taxes on: the summary watches the tax rates', (tester) async {
      final c = container(all);
      await pump(tester, c, summary(c));
      expect(reads['taxRates'], 1);
    });
    testWidgets('Taxes off: Settings has no default-rate row (rates unread)',
        (tester) async {
      await pump(tester, container(without(Feature.taxes)),
          const TaxSection());
      expect(find.text('Default Tax Rate'), findsNothing);
      expect(find.text('Invoice Prefix'), findsOneWidget);
      expect(reads['taxRates'], isNull);
    });
  });

  group('Loyalty (needs Customers) and Auto-print on Payment', () {
    for (final off in [Feature.loyalty, Feature.customers]) {
      test('${off.name} off: the cart total never reads the customer', () {
        final c = container(without(off));
        addLine(c);
        c.read(cartSummaryProvider);
        expect(reads['cartCustomer'], isNull);
        expect(reads['customers'], isNull);
      });
    }
    test('on: the cart total reads the customer', () {
      final c = container(all);
      c.read(cartSummaryProvider);
      expect(reads['cartCustomer'], 1);
    });

    testWidgets('off: payment screen never looks the customer up',
        (tester) async {
      final c = container(without(Feature.loyalty));
      addLine(c);
      await pump(tester, c, const PaymentScreen());
      expect(find.text('Loyalty Points'), findsNothing);
      expect(reads['cartCustomer'], isNull);
    });

    testWidgets('Auto-print off: paying never reads the print service',
        (tester) async {
      final productId = await tester.runAsync(
          () => seedProduct(db, sku: 'TEA', stock: 0, price: 10));
      final c = container(without(Feature.autoPrint), extra: [
        autoPrintServiceProvider.overrideWith((ref) =>
            counted('autoPrint', AutoPrintService(ref))),
      ]);
      c.read(cartProvider.notifier).restoreItem(CartItem(
          productId: productId!,
          name: 'Tea',
          unitPrice: 10,
          quantity: 1,
          isTaxable: false));
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const PaymentScreen()),
        GoRoute(path: '/receipt/:id', builder: (_, __) => const Text('rcpt')),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: c, child: MaterialApp.router(routerConfig: router)));
      await tester.pump();
      await tester.tap(find.textContaining('Confirm & Charge'));
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('rcpt'), findsOneWidget);
      expect(reads['autoPrint'], isNull);
    });
  });

  group('Stock tracking, Units on the sell tile', () {
    Product product({int stock = -1, String? secondary}) => Product(
          id: 1,
          name: 'Eggs',
          sku: 'EGG',
          price: 1,
          purchasePrice: 0,
          unit: 'pcs',
          secondaryUnit: secondary,
          conversionRate: secondary == null ? 1 : 12,
          stockQuantity: stock,
          isOutOfStock: false,
          isTaxable: true,
          isComposite: false,
          isHiddenInPos: false,
          isActive: true,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );

    testWidgets('Stock off: an over-sold product is not "Out of stock"',
        (tester) async {
      await pump(tester, container(without(Feature.stockTracking)),
          SizedBox(width: 160, height: 160,
              child: GridProductTile(product: product())));
      expect(find.text('Out of stock'), findsNothing);
    });
    testWidgets('Stock on: it is', (tester) async {
      await pump(tester, container(all),
          SizedBox(width: 160, height: 160,
              child: GridProductTile(product: product())));
      expect(find.text('Out of stock'), findsOneWidget);
    });
    testWidgets('Units off: no second-unit picker on long-press',
        (tester) async {
      await pump(tester, container(without(Feature.units)),
          SizedBox(width: 160, height: 160,
              child: GridProductTile(
                  product: product(stock: 0, secondary: 'dozen'))));
      await tester.longPress(find.text('Eggs'));
      await tester.pumpAndSettle();
      expect(find.textContaining('dozen'), findsNothing);
    });
  });

  group('Product form', () {
    for (final (f, key) in [
      (Feature.costProfit, 'product-purchase-price'),
      (Feature.taxes, 'product-apply-tax'),
      (Feature.units, 'product-secondary-unit'),
      (Feature.stockTracking, 'product-inventory'),
      (Feature.bundles, 'product-bundle'),
    ]) {
      testWidgets('${f.name} off: its fields are not built', (tester) async {
        await pump(tester, container(without(f)), const ProductFormScreen());
        expect(find.byKey(ValueKey(key)), findsNothing);
        await pump(tester, container(all), const ProductFormScreen());
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      });
    }
    testWidgets('Bundles need Stock tracking', (tester) async {
      await pump(tester,
          container(without(Feature.stockTracking)), const ProductFormScreen());
      expect(find.byKey(const ValueKey('product-bundle')), findsNothing);
    });
  });

  group('Reports', () {
    const data = ReportData(
      revenue: 100,
      vatCollected: 10,
      costOfGoods: 40,
      soldLines: 2,
      uncostedLines: 1,
      expenses: 5,
      orderCount: 2,
      topProducts: [TopProduct(productId: 1, name: 'Tea', qty: 2, sales: 90)],
      payBreakdown: [PayRow(method: 'cash', count: 2, total: 100)],
      chartTitle: 'Hourly Sales',
      chartDates: ['8am'],
      chartTotals: [100],
      chartHighlightIndex: 0,
    );
    Widget body(ReportSections s) => Builder(
        builder: (ctx) => DashboardBody(
            data: data,
            symbol: r'$',
            cs: Theme.of(ctx).colorScheme,
            periodLabel: 'Today',
            isCustomRange: false,
            sections: s));

    testWidgets('everything on: all parts, the chart included', (tester) async {
      await pump(tester, container(all), body(ReportSections.all));
      expect(find.byType(MiniBarChart), findsOneWidget);
      expect(find.text('Cost of Goods'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Net Profit'), findsOneWidget);
      expect(find.text('TOP PRODUCTS'), findsOneWidget);
    });
    testWidgets('Cost and profit off', (tester) async {
      await pump(tester, container(all),
          body(const ReportSections(costProfit: false, expenses: true,
              extras: true)));
      expect(find.text('Cost of Goods'), findsNothing);
      expect(find.text('Net Profit'), findsNothing);
      expect(find.textContaining('no purchase price'), findsNothing);
      expect(find.text('Expenses'), findsOneWidget);
    });
    testWidgets('Expenses off', (tester) async {
      await pump(tester, container(all),
          body(const ReportSections(costProfit: true, expenses: false,
              extras: true)));
      expect(find.text('Expenses'), findsNothing);
      expect(find.textContaining('− cost of goods.'), findsOneWidget);
    });
    testWidgets('Dashboard extras off: no chart, payment mix or top products',
        (tester) async {
      await pump(tester, container(all),
          body(const ReportSections(costProfit: true, expenses: true,
              extras: false)));
      expect(find.byType(MiniBarChart), findsNothing);
      expect(find.text('Cash'), findsNothing);
      expect(find.text('TOP PRODUCTS'), findsNothing);
      expect(find.text('Orders'), findsOneWidget);
    });
    test('the sections follow the switches', () {
      final c = container(all.difference(
          {Feature.costProfit, Feature.dashboardExtras}));
      expect(c.read(reportSectionsProvider),
          const ReportSections(costProfit: false, expenses: true,
              extras: false));
    });
  });

  group('CSV import and export', () {
    testWidgets('off: no CSV rows; the full backup stays', (tester) async {
      await pump(tester, container(without(Feature.csvImportExport)),
          const BackupScreen());
      expect(find.text('Back up everything'), findsWidgets);
      expect(find.text('Export Products'), findsNothing);
      expect(find.text('Export Order History'), findsNothing);
    });
    testWidgets('customer and expense rows follow those features',
        (tester) async {
      await pump(
          tester,
          container(all.difference({Feature.customers, Feature.expenses})),
          const BackupScreen());
      expect(find.text('Export Products'), findsOneWidget);
      expect(find.text('Export Customers'), findsNothing);
      expect(find.text('Export Expenses'), findsNothing);
    });
  });

  group('Review reminder', () {
    testWidgets('off: the receipt never creates the review controller',
        (tester) async {
      final orderId = await tester.runAsync(() => db.ordersDao.insertOrder(
          OrdersCompanion.insert(
              subtotal: 1, total: 1, paymentMethod: 'cash')));
      final c = container(without(Feature.reviewReminder), extra: [
        reviewControllerProvider.overrideWith(
            (ref) => throw StateError('review controller read')),
      ]);
      await pump(tester, c, ReceiptScreen(orderId: orderId!));
      await tester.pumpWidget(const SizedBox()); // dispose: no check
      expect(tester.takeException(), isNull);
    });
  });
}
