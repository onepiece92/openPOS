import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart' show Product;
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/pos_filter_provider.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/products/domain/favorites_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

// The sell screen's product list, derived once per input change.
//
// Nothing here reads the cart: adding to the cart must not re-filter or
// re-sort the catalogue. The work is split so each stage re-runs only for
// the inputs it depends on:
//
//   products ─┬─► search index (lowercased keys)   per product emission
//             └─► sorted      (+ sales, sort mode) per emission / sort change
//                    └─► visible (+ category, favourites, search) per keystroke
//
// Every stage builds a new list. The list held by [productsStreamProvider]
// is shared with the Products and Inventory screens and is never sorted or
// otherwise changed in place.

/// productId → lowercased "name\nsku", built once per product emission so a
/// keystroke does not lowercase the whole catalogue again.
final posSearchIndexProvider = Provider.autoDispose<Map<int, String>>((ref) {
  final products =
      ref.watch(productsStreamProvider).valueOrNull ?? const <Product>[];
  return buildPosSearchIndex(products);
});

Map<int, String> buildPosSearchIndex(List<Product> products) => {
      for (final p in products)
        p.id: '${p.name.toLowerCase()}\n${p.sku.toLowerCase()}',
    };

/// The whole catalogue in the chosen order — a copy, never the source list.
List<Product> sortPosProducts(
  List<Product> all,
  Map<int, int> salesCounts,
  PosSortMode mode,
) {
  final list = List<Product>.of(all);
  switch (mode) {
    case PosSortMode.mostSold:
      list.sort((a, b) {
        final diff = (salesCounts[b.id] ?? 0).compareTo(salesCounts[a.id] ?? 0);
        return diff != 0 ? diff : a.name.compareTo(b.name);
      });
    case PosSortMode.nameAZ:
      list.sort((a, b) => a.name.compareTo(b.name));
    case PosSortMode.nameZA:
      list.sort((a, b) => b.name.compareTo(a.name));
    case PosSortMode.priceLH:
      list.sort((a, b) => a.price.compareTo(b.price));
    case PosSortMode.priceHL:
      list.sort((a, b) => b.price.compareTo(a.price));
  }
  return list;
}

/// Narrows an already sorted list, keeping its order. [favorites] is only
/// consulted when non-null (the favourites-only chip is on); [search] is
/// matched against [searchIndex], falling back to the product's own fields
/// for an id the index does not hold.
List<Product> filterPosProducts(
  List<Product> sorted, {
  required Map<int, String> searchIndex,
  int? categoryId,
  Set<int>? favorites,
  String search = '',
}) {
  final q = search.toLowerCase();
  return [
    for (final p in sorted)
      if ((categoryId == null || p.categoryId == categoryId) &&
          (favorites == null || favorites.contains(p.id)) &&
          (q.isEmpty ||
              (searchIndex[p.id] ??
                      '${p.name.toLowerCase()}\n${p.sku.toLowerCase()}')
                  .contains(q)))
        p,
  ];
}

final _posSortedProductsProvider =
    Provider.autoDispose<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  // Until the sales counts arrive the ranking falls back to name order.
  final salesCounts =
      ref.watch(productSalesCountProvider).valueOrNull ?? const <int, int>{};
  final mode = ref.watch(posFilterProvider.select((f) => f.sortMode));
  return productsAsync
      .whenData((all) => sortPosProducts(all, salesCounts, mode));
});

/// What the sell screen's product area shows.
class PosCatalogView {
  const PosCatalogView({required this.catalogEmpty, required this.products});

  /// True when the shop has no sellable products at all (as opposed to the
  /// current filter matching none).
  final bool catalogEmpty;

  /// Filtered and sorted, ready for the grid or list.
  final List<Product> products;
}

/// The filtered, sorted product list for the sell screen.
///
/// Depends on products, most-sold counts, the filter's sort / category /
/// search / favourites-only fields and (only while favourites-only is on)
/// the favourites set. It does not depend on the cart, nor on the grid/list
/// toggle. Auto-disposed with the screen so the most-sold counts are still
/// read afresh on each visit.
final posCatalogProvider =
    Provider.autoDispose<AsyncValue<PosCatalogView>>((ref) {
  final sortedAsync = ref.watch(_posSortedProductsProvider);
  final (categoryId, search, favoritesOnly) = ref.watch(
    posFilterProvider
        .select((f) => (f.selectedCategoryId, f.search, f.favoritesOnly)),
  );
  final favorites = favoritesOnly ? ref.watch(favoritesProvider) : null;
  // Watched even with an empty search so the index lives as long as the
  // screen and is not rebuilt each time the cashier starts typing.
  final searchIndex = ref.watch(posSearchIndexProvider);
  return sortedAsync.whenData(
    (sorted) => PosCatalogView(
      catalogEmpty: sorted.isEmpty,
      products: filterPosProducts(
        sorted,
        searchIndex: searchIndex,
        categoryId: categoryId,
        favorites: favorites,
        search: search,
      ),
    ),
  );
});

// ─── Cart quantities for the tiles ───────────────────────────────────────────

/// productId → quantity on the product's main-unit cart line (what a tile's
/// badge and stepper show). Secondary-unit lines are separate lines and do
/// not appear here. Computed once per cart change; each tile then selects
/// its own entry, so a tap rebuilds only the tile whose number moved.
final cartMainUnitQtyProvider = Provider<Map<int, int>>((ref) {
  final cart = ref.watch(cartProvider);
  return {
    for (final i in cart)
      if (!i.isSecondaryUnit) i.productId: i.quantity,
  };
});

/// Main units of [productId] across every line of [cart] (pcs + boxes) —
/// what the stock cap is measured against.
int committedMainUnits(List<CartItem> cart, int productId) {
  var total = 0;
  for (final i in cart) {
    if (i.productId == productId) total += i.mainUnitQty;
  }
  return total;
}
