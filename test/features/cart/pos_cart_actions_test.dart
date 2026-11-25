import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/pos_cart_actions.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

import '../../_support/fake_products.dart';

/// The sell-screen tile stepper. Raising a quantity is capped at stock;
/// lowering one never is, even when the line already sits above stock
/// (a resumed ticket, or stock sold elsewhere since the line was added).
void main() {
  Future<(ProviderContainer, PosCartActions)> pump(
      WidgetTester tester, Product p) async {
    final c = ProviderContainer(overrides: [
      productsStreamProvider.overrideWith((ref) => Stream.value([p])),
    ]);
    addTearDown(c.dispose);
    late PosCartActions actions;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            actions = PosCartActions.of(context);
            return const SizedBox();
          }),
        ),
      ),
    ));
    c.listen(productsStreamProvider, (_, __) {});
    await tester.pump();
    return (c, actions);
  }

  CartItem line(Product p, int qty) => CartItem(
        productId: p.id,
        name: p.name,
        unitPrice: p.price,
        quantity: qty,
        isTaxable: true,
      );

  int qty(ProviderContainer c) =>
      c.read(cartProvider).fold(0, (s, i) => s + i.quantity);

  testWidgets('minus lowers a line that is already above stock',
      (tester) async {
    // 5 in the cart, but only 3 left in stock by now.
    final p = fakeProduct(id: 1, name: 'Eggs', stock: 3);
    final (c, actions) = await pump(tester, p);
    c.read(cartProvider.notifier).restoreItem(line(p, 5));
    expect(qty(c), 5);

    actions.step(p, -1);
    await tester.pump();
    expect(qty(c), 4, reason: '5 → 4 must not be refused by the stock cap');
    expect(find.textContaining('in stock'), findsNothing);

    actions.step(p, -1);
    actions.step(p, -1);
    expect(qty(c), 2);
  });

  testWidgets('plus is still capped at stock, with the reason shown',
      (tester) async {
    final p = fakeProduct(id: 1, name: 'Eggs', stock: 3);
    final (c, actions) = await pump(tester, p);
    c.read(cartProvider.notifier).restoreItem(line(p, 3));

    actions.step(p, 1);
    await tester.pump();
    expect(qty(c), 3);
    expect(find.text('Only 3 in stock for Eggs'), findsOneWidget);

    // Above stock already: raising further is refused too.
    c.read(cartProvider.notifier).restoreItem(line(p, 2)); // 3 + 2
    actions.step(p, 1);
    expect(qty(c), 5);
  });
}
