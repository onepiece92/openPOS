import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/cart_detail_screen.dart';
import 'package:pos_app/features/cart/presentation/clear_cart.dart';
import 'package:pos_app/features/cart/presentation/home.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

import '../../_support/fake_products.dart';

/// Every Clear cart (app bar icon, menu, ⌘K, the cart screen's Clear) goes
/// through one function: the cart is cleared and "Undo" puts back exactly
/// what was there, for about 5 seconds.
void main() {
  late Directory tmp;
  late Box<dynamic> heldBox;
  late Box<dynamic> settingsBox;
  late ProviderContainer c;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_clear_undo_');
    Hive.init(tmp.path);
    heldBox = await Hive.openBox<dynamic>('held_orders', bytes: Uint8List(0));
    settingsBox = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
    final products = [fakeProduct(id: 1, name: 'Tea'), fakeProduct(id: 2, name: 'Cake')];
    c = ProviderContainer(overrides: [
      settingsBoxProvider.overrideWithValue(settingsBox),
      heldOrdersBoxProvider.overrideWithValue(heldBox),
      productsStreamProvider.overrideWith((ref) => Stream.value(products)),
      categoriesStreamProvider
          .overrideWith((ref) => Stream.value(const <Category>[])),
      productSalesCountProvider.overrideWith((ref) async => <int, int>{}),
    ]);
  });

  tearDown(() async {
    c.dispose();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  /// Two lines with a line discount, an order discount, a table, tax off and
  /// a resumed ticket's id: everything a clear throws away.
  void fillCart() {
    final cart = c.read(cartProvider.notifier);
    cart.restoreItem(CartItem(
        productId: 1, name: 'Tea', unitPrice: 3, quantity: 2, isTaxable: true));
    cart.restoreItem(CartItem(
        productId: 2,
        name: 'Cake',
        unitPrice: 5,
        quantity: 1,
        isTaxable: true,
        lineDiscount: 1));
    final s = c.read(cartSessionProvider.notifier);
    s.setOrderDiscount(10, isPercent: true);
    s.setTable(4);
    s.setTaxEnabled(false);
    // Bound to a held ticket that is still on file.
    final held = c.read(heldOrdersProvider.notifier).holdCurrentCart();
    s.restore(c.read(cartSessionProvider).copyWith(heldTicketId: held.id));
  }

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(home: home),
    ));
    await tester.pumpAndSettle();
  }

  /// Animations run out (a held ticket on the bar keeps pumpAndSettle busy).
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> expectClearedThenUndone(
      WidgetTester tester, Future<void> Function() clear) async {
    fillCart();
    await tester.pump();
    final items = c.read(cartProvider);
    final session = c.read(cartSessionProvider);
    final rates = c.read(selectedTaxRatesProvider);

    await clear();
    await settle(tester); // the SnackBar slides in
    expect(c.read(cartProvider), isEmpty);
    expect(c.read(cartSessionProvider).ticketNumber,
        isNot(session.ticketNumber));
    expect(find.text(kCartClearedMessage), findsOneWidget);

    await tester.tap(find.text(kCartClearedUndo));
    await tester.pump();
    expect(c.read(cartProvider), items);
    final back = c.read(cartSessionProvider);
    expect(identical(back, session), isTrue,
        reason: 'number, ticket, table, discount and tax all come back');
    expect(back.orderDiscount, 10);
    expect(back.tableId, 4);
    expect(back.heldTicketId, isNotNull);
    expect(heldBox.containsKey(back.heldTicketId), isTrue);
    expect(back.taxEnabled, isFalse);
    expect(c.read(selectedTaxRatesProvider), rates);
    await tester.pump(const Duration(seconds: 6));
    await settle(tester);
  }

  testWidgets('the app bar icon: Undo restores the exact cart',
      (tester) async {
    await pump(tester, const CartScreen());
    await expectClearedThenUndone(tester,
        () => tester.tap(find.byTooltip('Clear cart')));
  });

  testWidgets('the menu item: Undo restores the exact cart', (tester) async {
    await pump(tester, const CartScreen());
    await expectClearedThenUndone(tester, () async {
      await tester.tap(find.byType(PopupMenuButton<String>));
      await settle(tester);
      await tester.tap(find.text('Clear Cart'));
      await settle(tester);
    });
  });

  testWidgets('⌘K: Undo restores the exact cart', (tester) async {
    await pump(tester, const CartScreen());
    await expectClearedThenUndone(tester, () async {
      // Focus inside the shortcuts, off the search field.
      final shortcuts = find.byType(CallbackShortcuts).first;
      Focus.of(tester.element(find.descendant(
              of: shortcuts, matching: find.byType(Column)).first))
          .requestFocus();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    });
  });

  testWidgets("the cart screen's Clear: Undo restores the exact cart",
      (tester) async {
    await pump(tester, const CartDetailScreen());
    await expectClearedThenUndone(tester, () async {
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Clear'));
    });
  });

  Future<void> clearFromIcon(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Clear cart'));
    await settle(tester);
  }

  testWidgets('Undo with a non-empty cart replaces nothing and says so',
      (tester) async {
    await pump(tester, const CartScreen());
    fillCart();
    await tester.pump();
    await clearFromIcon(tester);
    final newLine = CartItem(
        productId: 2, name: 'Cake', unitPrice: 5, quantity: 1, isTaxable: true);
    c.read(cartProvider.notifier).restoreItem(newLine);
    final session = c.read(cartSessionProvider);
    await tester.pump();
    await tester.tap(find.text(kCartClearedUndo));
    await settle(tester);
    expect(c.read(cartProvider), [newLine]);
    expect(identical(c.read(cartSessionProvider), session), isTrue);
    expect(find.text(kCartUndoNotEmpty), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await settle(tester);
  });

  testWidgets('Undo after the linked ticket was paid brings the lines back '
      'without the link', (tester) async {
    await pump(tester, const CartScreen());
    fillCart();
    final ticketId = c.read(cartSessionProvider).heldTicketId!;
    await tester.pump();
    final items = c.read(cartProvider);
    await clearFromIcon(tester);
    // The ticket is paid elsewhere meanwhile (here: being paid, then gone).
    await tester.runAsync(() async {
      await c.read(heldOrdersProvider.notifier).beginPayment(ticketId);
    });
    await tester.tap(find.text(kCartClearedUndo));
    await tester.pump();
    expect(c.read(cartProvider), items);
    expect(c.read(cartSessionProvider).heldTicketId, isNull,
        reason: 'a restored cart cannot sell that ticket again');
    expect(c.read(cartSessionProvider).tableId, 4);
    await tester.pump(const Duration(seconds: 6));
    await settle(tester);
  });

  testWidgets('a sale (or a resume) withdraws the Undo', (tester) async {
    await pump(tester, const CartScreen());
    fillCart();
    await tester.pump();
    await clearFromIcon(tester);
    expect(find.text(kCartClearedUndo), findsOneWidget);
    cancelCartUndo(); // what the payment screen and the resume do
    await settle(tester);
    expect(find.text(kCartClearedUndo), findsNothing);
    expect(c.read(cartProvider), isEmpty);
  });

  testWidgets('Undo is gone after about 5 seconds; the cart stays cleared',
      (tester) async {
    await pump(tester, const CartScreen());
    fillCart();
    await tester.pump();
    await tester.tap(find.byTooltip('Clear cart'));
    await settle(tester);
    expect(find.text(kCartClearedUndo), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text(kCartClearedUndo), findsOneWidget, reason: 'still up');
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.text(kCartClearedUndo), findsNothing);
    expect(c.read(cartProvider), isEmpty);
  });

  testWidgets('an empty cart: nothing happens, no message, same ticket',
      (tester) async {
    await pump(tester, const CartScreen());
    final number = c.read(cartSessionProvider).ticketNumber;
    late BuildContext ctx;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: Scaffold(body: Consumer(builder: (context, ref, _) {
          ctx = context;
          return TextButton(
              onPressed: () => clearCartWithUndo(ctx, ref),
              child: const Text('go'));
        })),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.text(kCartClearedMessage), findsNothing);
    expect(c.read(cartSessionProvider).ticketNumber, number);
  });
}
