import 'package:drift/drift.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/tables/categories_table.dart';
import 'package:pos_app/core/database/tables/product_components_table.dart';
import 'package:pos_app/core/database/tables/product_modifiers_table.dart';
import 'package:pos_app/core/database/tables/product_taxes_table.dart';
import 'package:pos_app/core/database/tables/product_variants_table.dart';
import 'package:pos_app/core/database/tables/products_table.dart';

part 'products_dao.g.dart';

@DriftAccessor(
  tables: [Products, ProductComponents, ProductVariants, ProductModifiers, ProductTaxes, Categories],
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

  Future<List<ProductVariant>> getVariants(int productId) =>
      (select(productVariants)
            ..where((v) => v.productId.equals(productId)))
          .get();

  Future<List<ProductModifier>> getModifiers(int productId) =>
      (select(productModifiers)
            ..where((m) => m.productId.equals(productId)))
          .get();

  // ── Write ──────────────────────────────────────────────────────────────

  Future<int> upsert(ProductsCompanion entry) =>
      into(products).insertOnConflictUpdate(entry);

  /// Targeted update for edit mode — only touches columns present in [companion].
  Future<void> updateProduct(int id, ProductsCompanion companion) =>
      (update(products)..where((p) => p.id.equals(id))).write(companion);

  Future<int> upsertVariant(ProductVariantsCompanion entry) =>
      into(productVariants).insertOnConflictUpdate(entry);

  Future<int> upsertModifier(ProductModifiersCompanion entry) =>
      into(productModifiers).insertOnConflictUpdate(entry);

  /// Soft-delete: sets is_active = false. Hard deletes break order history.
  Future<void> softDelete(int id) async {
    await (update(products)..where((p) => p.id.equals(id)))
        .write(const ProductsCompanion(isActive: Value(false)));
  }

  /// Deduct stock on sale. Caller is responsible for audit logging.
  /// Only deducts when stock tracking is active (stock_quantity > 0).
  /// A value of 0 means "unlimited" — never touch it.
  Future<void> deductStock(int productId, int quantity) async {
    await customUpdate(
      'UPDATE products SET stock_quantity = stock_quantity - ? '
      'WHERE id = ? AND stock_quantity > 0',
      variables: [Variable(quantity), Variable(productId)],
      updates: {products},
    );
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

  /// Adjust stock by delta (positive = add, negative = remove).
  Future<void> adjustStock(int productId, int delta) async {
    await customUpdate(
      'UPDATE products SET stock_quantity = stock_quantity + ? WHERE id = ?',
      variables: [Variable(delta), Variable(productId)],
      updates: {products},
    );
  }

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
