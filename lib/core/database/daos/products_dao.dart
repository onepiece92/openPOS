import 'package:drift/drift.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/tables/categories_table.dart';
import 'package:pos_app/core/database/tables/product_components_table.dart';
import 'package:pos_app/core/database/tables/product_taxes_table.dart';
import 'package:pos_app/core/database/tables/products_table.dart';

part 'products_dao.g.dart';

@DriftAccessor(
  tables: [Products, ProductComponents, ProductTaxes, Categories],
)
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  ProductsDao(super.db);

  // ── Watch ──────────────────────────────────────────────────────────────

  Stream<List<Product>> watchAll() =>
      (select(products)..where((p) => p.isActive.equals(true))).watch();

  /// POS-facing stream: excludes soft-deleted AND hidden-in-pos products.
  Stream<List<Product>> watchAllForPos() =>
      (select(products)
            ..where((p) =>
                p.isActive.equals(true) & p.isHiddenInPos.equals(false)))
          .watch();

  Stream<List<Product>> watchByCategory(int categoryId) => (select(products)
        ..where((p) =>
            p.categoryId.equals(categoryId) & p.isActive.equals(true)))
      .watch();

  // ── Read ───────────────────────────────────────────────────────────────

  Future<Product?> getBySku(String sku) =>
      (select(products)..where((p) => p.sku.equals(sku))).getSingleOrNull();

  Future<Product?> getById(int id) =>
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<int> upsert(ProductsCompanion entry) =>
      into(products).insertOnConflictUpdate(entry);

  /// Targeted update for edit mode — only touches columns present in [companion].
  Future<void> updateProduct(int id, ProductsCompanion companion) =>
      (update(products)..where((p) => p.id.equals(id))).write(companion);

  /// Soft-delete: sets is_active = false. Hard deletes break order history.
  Future<void> softDelete(int id) async {
    await (update(products)..where((p) => p.id.equals(id)))
        .write(const ProductsCompanion(isActive: Value(false)));
  }

  /// Deduct stock on sale and return the units actually removed, so the
  /// caller can log exactly what changed (0 = nothing to log).
  ///
  /// Only deducts when stock is being counted (stock_quantity > 0); a value
  /// of 0 without the out-of-stock flag means "untracked / unlimited" and is
  /// never touched. Stock never goes below 0, and a tracked product that
  /// reaches 0 is flagged out of stock — otherwise selling the last unit
  /// would silently turn it into an unlimited product.
  Future<int> deductStock(int productId, int quantity) async {
    final product = await getById(productId);
    if (product == null || quantity <= 0 || product.stockQuantity <= 0) {
      return 0;
    }
    final taken =
        quantity < product.stockQuantity ? quantity : product.stockQuantity;
    final left = product.stockQuantity - taken;
    await (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(
        stockQuantity: Value(left),
        isOutOfStock: left == 0 ? const Value(true) : const Value.absent(),
      ),
    );
    return taken;
  }

  /// Put [quantity] units back after a void or refund and return the units
  /// actually added (0 = nothing to log).
  ///
  /// Untracked products (stock 0, not flagged out of stock) are left alone:
  /// the sale never deducted from them, and giving them a quantity would
  /// start capping an unlimited product. A product that had sold out
  /// (nothing left) becomes sellable again; a product the owner flagged out
  /// of stock while it still had units keeps the flag.
  Future<int> restock(int productId, int quantity) async {
    final product = await getById(productId);
    if (product == null || quantity <= 0) return 0;
    final untracked = product.stockQuantity == 0 && !product.isOutOfStock;
    if (untracked) return 0;
    final hadNone = product.stockQuantity <= 0;
    final base = hadNone ? 0 : product.stockQuantity;
    await (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(
        stockQuantity: Value(base + quantity),
        isOutOfStock: hadNone ? const Value(false) : const Value.absent(),
      ),
    );
    return quantity;
  }

  /// Set stock to an absolute value.
  Future<void> setStock(int productId, int quantity) => customUpdate(
        'UPDATE products SET stock_quantity = ? WHERE id = ?',
        variables: [Variable(quantity), Variable(productId)],
        updates: {products},
      );

  /// Combined qty + out-of-stock write — single UPDATE, single stream emission.
  /// Use for stepper transitions that change both at once.
  Future<void> setStockState(
    int productId, {
    required int stockQuantity,
    required bool isOutOfStock,
  }) =>
      (update(products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(
          stockQuantity: Value(stockQuantity),
          isOutOfStock: Value(isOutOfStock),
        ),
      );

  // ── Composite components ────────────────────────────────────────────────

  Future<List<ProductComponent>> getComponents(int compositeId) =>
      (select(productComponents)
            ..where((c) => c.compositeProductId.equals(compositeId)))
          .get();

  Future<void> replaceComponents(
      int compositeId, List<ProductComponentsCompanion> entries) async {
    await (delete(productComponents)
          ..where((c) => c.compositeProductId.equals(compositeId)))
        .go();
    if (entries.isNotEmpty) {
      await batch((b) => b.insertAll(productComponents, entries));
    }
  }

  // ── Categories ──────────────────────────────────────────────────────────

  Stream<List<Category>> watchAllCategories() =>
      (select(categories)
            ..orderBy([
              (c) => OrderingTerm(expression: c.sortOrder),
              (c) => OrderingTerm(expression: c.name),
            ]))
          .watch();

  Future<List<Category>> getAllCategories() => select(categories).get();

  Future<int> upsertCategory(CategoriesCompanion entry) =>
      into(categories).insertOnConflictUpdate(entry);

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();
}
