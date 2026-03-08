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
