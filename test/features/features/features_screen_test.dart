import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/cart/data/place_order.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';
import 'package:pos_app/features/cart/domain/cart_calculator.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/features/presentation/features_screen.dart';

import '../../_support/sales.dart';
import '../../_support/temp_hive.dart';
import '../../_support/test_db.dart';

void main() {
  late Box<dynamic> settings;
  setUp(() async =>
      settings = await openTempSettingsBox(more: ['held_orders']));

  ProviderContainer container({AppDatabase? db}) {
    final c = ProviderContainer(overrides: [
      settingsBoxProvider.overrideWithValue(settings),
      heldOrdersBoxProvider.overrideWithValue(Hive.box('held_orders')),
      if (db != null) databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<ProviderContainer> pump(WidgetTester tester,
      {AppDatabase? db}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2600);
    addTearDown(tester.view.reset);
    final c = container(db: db);
    final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, __) => const FeaturesScreen())]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c, child: MaterialApp.router(routerConfig: router)));
    await tester.pump();
    return c;
  }

  Finder row(Feature f) => find.byKey(ValueKey('feature-${f.name}'));
  SwitchListTile tile(WidgetTester t, Feature f) =>
      t.widget<SwitchListTile>(row(f));

  testWidgets('a text list: name, one line, a switch for every feature',
      (tester) async {
    await pump(tester);
    expect(find.text(kFeaturesScreenIntro), findsOneWidget);
    for (final f in Feature.values) {
      expect(row(f), findsOneWidget);
      expect(find.text(f.label), findsOneWidget);
    }
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a child whose parent is off is greyed out: "Needs <Parent>"',
      (tester) async {
    await pump(tester);
    await tester.tap(row(Feature.customers));
    await tester.pump();
    expect(tile(tester, Feature.loyalty).onChanged, isNull);
    expect(find.text('Needs Customers'), findsOneWidget);
    await tester.tap(row(Feature.heldTickets));
    await tester.pump();
    expect(find.text('Needs Held tickets'), findsOneWidget);
  });

  testWidgets('Taxes off asks first; Cancel keeps it on', (tester) async {
    final c = await pump(tester);
    await tester.tap(row(Feature.taxes));
    await tester.pumpAndSettle();
    expect(find.text(kTaxesOffTitle), findsOneWidget);
    expect(find.text(kTaxesOffBody), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(c.read(featureFlagsProvider).taxes, isTrue);

    await tester.tap(row(Feature.taxes));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('taxes-off-confirm')));
    await tester.pumpAndSettle();
    expect(c.read(featureFlagsProvider).taxes, isFalse);

    // Back on: no question.
    await tester.tap(row(Feature.taxes));
    await tester.pumpAndSettle();
    expect(find.text(kTaxesOffTitle), findsNothing);
    expect(c.read(featureFlagsProvider).taxes, isTrue);
  });

  group('confirm before hiding live data', () {
    final item = CartItem(
        productId: 1, name: 'Tea', unitPrice: 1, quantity: 1, isTaxable: false);

    Future<void> turnOff(WidgetTester tester, Feature f) async {
      await tester.tap(row(f));
      await tester.pumpAndSettle();
    }

    testWidgets('Held tickets: "2 saved tickets will be hidden…"; Cancel keeps '
        'it on', (tester) async {
      final c = await pump(tester);
      final held = c.read(heldOrdersProvider.notifier);
      held.hold([item], ticketNumber: '#0001');
      held.hold([item], ticketNumber: '#0002');
      await turnOff(tester, Feature.heldTickets);
      expect(find.text('Turn off Held tickets?'), findsOneWidget);
      expect(
          find.text('2 saved tickets will be hidden until you turn this back '
              'on. Nothing is deleted.'),
          findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(c.read(featureFlagsProvider).heldTickets, isTrue);

      await turnOff(tester, Feature.heldTickets);
      await tester.tap(find.byKey(const ValueKey('feature-off-confirm')));
      await tester.pumpAndSettle();
      expect(c.read(featureFlagsProvider).heldTickets, isFalse);
      expect(c.read(heldOrdersProvider), hasLength(2), reason: 'kept');
    });

    testWidgets('End-of-day close with a day open asks; the day stays open',
        (tester) async {
      final db = openInMemoryDatabase();
      addTearDown(db.close);
      await settings.put(kFeaturesKey, {'endOfDay': true});
      final shift = await db.shiftsDao.openShift(openingCash: 0);
      final c = await pump(tester, db: db);
      await turnOff(tester, Feature.endOfDay);
      expect(find.text('Turn off End-of-day close?'), findsOneWidget);
      expect(find.text(kEndOfDayOpenBody), findsOneWidget);
      expect(kEndOfDayOpenBody,
          'A day is open. It stays open and you can close it after turning '
          'this back on.');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(c.read(featureFlagsProvider).endOfDay, isTrue);

      await turnOff(tester, Feature.endOfDay);
      await tester.tap(find.byKey(const ValueKey('feature-off-confirm')));
      await tester.pumpAndSettle();
      expect(c.read(featureFlagsProvider).endOfDay, isFalse);
      expect((await db.shiftsDao.currentShift())!.id, shift, reason: 'kept');
    });

    testWidgets('End-of-day close with no day open: off at once',
        (tester) async {
      final db = openInMemoryDatabase();
      addTearDown(db.close);
      await settings.put(kFeaturesKey, {'endOfDay': true});
      final c = await pump(tester, db: db);
      await turnOff(tester, Feature.endOfDay);
      expect(find.byType(AlertDialog), findsNothing);
      expect(c.read(featureFlagsProvider).endOfDay, isFalse);
    });

    testWidgets('Held tickets with none parked: off at once', (tester) async {
      final c = await pump(tester);
      await turnOff(tester, Feature.heldTickets);
      expect(find.byType(AlertDialog), findsNothing);
      expect(c.read(featureFlagsProvider).heldTickets, isFalse);
    });

    testWidgets('Tables: asks when a ticket (or the open cart) has a table',
        (tester) async {
      final c = await pump(tester);
      c.read(heldOrdersProvider.notifier)
        ..hold([item], ticketNumber: '#0001', tableId: 4)
        ..hold([item], ticketNumber: '#0002');
      c.read(cartSessionProvider.notifier).setTable(2);
      await turnOff(tester, Feature.tables);
      expect(
          find.text('2 open tickets have a table. Tables will be hidden until '
              'you turn this back on. Nothing is deleted.'),
          findsOneWidget);
    });

    testWidgets('Tables with no table in use: off at once', (tester) async {
      final c = await pump(tester);
      await turnOff(tester, Feature.tables);
      expect(find.byType(AlertDialog), findsNothing);
      expect(c.read(featureFlagsProvider).tables, isFalse);
    });

    testWidgets('Customers: asks when the current sale has a customer',
        (tester) async {
      final c = await pump(tester);
      c.read(cartSessionProvider.notifier).setCustomer(3);
      await turnOff(tester, Feature.customers);
      expect(
          find.text('The customer on the current sale will be hidden until '
              'you turn this back on. It is still saved with the sale.'),
          findsOneWidget);
    });

    test('no confirm for features that hide nothing in use', () {
      for (final f in Feature.values) {
        if (f == Feature.taxes) continue;
        expect(hideConfirmBody(f), isNull, reason: f.name);
      }
    });
  });

  testWidgets('Taxes off keeps the default rate', (tester) async {
    await settings.put('default_tax_id', 7);
    final c = await pump(tester);
    await c.read(settingsProvider.notifier).setFeature(Feature.taxes, false);
    expect(c.read(defaultTaxIdProvider), 7);
  });

  testWidgets(
      'Stock tracking back on shows "Stock wasn\'t tracked from <date>" until '
      'Done', (tester) async {
    final c = await pump(tester);
    await c
        .read(settingsProvider.notifier)
        .setFeature(Feature.stockTracking, false, now: DateTime(2026, 11, 26));
    await tester.pump();
    expect(find.byKey(const ValueKey('stock-recount')), findsNothing,
        reason: 'not while it is off');
    await c
        .read(settingsProvider.notifier)
        .setFeature(Feature.stockTracking, true);
    await tester.pump();
    expect(find.text("Stock wasn't tracked from 26 Nov 2026. Recount your "
        'stock.'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.byKey(const ValueKey('stock-recount')), findsNothing);
    expect(settings.containsKey(kStockOffSince), isFalse);
  });

  test('a second switch-off keeps the first date', () async {
    final c = container();
    final n = c.read(settingsProvider.notifier);
    await n.setFeature(Feature.stockTracking, false, now: DateTime(2026, 1, 2));
    await n.setFeature(Feature.stockTracking, true);
    await n.setFeature(Feature.stockTracking, false, now: DateTime(2026, 3, 4));
    expect(c.read(stockOffSinceProvider), DateTime(2026, 1, 2));
  });

  group('Stock tracking off skips deductions', () {
    late AppDatabase db;
    setUp(() => db = openInMemoryDatabase());
    tearDown(() => db.close());

    Future<int> sell(int productId, {required bool trackStock}) {
      final cart = [line(productId, qty: 3)];
      final session = CartSession.fresh('#1');
      return placeOrder(
        db,
        AuditService(db),
        cart: cart,
        summary: CartCalculator.compute(
            items: cart, session: session, selectedRates: const []),
        session: session,
        paymentMethod: 'card',
        tenderedAmount: 0,
        trackStock: trackStock,
      );
    }

    test('off: stock and the adjustment log are untouched', () async {
      final p = await seedProduct(db, sku: 'A', stock: 10);
      await sell(p, trackStock: false);
      expect((await db.productsDao.getById(p))!.stockQuantity, 10);
      expect(await db.select(db.stockAdjustments).get(), isEmpty);
    });

    test('off: a bundle deducts no components', () async {
      final part = await seedProduct(db, sku: 'P', stock: 10);
      final bundle = await seedProduct(db, sku: 'B', stock: 0, composite: true);
      await db.into(db.productComponents).insert(
          ProductComponentsCompanion.insert(
              compositeProductId: bundle,
              componentProductId: part,
              quantity: const Value(2)));
      await sell(bundle, trackStock: false);
      expect((await db.productsDao.getById(part))!.stockQuantity, 10);
    });

    test('on: deducted as before', () async {
      final p = await seedProduct(db, sku: 'A', stock: 10);
      await sell(p, trackStock: true);
      expect((await db.productsDao.getById(p))!.stockQuantity, 7);
    });
  });
}
