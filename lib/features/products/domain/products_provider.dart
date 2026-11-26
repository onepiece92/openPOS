import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';

/// All active products, reactively updated.
/// POS catalog — excludes hidden-in-pos products.
///
/// Several screens share this one list, so it is handed out unmodifiable:
/// sorting or editing it in place throws. Work on a copy (`[...list]`).
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref
      .watch(databaseProvider)
      .productsDao
      .watchAllForPos()
      .map(List<Product>.unmodifiable);
});

/// Products filtered by category. Used only by the categories screen's
/// expandable rows, so it stops querying when the row (or screen) goes away.
final productsByCategoryProvider =
    StreamProvider.autoDispose.family<List<Product>, int>((ref, categoryId) {
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

/// How far back the sell screen's "most sold" ranking looks.
const mostSoldWindow = Duration(days: 90);

/// productId → units sold (main units) over the last [mostSoldWindow].
///
/// Read once when the sell screen opens, not streamed: the ranking then
/// holds still for the whole visit — tiles do not reshuffle under the
/// cashier's finger after each sale — and no query re-runs on every order
/// write or receipt print. Leaving the sell screen and coming back (or
/// restarting the app) takes a fresh reading.
final productSalesCountProvider =
    FutureProvider.autoDispose<Map<int, int>>((ref) {
  return ref.watch(databaseProvider).ordersDao.productSalesCounts(
        since: DateTime.now().subtract(mostSoldWindow),
      );
});

/// Shared [CurrencyFormatter] that reads the active currency symbol from
/// settings. Use this in UI code instead of inline `toStringAsFixed(2)`
/// concatenation so the symbol, grouping, and decimal count stay consistent.
final currencyFormatterProvider = Provider<CurrencyFormatter>((ref) {
  final symbol = ref.watch(currencySymbolProvider);
  final code = ref.watch(currencyCodeProvider);
  return CurrencyFormatter(
      symbol: '$symbol ', locale: 'en_US', currencyCode: code);
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

/// The Products screen's list: [all] narrowed by [f] and sorted by name.
///
/// Always a new list. [all] is the list held by [productsStreamProvider],
/// which the sell and Inventory screens read too — sorting it in place
/// would reorder their source.
List<Product> applyProductsFilter(List<Product> all, ProductsFilterState f) {
  Iterable<Product> list = all;
  if (f.selectedCategoryId != null) {
    list = list.where((p) => p.categoryId == f.selectedCategoryId);
  }
  if (f.outOfStockOnly) {
    // is_out_of_stock flag OR qty < 0 (over-sold). 0 = unlimited.
    list = list.where((p) => p.isOutOfStock || p.stockQuantity < 0);
  }
  if (f.search.isNotEmpty) {
    final q = f.search.toLowerCase();
    list = list.where((p) =>
        p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q));
  }
  return list.toList()
    ..sort((a, b) =>
        f.sortAZ ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
}
