import 'package:pos_app/core/database/app_database.dart' show Product;

/// True when [product] is tracked, still in stock, and at or under the
/// shop's low-stock [threshold] (Settings → Inventory). A stock of 0 means
/// "not tracked", so it is never low.
bool isLowStock(Product product, int threshold) =>
    !product.isOutOfStock &&
    product.stockQuantity > 0 &&
    product.stockQuantity <= threshold;
