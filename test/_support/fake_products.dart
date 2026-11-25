import 'package:pos_app/core/database/app_database.dart';

/// A plain in-memory [Product] for tests that never touch the database.
Product fakeProduct({
  required int id,
  String? name,
  String? sku,
  double price = 10,
  int stock = 0,
  bool outOfStock = false,
  int? categoryId,
  String? secondaryUnit,
  double conversionRate = 1,
}) =>
    Product(
      id: id,
      sku: sku ?? 'SKU$id',
      name: name ?? 'Item ${id.toString().padLeft(3, '0')}',
      price: price,
      purchasePrice: 0,
      unit: 'pc',
      secondaryUnit: secondaryUnit,
      conversionRate: conversionRate,
      stockQuantity: stock,
      categoryId: categoryId,
      isTaxable: true,
      isComposite: false,
      isHiddenInPos: false,
      isOutOfStock: outOfStock,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
