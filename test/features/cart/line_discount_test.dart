import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart' show Product;
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

/// A line discount is a flat amount off the line. It can never be more than
/// the line is worth before the discount (unit price × quantity), whatever
/// order the discount and the quantity are set in.
void main() {
  late ProviderContainer c;
  late CartNotifier cart;

  setUp(() {
    c = ProviderContainer(overrides: [
      productsStreamProvider
          .overrideWith((ref) => Stream.value(const <Product>[])),
    ]);
    cart = c.read(cartProvider.notifier);
  });
  tearDown(() => c.dispose());

  CartItem line() => c.read(cartProvider).single;

  void add({double price = 100, int qty = 1}) => cart.restoreItem(CartItem(
      productId: 1,
      name: 'A',
      unitPrice: price,
      quantity: qty,
      isTaxable: true));

  test('the cap is the gross line amount, not what an earlier discount left',
      () {
    add();
    cart.setDiscount(1, 60);
    expect(line().lineDiscount, 60);
    // Was clamped against the already-discounted 40.
    cart.setDiscount(1, 80);
    expect(line().lineDiscount, 80);
    expect(line().lineSubtotal, 20);
    cart.setDiscount(1, 20);
    expect(line().lineDiscount, 20);
  });

  test('a discount larger than the line is capped at the line', () {
    add(price: 30, qty: 2);
    cart.setDiscount(1, 500);
    expect(line().lineDiscount, 60);
    expect(line().lineSubtotal, 0);
  });

  test('a negative discount is treated as none', () {
    add();
    cart.setDiscount(1, -5);
    expect(line().lineDiscount, 0);
  });

  test('lowering the quantity re-caps the discount: no negative line', () {
    add(price: 50, qty: 4);
    cart.setDiscount(1, 150);
    expect(line().lineSubtotal, 50);

    cart.setQuantity(1, 1);
    expect(line().lineDiscount, 50);
    expect(line().lineSubtotal, 0);
  });

  test('raising the quantity keeps the discount as it was', () {
    add(price: 50, qty: 1);
    cart.setDiscount(1, 20);
    cart.setQuantity(1, 3);
    expect(line().lineDiscount, 20);
    expect(line().lineSubtotal, 130);
  });

  test('only the addressed line (product + unit) is touched', () {
    add();
    cart.restoreItem(CartItem(
        productId: 1,
        name: 'A',
        unitPrice: 1000,
        quantity: 1,
        isTaxable: true,
        unitLabel: 'box',
        unitsPerQty: 10));
    cart.setDiscount(1, 300, unitLabel: 'box');
    final lines = c.read(cartProvider);
    expect(lines.first.lineDiscount, 0);
    expect(lines.last.lineDiscount, 300);
  });
}
