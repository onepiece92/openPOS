import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/cart/domain/pos_catalog_provider.dart';
import 'package:pos_app/features/cart/domain/pos_filter_provider.dart';
import 'package:pos_app/features/inventory/presentation/inventory_screen.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

import '../../_support/fake_products.dart';

/// The sell, Products and Inventory screens all read the one list held by
/// productsStreamProvider. Each used to sort it in place when no filter was
/// set, so opening one screen reordered the source of the other two.
///
/// The source here is unmodifiable: an in-place sort throws.
void main() {
  // Deliberately in no useful order, by name or by price.
  List<Product> source() => List.unmodifiable([
        fakeProduct(id: 1, name: 'Mango', price: 3),
        fakeProduct(id: 2, name: 'Apple', price: 9),
        fakeProduct(id: 3, name: 'Zucchini', price: 1),
        fakeProduct(id: 4, name: 'Banana', price: 5),
      ]);

  List<int> ids(Iterable<Product> l) => [for (final p in l) p.id];
  const original = [1, 2, 3, 4];

  test('sell screen: every sort mode leaves the provider list untouched',
      () async {
    final all = source();
    final c = ProviderContainer(overrides: [
      productsStreamProvider.overrideWith((ref) => Stream.value(all)),
      productSalesCountProvider.overrideWith((ref) async => {4: 7, 1: 2}),
    ]);
    addTearDown(c.dispose);
    c.listen(posCatalogProvider, (_, __) {});
    await c.read(productsStreamProvider.future);
    await c.read(productSalesCountProvider.future);

    const expected = {
      PosSortMode.mostSold: [4, 1, 2, 3], // 7, 2, then names A→Z
      PosSortMode.nameAZ: [2, 4, 1, 3],
      PosSortMode.nameZA: [3, 1, 4, 2],
      PosSortMode.priceLH: [3, 1, 4, 2],
      PosSortMode.priceHL: [2, 4, 1, 3],
    };
    for (final mode in PosSortMode.values) {
      c.read(posFilterProvider.notifier).setSortMode(mode);
      final shown = c.read(posCatalogProvider).requireValue.products;
      expect(ids(shown), expected[mode], reason: '$mode');
      expect(identical(shown, all), isFalse);
      expect(ids(c.read(productsStreamProvider).requireValue), original,
          reason: 'source reordered by $mode');
    }
  });

  test('Products screen filter returns a sorted copy', () {
    final all = source();
    for (final sortAZ in [true, false]) {
      final shown =
          applyProductsFilter(all, ProductsFilterState(sortAZ: sortAZ));
      expect(ids(shown), sortAZ ? [2, 4, 1, 3] : [3, 1, 4, 2]);
      expect(identical(shown, all), isFalse);
      expect(ids(all), original);
    }
  });

  test('Inventory screen filter returns a sorted copy', () {
    final all = source();
    for (final sortAZ in [true, false]) {
      final shown = filterInventoryProducts(
        all,
        stockFilter: null,
        search: '',
        sortAZ: sortAZ,
        lowStockThreshold: 5,
      );
      expect(ids(shown), sortAZ ? [2, 4, 1, 3] : [3, 1, 4, 2]);
      expect(identical(shown, all), isFalse);
      expect(ids(all), original);
    }
  });

  test('the three screens do not reorder each other (plain growable list)',
      () {
    // Same check without relying on the list refusing writes.
    final all = [...source()];
    sortPosProducts(all, const {}, PosSortMode.priceHL);
    applyProductsFilter(all, const ProductsFilterState(sortAZ: false));
    filterInventoryProducts(all,
        stockFilter: null, search: '', sortAZ: true, lowStockThreshold: 5);
    expect(ids(all), original);
  });

  test('filters still narrow as before', () {
    final all = List<Product>.unmodifiable([
      fakeProduct(id: 1, name: 'Green Tea', sku: 'TEA-1', categoryId: 1),
      fakeProduct(id: 2, name: 'Coffee', sku: 'cof-2', categoryId: 2),
      fakeProduct(id: 3, name: 'Tea Cake', sku: 'CK-3', categoryId: 2),
      fakeProduct(
          id: 4, name: 'Scone', sku: 'SC-4', categoryId: 2, outOfStock: true),
      fakeProduct(id: 5, name: 'Bun', sku: 'BN-5', stock: 2),
    ]);
    final index = buildPosSearchIndex(all);

    // Sell screen: name OR sku, case-insensitive; category; favourites.
    expect(ids(filterPosProducts(all, searchIndex: index, search: 'TEA')),
        [1, 3]);
    expect(ids(filterPosProducts(all, searchIndex: index, search: 'COF-')),
        [2]);
    expect(ids(filterPosProducts(all, searchIndex: index, categoryId: 2)),
        [2, 3, 4]);
    expect(
        ids(filterPosProducts(all,
            searchIndex: index, categoryId: 2, favorites: {1, 3}, search: 't')),
        [3]);
    // A product the index has not caught up with is still searchable.
    expect(ids(filterPosProducts(all, searchIndex: const {}, search: 'bun')),
        [5]);

    expect(
        ids(applyProductsFilter(
            all,
            const ProductsFilterState(
                selectedCategoryId: 2, search: 'c', outOfStockOnly: true))),
        [4]);
    expect(
        ids(filterInventoryProducts(all,
            stockFilter: 'low', search: '', sortAZ: true, lowStockThreshold: 5)),
        [5]);
    expect(
        ids(filterInventoryProducts(all,
            stockFilter: 'out',
            search: 'sc',
            sortAZ: true,
            lowStockThreshold: 5)),
        [4]);
  });
}
