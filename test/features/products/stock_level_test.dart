import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/products/domain/stock_level.dart';

Product product({required int stock, bool outOfStock = false}) => Product(
      id: 1,
      sku: 'A',
      name: 'A',
      price: 1,
      purchasePrice: 0,
      unit: 'pcs',
      conversionRate: 1,
      stockQuantity: stock,
      isTaxable: true,
      isComposite: false,
      isHiddenInPos: false,
      isOutOfStock: outOfStock,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  test('low stock follows the shop setting, not a fixed 5', () {
    expect(isLowStock(product(stock: 8), 10), isTrue);
    expect(isLowStock(product(stock: 10), 10), isTrue);
    expect(isLowStock(product(stock: 11), 10), isFalse);
    expect(isLowStock(product(stock: 4), 2), isFalse);
    expect(isLowStock(product(stock: 2), 2), isTrue);
  });

  test('untracked (0) and out-of-stock products are not "low"', () {
    expect(isLowStock(product(stock: 0), 10), isFalse);
    expect(isLowStock(product(stock: 3, outOfStock: true), 10), isFalse);
    expect(isLowStock(product(stock: -1), 10), isFalse);
  });
}
