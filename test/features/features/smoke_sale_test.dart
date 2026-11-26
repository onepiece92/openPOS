import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/app.dart' show routerProvider;
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/payment_screen.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';
import 'package:pos_app/features/customers/domain/customers_provider.dart';
import 'package:pos_app/features/printing/domain/auto_print.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

import '../../_support/sales.dart';
import '../../_support/temp_hive.dart';
import '../../_support/test_db.dart';

/// One whole sale through the real providers and the real payment screen,
/// with every optional feature off, and with every one on.
void main() {
  late Box<dynamic> settings;
  late AppDatabase db;

  setUp(() async {
    settings = await openTempSettingsBox(more: ['held_orders']);
    db = openInMemoryDatabase();
    addTearDown(db.close);
  });

  ProviderContainer container(FeatureFlags flags) {
    settings
      ..put('onboarding_complete', true)
      ..put(kFeaturesKey, flags.toStored())
      ..put(kLoyaltyEnabled, flags.stored(Feature.loyalty))
      ..put(kFeaturesIntroSeen, true);
    final c = ProviderContainer(overrides: [
      settingsBoxProvider.overrideWithValue(settings),
      heldOrdersBoxProvider.overrideWithValue(Hive.box('held_orders')),
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<Order> sell(WidgetTester tester, ProviderContainer c,
      {required int productId}) async {
    c.read(cartProvider.notifier).restoreItem(CartItem(
        productId: productId,
        name: 'TEA',
        unitPrice: 10,
        quantity: 2,
        isTaxable: true));
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const PaymentScreen()),
      GoRoute(path: '/receipt/:id', builder: (_, __) => const Text('receipt')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c, child: MaterialApp.router(routerConfig: router)));
    await settle(tester);
    await tester.tap(find.textContaining('Confirm & Charge'));
    await settle(tester);
    expect(find.text('receipt'), findsOneWidget);
    final orders = await tester.runAsync(() => db.select(db.orders).get());
    return orders!.single;
  }

  Future<int> setUpShop(WidgetTester tester) async =>
      (await tester.runAsync(() async {
        final rate = await db.taxDao.upsertRate(TaxRatesCompanion.insert(
            name: 'Tax', rate: 0.1, inclusionType: const Value('exclusive')));
        await settings.put('default_tax_id', rate);
        return seedProduct(db, sku: 'TEA', stock: 10, price: 10);
      }))!;

  testWidgets('everything off: a plain sale — no tax, stock untouched',
      (tester) async {
    final productId = await setUpShop(tester);
    final c = container(FeatureFlags.only(const {}));
    final order = await sell(tester, c, productId: productId);
    expect(order.total, 20);
    expect(order.taxTotal, 0);
    final product =
        await tester.runAsync(() => db.productsDao.getById(productId));
    expect(product!.stockQuantity, 10);
    expect(await tester.runAsync(() => db.select(db.stockAdjustments).get()),
        isEmpty);
    // Nothing optional was started.
    expect(c.exists(customersStreamProvider), isFalse);
    expect(c.exists(cartCustomerProvider), isFalse);
    expect(c.exists(taxRatesStreamProvider), isFalse);
    expect(c.exists(autoPrintServiceProvider), isFalse);
    expect(c.exists(heldOrdersProvider), isFalse);
  });

  testWidgets('everything on: tax added and stock deducted', (tester) async {
    final productId = await setUpShop(tester);
    final c = container(FeatureFlags.only(Feature.values.toSet()));
    final order = await sell(tester, c, productId: productId);
    expect(order.taxTotal, 2);
    expect(order.total, 22);
    final product =
        await tester.runAsync(() => db.productsDao.getById(productId));
    expect(product!.stockQuantity, 8);
    final log =
        await tester.runAsync(() => db.select(db.stockAdjustments).get());
    expect(log!.single.delta, -2);
    expect(c.exists(autoPrintServiceProvider), isTrue);
    expect(c.exists(taxRatesStreamProvider), isTrue);
  });

  testWidgets(
      "the app router's own listener sends an open screen to /pos when its "
      'feature is switched off', (tester) async {
    final c = container(FeatureFlags.only(Feature.values.toSet()));
    final router = c.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c, child: MaterialApp.router(routerConfig: router)));
    await settle(tester);
    router.go('/expenses');
    await settle(tester);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/expenses');

    // No manual refresh: routerProvider's ref.listen(featureFlagsProvider)
    // pings the router.
    await c.read(settingsProvider.notifier).setFeature(Feature.expenses, false);
    await settle(tester);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/pos');
  });
}
