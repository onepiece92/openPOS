import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import '../../_support/features.dart';

/// The stock cap lives in the cart notifier, so every way of raising a
/// quantity (tiles, cart "+" stepper, unit picker) is bound by it.
void main() {
  Product product({
    int id = 1,
    int stock = 5,
    bool outOfStock = false,
  }) =>
      Product(
        id: id,
        sku: 'P$id',
        name: 'Eggs',
        price: 10,
        purchasePrice: 0,
        unit: 'pc',
        secondaryUnit: 'dozen',
        conversionRate: 12,
        stockQuantity: stock,
        isTaxable: true,
        isComposite: false,
        isHiddenInPos: false,
        isOutOfStock: outOfStock,
        isActive: true,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  Future<ProviderContainer> containerWith(List<Product> products) async {
    final c = ProviderContainer(overrides: [
      allFeaturesOn,
      productsStreamProvider.overrideWith((ref) => Stream.value(products)),
    ]);
    addTearDown(c.dispose);
    c.listen(productsStreamProvider, (_, __) {});
    await c.read(productsStreamProvider.future);
    return c;
  }

  int qty(ProviderContainer c, {String unit = ''}) => c
      .read(cartProvider)
      .where((i) => i.unitLabel == unit)
      .fold(0, (s, i) => s + i.quantity);

  test('setQuantity (the cart "+" stepper) cannot exceed tracked stock',
      () async {
    final p = product(stock: 5);
    final c = await containerWith([p]);
    final n = c.read(cartProvider.notifier);
    n.addProduct(p);
    n.setQuantity(p.id, 5);
    expect(qty(c), 5);

    n.setQuantity(p.id, 6);
    expect(qty(c), 5);
  });

  test('addProduct cannot exceed tracked stock', () async {
    final p = product(stock: 2);
    final c = await containerWith([p]);
    final n = c.read(cartProvider.notifier);
    n.addProduct(p);
    n.addProduct(p);
    n.addProduct(p);
    expect(qty(c), 2);
  });

  test('secondary-unit lines count in main units', () async {
    final p = product(stock: 30); // dozen = 12
    final c = await containerWith([p]);
    final n = c.read(cartProvider.notifier);
    n.addProductInSecondaryUnit(p); // 12
    n.addProduct(p); // 13
    n.setQuantity(p.id, 2, unitLabel: 'dozen'); // 25
    expect(qty(c, unit: 'dozen'), 2);

    n.setQuantity(p.id, 3, unitLabel: 'dozen'); // 37 > 30
    expect(qty(c, unit: 'dozen'), 2);
    n.setQuantity(p.id, 7); // 24 + 7 = 31 > 30
    expect(qty(c), 1);
    n.setQuantity(p.id, 6); // 24 + 6 = 30
    expect(qty(c), 6);
    n.addProductInSecondaryUnit(p); // would be 42
    expect(qty(c, unit: 'dozen'), 2);
  });

  test('untracked products (stock 0, not flagged) stay unlimited', () async {
    final p = product(stock: 0);
    final c = await containerWith([p]);
    final n = c.read(cartProvider.notifier);
    n.addProduct(p);
    n.setQuantity(p.id, 500);
    expect(qty(c), 500);
  });

  test('an out-of-stock product cannot be added', () async {
    final p = product(stock: 0, outOfStock: true);
    final c = await containerWith([p]);
    c.read(cartProvider.notifier).addProduct(p);
    expect(c.read(cartProvider), isEmpty);
  });

  test('lowering a quantity is always allowed', () async {
    final p = product(stock: 3);
    final c = await containerWith([p]);
    final n = c.read(cartProvider.notifier);
    // A resumed ticket may hold more than is in stock now.
    n.restoreItem(CartItem(
        productId: p.id,
        name: p.name,
        unitPrice: 10,
        quantity: 8,
        isTaxable: true));
    expect(qty(c), 8);
    n.setQuantity(p.id, 7);
    expect(qty(c), 7);
    n.setQuantity(p.id, 8);
    expect(qty(c), 7);
  });
}
