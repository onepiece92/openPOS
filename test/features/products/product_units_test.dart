import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/tables/products_table.dart' show Products;

import '../../_support/test_db.dart';

/// Covers the v9 product columns: purchase price + main/secondary units.
void main() {
  late AppDatabase db;

  setUp(() => db = openInMemoryDatabase());
  tearDown(() => db.close());

  test('new columns fall back to sensible defaults', () async {
    final id = await db.productsDao.upsert(
      ProductsCompanion.insert(sku: 'PLAIN', name: 'Plain', price: 5),
    );
    final p = (await db.productsDao.getById(id))!;
    expect(p.purchasePrice, 0.0);
    expect(p.unit, 'pcs');
    expect(p.secondaryUnit, isNull);
    expect(p.conversionRate, 1.0);
  });

  test('purchase price and units round-trip through insert + update', () async {
    final id = await db.productsDao.upsert(
      ProductsCompanion.insert(
        sku: 'EGGS',
        name: 'Eggs',
        price: 1.5,
        purchasePrice: const Value(0.9),
        unit: const Value('pc'),
        secondaryUnit: const Value('dozen'),
        conversionRate: const Value(12),
      ),
    );
    var p = (await db.productsDao.getById(id))!;
    expect(p.purchasePrice, 0.9);
    expect(p.unit, 'pc');
    expect(p.secondaryUnit, 'dozen');
    expect(p.conversionRate, 12);

    // Editing can clear the secondary unit and reset conversion.
    await db.productsDao.updateProduct(
      id,
      const ProductsCompanion(
        purchasePrice: Value(1.1),
        unit: Value('kg'),
        secondaryUnit: Value(null),
        conversionRate: Value(1),
      ),
    );
    p = (await db.productsDao.getById(id))!;
    expect(p.purchasePrice, 1.1);
    expect(p.unit, 'kg');
    expect(p.secondaryUnit, isNull);
    expect(p.conversionRate, 1);
  });

  test('schema is current and products table exposes the unit columns', () {
    expect(db.schemaVersion, AppDatabase.currentSchemaVersion);
    final cols = db.products.$columns.map((c) => c.name).toSet();
    expect(cols, containsAll(['purchase_price', 'unit', 'secondary_unit', 'conversion_rate']));
    // Keep the import used so this test stays a compile-time guard on the table class.
    expect(Products, isNotNull);
  });
}
