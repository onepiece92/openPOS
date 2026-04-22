import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';

/// All active products, reactively updated.
/// POS catalog — excludes hidden-in-pos products.
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(databaseProvider).productsDao.watchAllForPos();
});

/// Products filtered by category.
final productsByCategoryProvider =
    StreamProvider.family<List<Product>, int>((ref, categoryId) {
  return ref
      .watch(databaseProvider)
      .productsDao
      .watchByCategory(categoryId);
});

/// All categories, sorted by sortOrder then name.
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(databaseProvider).productsDao.watchAllCategories();
});

/// Active tax rates.
final taxRatesStreamProvider = StreamProvider<List<TaxRate>>((ref) {
  return ref.watch(databaseProvider).taxDao.watchActive();
});

/// productId → total units sold (reactively updated as orders are placed).
final productSalesCountProvider = StreamProvider<Map<int, int>>((ref) {
  return ref.watch(databaseProvider).ordersDao.watchProductSalesCounts();
});

/// Currency symbol from Hive settings (e.g. "Rs", "$").
final currencySymbolProvider = Provider<String>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return box.get(kCurrencySymbol, defaultValue: 'Rs') as String;
});

// ── Products screen filter state ──────────────────────────────────────────────
// Kept in a provider (not widget state) so navigating away and back
// preserves the user's chosen sort / filter / search preferences.

class ProductsFilterState {
  const ProductsFilterState({
    this.sortAZ = true,
    this.outOfStockOnly = false,
    this.selectedCategoryId,
    this.search = '',
  });

  final bool sortAZ;
  final bool outOfStockOnly;
  final int? selectedCategoryId;
  final String search;

  ProductsFilterState copyWith({
    bool? sortAZ,
    bool? outOfStockOnly,
    int? selectedCategoryId,
    bool clearCategory = false,
    String? search,
  }) =>
      ProductsFilterState(
        sortAZ: sortAZ ?? this.sortAZ,
        outOfStockOnly: outOfStockOnly ?? this.outOfStockOnly,
        selectedCategoryId:
            clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
        search: search ?? this.search,
      );
}

class ProductsFilterNotifier extends StateNotifier<ProductsFilterState> {
  ProductsFilterNotifier() : super(const ProductsFilterState());

  void toggleSort() => state = state.copyWith(sortAZ: !state.sortAZ);
  void toggleOutOfStock() =>
      state = state.copyWith(outOfStockOnly: !state.outOfStockOnly);
  void setCategory(int? id) => id == null
      ? state = state.copyWith(clearCategory: true)
      : state = state.copyWith(selectedCategoryId: id);
  void setSearch(String q) => state = state.copyWith(search: q);
  void clearSearch() => state = state.copyWith(search: '');
}

final productsFilterProvider =
    StateNotifierProvider<ProductsFilterNotifier, ProductsFilterState>(
  (_) => ProductsFilterNotifier(),
);
