import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/payment_screen.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

void main() {
  late Directory tmp;
  late Box<dynamic> heldBox;
  late Box<dynamic> settingsBox;
  late AppDatabase db;
  late int productId;
  late ProviderContainer c;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_tip_');
    Hive.init(tmp.path);
    heldBox = await Hive.openBox<dynamic>('held_orders', bytes: Uint8List(0));
    settingsBox = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
    db = openInMemoryDatabase();
    productId = await seedProduct(db, sku: 'TEA', stock: 0, price: 100);
    c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      settingsBoxProvider.overrideWithValue(settingsBox),
      heldOrdersBoxProvider.overrideWithValue(heldBox),
    ]);
    c.read(cartProvider.notifier).restoreItem(CartItem(
        productId: productId,
        name: 'Tea',
        unitPrice: 100,
        quantity: 1,
        isTaxable: false));
  });

  tearDown(() async {
    c.dispose();
    await db.close();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  Future<void> pumpScreen(WidgetTester tester, {required bool on}) async {
    if (on) {
      await tester.runAsync(
        () => settingsBox.put(kFeaturesKey, {'tips': true}),
      );
    }
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const PaymentScreen()),
      GoRoute(
          path: '/receipt/:id',
          builder: (_, s) => Text('receipt ${s.pathParameters['id']}')),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Finder tendered() =>
      find.widgetWithText(TextField, 'Amount received from customer');
  String tenderedText(WidgetTester tester) =>
      tester.widget<TextField>(tendered()).controller!.text;
  Finder confirm() => find.textContaining('Confirm & Charge');

  Future<Order> theOrder(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.orders).getSingle()))!;

  testWidgets('tips off: no chips are built and the order has tip 0',
      (tester) async {
    await pumpScreen(tester, on: false);
    expect(find.text('No tip'), findsNothing);
    expect(find.text('15%'), findsNothing);
    expect(find.text('Custom'), findsNothing);

    await tester.tap(confirm());
    await settle(tester);
    final o = await theOrder(tester);
    expect(o.tipAmount, 0);
    expect(o.total, 100);
  });

  testWidgets('tips on: chips show, No tip is the default and charges 100',
      (tester) async {
    await pumpScreen(tester, on: true);
    for (final t in ['No tip', '15%', '18%', '20%', 'Custom']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(find.textContaining('Confirm & Charge'), findsOneWidget);
    expect(find.textContaining('115'), findsNothing);
    expect(find.text('Total with tip'), findsNothing);
    await tester.tap(confirm());
    await settle(tester);
    expect((await theOrder(tester)).tipAmount, 0);
  });

  testWidgets('a preset chip: tip, total with tip, tendered and change',
      (tester) async {
    await pumpScreen(tester, on: true);
    await tester.tap(find.text('18%'));
    await tester.pump();
    expect(find.text('Tip'), findsWidgets);
    expect(find.text('Total with tip'), findsOneWidget);
    expect(find.textContaining('118'), findsWidgets);
    expect(find.textContaining('Confirm & Charge'), findsOneWidget);
    expect(tenderedText(tester), '118');

    // Below total + tip is refused, even though it covers the total.
    await tester.enterText(tendered(), '110');
    await tester.pump();
    await tester.tap(confirm());
    await settle(tester);
    expect(find.textContaining('less than the total with tip'), findsOneWidget);
    expect(await tester.runAsync(() => db.select(db.orders).get()), isEmpty);

    await tester.enterText(tendered(), '150');
    await tester.pump();
    expect(find.textContaining('32'), findsWidgets); // change 150 - 118
    await tester.tap(confirm());
    await settle(tester);
    final o = await theOrder(tester);
    expect(o.tipAmount, 18);
    expect(o.total, 100, reason: 'total stays tip-free');
    expect(o.tenderedAmount, 150);
    expect(o.changeAmount, 32);
  });

  testWidgets('custom tip, on card: charged amount is total + tip',
      (tester) async {
    await pumpScreen(tester, on: true);
    await tester.tap(find.text('Card'));
    await tester.pump();
    await tester.tap(find.text('Custom'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Tip amount'), '7.5');
    await tester.pump();
    expect(find.textContaining('Confirm & Charge'), findsOneWidget);
    expect(find.textContaining('107.50'), findsWidgets);
    await tester.tap(confirm());
    await settle(tester);
    final o = await theOrder(tester);
    expect(o.paymentMethod, 'card');
    expect(o.tipAmount, 7.5);
    expect(o.total, 100);
    expect(o.tenderedAmount, isNull);
  });

  testWidgets('tipping and then choosing No tip returns to the plain total',
      (tester) async {
    await pumpScreen(tester, on: true);
    await tester.tap(find.text('20%'));
    await tester.pump();
    expect(tenderedText(tester), '120');
    await tester.tap(find.text('No tip'));
    await tester.pump();
    expect(tenderedText(tester), '100');
    await tester.tap(confirm());
    await settle(tester);
    expect((await theOrder(tester)).tipAmount, 0);
  });

  Future<void> customTip(WidgetTester tester, String v) async {
    await tester.tap(find.text('Custom'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Tip amount'), v);
    await tester.pump();
  }

  testWidgets('a tip bigger than the sale asks first; Change tip charges nothing',
      (tester) async {
    await pumpScreen(tester, on: true);
    await customTip(tester, '150');
    await tester.tap(confirm());
    await tester.pump();
    expect(find.textContaining('Tip is larger than the sale'), findsOneWidget);
    expect(find.textContaining('150.00 on'), findsOneWidget);
    expect(find.textContaining('Keep it?'), findsOneWidget);
    await tester.tap(find.text('Change tip'));
    await settle(tester);
    expect(await tester.runAsync(() => db.select(db.orders).get()), isEmpty);
  });

  testWidgets('Keep tip places the order with that tip', (tester) async {
    await pumpScreen(tester, on: true);
    await customTip(tester, '150');
    await tester.tap(confirm());
    await tester.pump();
    await tester.tap(find.text('Keep tip'));
    await settle(tester);
    expect((await theOrder(tester)).tipAmount, 150);
  });

  testWidgets('a tip up to the sale total asks nothing', (tester) async {
    await pumpScreen(tester, on: true);
    await customTip(tester, '100');
    await tester.tap(confirm());
    await settle(tester);
    expect(find.textContaining('Keep it?'), findsNothing);
    expect((await theOrder(tester)).tipAmount, 100);
  });

  testWidgets('a mistyped tip far past the cap: a plain sentence with the '
      'formatted maximum, no dialog, no order', (tester) async {
    await pumpScreen(tester, on: true);
    await tester.tap(find.text('Card'));
    await tester.pump();
    await customTip(tester, '1500');
    await tester.tap(confirm());
    await settle(tester);
    expect(
        find.textContaining('That tip is too large for this sale. '
            'The most you can add is'),
        findsOneWidget);
    expect(find.textContaining('1,000.00'), findsOneWidget);
    expect(find.textContaining('Order failed'), findsNothing);
    expect(find.textContaining('Invalid argument'), findsNothing);
    expect(find.text('Keep tip'), findsNothing);
    expect(await tester.runAsync(() => db.select(db.orders).get()), isEmpty);
  });

  testWidgets('a zero-total order with a large tip goes through after Keep tip',
      (tester) async {
    await pumpScreen(tester, on: true);
    c.read(cartProvider.notifier).clear();
    c.read(cartProvider.notifier).restoreItem(CartItem(
        productId: productId,
        name: 'Free',
        unitPrice: 0,
        quantity: 1,
        isTaxable: false));
    await tester.pump();
    await tester.tap(find.text('Card'));
    await tester.pump();
    await customTip(tester, '5000');
    await tester.tap(confirm());
    await tester.pump();
    expect(find.textContaining('Keep it?'), findsOneWidget);
    await tester.tap(find.text('Keep tip'));
    await settle(tester);
    final o = await theOrder(tester);
    expect((o.total, o.tipAmount), (0, 5000));
  });

  testWidgets('nothing to tip on: chips are disabled with the reason',
      (tester) async {
    await pumpScreen(tester, on: true);
    c.read(cartProvider.notifier).clear();
    c.read(cartProvider.notifier).restoreItem(CartItem(
        productId: productId,
        name: 'Free',
        unitPrice: 0,
        quantity: 1,
        isTaxable: false));
    await tester.pump();
    expect(find.text('Nothing to tip on: use a custom amount.'),
        findsOneWidget);
    final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '15%'));
    expect(chip.onSelected, isNull);
    // Custom still works.
    await customTip(tester, '5');
    expect(find.textContaining('Total with tip'), findsOneWidget);
  });

  testWidgets('with a base, the reason line is not shown', (tester) async {
    await pumpScreen(tester, on: true);
    expect(find.text('Nothing to tip on: use a custom amount.'), findsNothing);
  });
}
