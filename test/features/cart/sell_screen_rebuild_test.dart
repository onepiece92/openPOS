import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/theme/tron_border.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/pos_catalog_provider.dart';
import 'package:pos_app/features/cart/domain/pos_filter_provider.dart';
import 'package:pos_app/features/cart/presentation/home.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';
import 'package:pos_app/features/cart/presentation/widgets/checkout_bar.dart';
import 'package:pos_app/features/cart/presentation/widgets/grid_product_tile.dart';
import 'package:pos_app/features/cart/presentation/widgets/held_tickets_bar.dart';
import 'package:pos_app/features/cart/presentation/widgets/product_tile.dart';
import 'package:pos_app/features/products/domain/favorites_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

import '../../_support/fake_products.dart';

/// What a tap on the sell screen costs, measured in rebuilt widgets.
///
/// No device profiling here: these tests pin the *shape* of the work — which
/// widgets rebuild and whether the catalogue is re-filtered — not its
/// duration.
void main() {
  late Directory tmp;
  late Box<dynamic> heldBox;
  late Box<dynamic> settingsBox;
  late ProviderContainer c;

  const catalogSize = 300;

  // Item 000 … Item 299, handed over in reverse and unmodifiable, so any
  // in-place sort of the provider's list throws.
  List<Product> catalog() => List.unmodifiable([
        for (var i = catalogSize - 1; i >= 0; i--)
          fakeProduct(
            id: i + 1,
            name: 'Item ${i.toString().padLeft(3, '0')}',
            categoryId: i.isEven ? 1 : 2,
            // Item 005: tracked, 2 left. Item 006: 13 left, sold by the dozen.
            stock: i == 5 ? 2 : (i == 6 ? 13 : 0),
            secondaryUnit: i == 6 ? 'dozen' : null,
            conversionRate: i == 6 ? 12 : 1,
            outOfStock: i == 7,
          ),
      ]);

  Category category(int id, String name) => Category(
        id: id,
        name: name,
        sortOrder: id,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_sell_');
    Hive.init(tmp.path);
    heldBox = await Hive.openBox<dynamic>('held_orders', bytes: Uint8List(0));
    settingsBox = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
    final products = catalog();
    c = ProviderContainer(overrides: [
      settingsBoxProvider.overrideWithValue(settingsBox),
      heldOrdersBoxProvider.overrideWithValue(heldBox),
      productsStreamProvider.overrideWith((ref) => Stream.value(products)),
      categoriesStreamProvider.overrideWith(
          (ref) => Stream.value([category(1, 'Even'), category(2, 'Odd')])),
      productSalesCountProvider.overrideWith((ref) async => <int, int>{}),
    ]);
  });

  tearDown(() async {
    debugOnRebuildDirtyWidget = null;
    c.dispose();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  Future<void> pumpSellScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: CartScreen()),
    ));
    await tester.pumpAndSettle();
  }

  /// Runs [action] and returns the widget of every element rebuilt by it.
  Future<List<Widget>> rebuiltDuring(
    WidgetTester tester,
    Future<void> Function() action,
  ) async {
    final rebuilt = <Widget>[];
    debugOnRebuildDirtyWidget = (e, _) => rebuilt.add(e.widget);
    try {
      await action();
      await tester.pump();
    } finally {
      debugOnRebuildDirtyWidget = null;
    }
    return rebuilt;
  }

  int qtyOf(int productId, {String unit = ''}) => c
      .read(cartProvider)
      .where((i) => i.productId == productId && i.unitLabel == unit)
      .fold(0, (s, i) => s + i.quantity);

  PosCatalogView view() => c.read(posCatalogProvider).requireValue;

  testWidgets('grid: a tap rebuilds the tapped tile and the checkout bar only',
      (tester) async {
    await pumpSellScreen(tester);
    final tilesShown = tester.widgetList(find.byType(GridProductTile)).length;
    expect(tilesShown, greaterThan(20));
    final listBefore = view();

    // First tap: adds the product (empty cart → one line).
    var rebuilt = await rebuiltDuring(
        tester, () => tester.tap(find.text('Item 003')));
    expect(qtyOf(4), 1);
    expect(
      [for (final w in rebuilt.whereType<GridProductTile>()) w.product.name],
      ['Item 003'],
      reason: 'only the tapped tile may rebuild',
    );
    expect(rebuilt.whereType<CheckoutBar>(), hasLength(1));
    expect(rebuilt.whereType<CartScreen>(), isEmpty);
    expect(rebuilt.whereType<Scaffold>(), isEmpty);
    expect(rebuilt.whereType<AppBar>(), isEmpty);
    expect(rebuilt.whereType<TextField>(), isEmpty);
    expect(rebuilt.whereType<FilterChip>(), isEmpty);
    expect(rebuilt.whereType<GridView>(), isEmpty);
    expect(identical(view(), listBefore), isTrue,
        reason: 'a cart change must not re-run the filter/sort');

    // Second tap on the same tile: the stepper path (1 → 2).
    rebuilt = await rebuiltDuring(
        tester, () => tester.tap(find.text('Item 003')));
    expect(qtyOf(4), 2);
    expect(
      [for (final w in rebuilt.whereType<GridProductTile>()) w.product.name],
      ['Item 003'],
    );
    expect(rebuilt.whereType<CartScreen>(), isEmpty);
    expect(rebuilt.whereType<GridView>(), isEmpty);
    expect(rebuilt.whereType<FilterChip>(), isEmpty);

    // A different product while the cart already has a line.
    rebuilt = await rebuiltDuring(
        tester, () => tester.tap(find.text('Item 010')));
    expect(qtyOf(11), 1);
    expect(
      [for (final w in rebuilt.whereType<GridProductTile>()) w.product.name],
      ['Item 010'],
    );
    expect(rebuilt.whereType<CartScreen>(), isEmpty);
    expect(identical(view(), listBefore), isTrue);

    // Let the tile highlight animations finish.
    await tester.pumpAndSettle();
  });

  testWidgets('list: a tap rebuilds the tapped row only', (tester) async {
    c.read(posFilterProvider.notifier).toggleView();
    await pumpSellScreen(tester);
    expect(tester.widgetList(find.byType(PosProductTile)).length,
        greaterThan(8));
    final listBefore = view();

    var rebuilt = await rebuiltDuring(
        tester, () => tester.tap(find.text('Item 003')));
    expect(qtyOf(4), 1);
    expect(
      [for (final w in rebuilt.whereType<PosProductTile>()) w.product.name],
      ['Item 003'],
    );
    expect(rebuilt.whereType<CartScreen>(), isEmpty);
    expect(rebuilt.whereType<ListView>(), isEmpty);
    expect(rebuilt.whereType<FilterChip>(), isEmpty);
    expect(identical(view(), listBefore), isTrue);

    rebuilt = await rebuiltDuring(
        tester, () => tester.tap(find.text('Item 003')));
    expect(qtyOf(4), 2);
    expect(
      [for (final w in rebuilt.whereType<PosProductTile>()) w.product.name],
      ['Item 003'],
    );
    await tester.pumpAndSettle();
  });

  testWidgets('the filter/sort runs for search and category, not for the cart',
      (tester) async {
    await pumpSellScreen(tester);
    final initial = view();
    expect(initial.products, hasLength(catalogSize));
    expect(initial.products.first.name, 'Item 000');

    // Cart changes of every kind: same list object, so no re-run.
    final cart = c.read(cartProvider.notifier);
    cart.addProduct(initial.products[0]);
    cart.setQuantity(initial.products[0].id, 3);
    cart.addProduct(initial.products[1]);
    cart.remove(initial.products[1].id);
    await tester.pump();
    expect(identical(view(), initial), isTrue);

    // Grid/list toggle is not a filter input either.
    c.read(posFilterProvider.notifier).toggleView();
    await tester.pump();
    expect(identical(view(), initial), isTrue);
    c.read(posFilterProvider.notifier).toggleView();
    await tester.pump();

    // Starring a product only matters while "favourites only" is on.
    await c.read(favoritesProvider.notifier).toggle(1);
    await tester.pump();
    expect(identical(view(), initial), isTrue);

    // Typing in the search field re-filters.
    await tester.enterText(find.byType(TextField), 'item 01');
    await tester.pump();
    final searched = view();
    expect(identical(searched, initial), isFalse);
    expect([for (final p in searched.products) p.name],
        [for (var i = 10; i < 20; i++) 'Item 0$i']);
    expect(find.byType(GridProductTile), findsNWidgets(10));

    // …and a cart change still does not.
    cart.addProduct(searched.products.first);
    await tester.pump();
    expect(identical(view(), searched), isTrue);

    // Picking a category re-filters.
    await tester.tap(find.widgetWithText(FilterChip, 'Odd'));
    await tester.pump();
    final byCategory = view();
    expect(identical(byCategory, searched), isFalse);
    expect([for (final p in byCategory.products) p.name],
        ['Item 011', 'Item 013', 'Item 015', 'Item 017', 'Item 019']);

    // So does a new sort order.
    c.read(posFilterProvider.notifier).setSortMode(PosSortMode.nameZA);
    await tester.pump();
    expect(view().products.first.name, 'Item 019');
    await tester.pumpAndSettle();
  });

  testWidgets('stock cap through the tiles is unchanged', (tester) async {
    await pumpSellScreen(tester);

    // Item 005 (id 6): 2 in stock. Third tap is refused with the message.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Item 005'));
      await tester.pump();
    }
    expect(qtyOf(6), 2);
    expect(find.byType(SnackBar), findsNothing);
    await tester.tap(find.text('Item 005'));
    await tester.pump();
    expect(qtyOf(6), 2);
    expect(find.text('Only 2 in stock for Item 005'), findsOneWidget);

    // Item 006 (id 7): 13 in stock, a dozen already in the cart → room for
    // exactly one more piece; secondary-unit lines count in main units.
    final eggs = view().products.firstWhere((p) => p.id == 7);
    expect(c.read(cartProvider.notifier).addProductInSecondaryUnit(eggs),
        isTrue);
    await tester.pump();
    await tester.tap(find.text('Item 006'));
    await tester.pump();
    expect(qtyOf(7), 1);
    await tester.tap(find.text('Item 006'));
    await tester.pump();
    expect(qtyOf(7), 1);
    expect(qtyOf(7, unit: 'dozen'), 1);
    expect(find.text('Only 13 in stock for Item 006'), findsOneWidget);

    // Item 007 (id 8) is flagged out of stock: the tile does nothing.
    await tester.tap(find.text('Item 007'));
    await tester.pump();
    expect(qtyOf(8), 0);

    // The stepper's minus still lowers and then removes the line.
    final minus = find.descendant(
      of: find.widgetWithText(GridProductTile, 'Item 005'),
      matching: find.byIcon(Icons.remove_rounded),
    );
    await tester.tap(minus);
    await tester.pump();
    expect(qtyOf(6), 1);
    await tester.tap(find.descendant(
      of: find.widgetWithText(GridProductTile, 'Item 005'),
      matching: find.byIcon(Icons.delete_outline_rounded),
    ));
    await tester.pump();
    expect(qtyOf(6), 0);

    await tester.pump(const Duration(seconds: 3)); // snackbar timer
    await tester.pumpAndSettle();
  });

  group('held-tickets comet', () {
    void holdATicket() {
      c.read(heldOrdersProvider.notifier).hold(
        [
          CartItem(
              productId: 1,
              name: 'Item 000',
              unitPrice: 10,
              quantity: 1,
              isTaxable: false),
        ],
        ticketNumber: 'T-0001',
      );
    }

    testWidgets('no held tickets: the sell screen schedules no frames',
        (tester) async {
      await pumpSellScreen(tester);
      expect(find.byType(HeldTicketsBar), findsOneWidget);
      expect(find.byType(CustomPaint).evaluate().where((e) =>
          (e.widget as CustomPaint).painter is TronBorderPainter), isEmpty);
      // Idle: nothing asks for another frame, now or a few seconds on.
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('runs while tickets exist, on its own layer, and stops after',
        (tester) async {
      await pumpSellScreen(tester);
      holdATicket();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('1 held ticket'), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isTrue);

      final border = find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is TronBorderPainter);
      expect(border, findsOneWidget);
      // The comet moves from frame to frame…
      final t0 = (tester.widget<CustomPaint>(border).painter!
              as TronBorderPainter)
          .t;
      await tester.pump(const Duration(milliseconds: 500));
      final t1 = (tester.widget<CustomPaint>(border).painter!
              as TronBorderPainter)
          .t;
      expect(t1, isNot(t0));
      // …inside a RepaintBoundary that sits within the bar itself.
      expect(
        find.ancestor(
          of: border,
          matching: find.descendant(
            of: find.byType(HeldTicketsBar),
            matching: find.byType(RepaintBoundary),
          ),
        ),
        findsOneWidget,
      );

      // Last ticket gone → the ticker stops and the screen goes idle.
      c.read(heldOrdersProvider.notifier).delete('T-0001');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(border, findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('pauses while another page covers the sell screen',
        (tester) async {
      await pumpSellScreen(tester);
      holdATicket();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isTrue);

      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(nav.push(MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('covering page')))));
      // Would never settle if the comet kept ticking underneath.
      await tester.pumpAndSettle();
      expect(find.text('covering page'), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);

      nav.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.binding.hasScheduledFrame, isTrue);
      // Leave nothing ticking for the test binding to complain about.
      c.read(heldOrdersProvider.notifier).delete('T-0001');
      await tester.pumpAndSettle();
    });
  });
}
