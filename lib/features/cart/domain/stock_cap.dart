import 'package:pos_app/core/database/app_database.dart' show Product;

/// The most main units of [product] a cart may hold, or null for no limit.
///
/// - flagged out of stock (or a negative count) → 0, nothing can be added
/// - a positive count → that count
/// - 0 and not flagged → untracked, unlimited
int? stockCapFor(Product product) {
  if (product.isOutOfStock || product.stockQuantity < 0) return 0;
  if (product.stockQuantity > 0) return product.stockQuantity;
  return null;
}
