import 'package:drift/drift.dart';

import 'products_table.dart';
import 'tax_rates_table.dart';

/// Many-to-many: specific tax rates assigned directly to a product.
/// Overrides the category-level and store-level default tax assignment.
class ProductTaxes extends Table {
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get taxRateId => integer().references(TaxRates, #id)();

  @override
  Set<Column> get primaryKey => {productId, taxRateId};
}
