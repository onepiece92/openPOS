import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/product_taxes_table.dart';
import '../tables/tax_group_members_table.dart';
import '../tables/tax_groups_table.dart';
import '../tables/tax_rates_table.dart';

part 'tax_dao.g.dart';

@DriftAccessor(
  tables: [TaxRates, TaxGroups, TaxGroupMembers, ProductTaxes],
)
class TaxDao extends DatabaseAccessor<AppDatabase> with _$TaxDaoMixin {
  TaxDao(super.db);

  Stream<List<TaxRate>> watchActive() =>
      (select(taxRates)..where((t) => t.isActive.equals(true))).watch();

  Future<List<TaxRate>> getAll() => select(taxRates).get();

  Future<TaxRate?> getById(int id) =>
      (select(taxRates)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<TaxRate>> getRatesForProduct(int productId) async {
    final joins = await (select(productTaxes)
          ..where((pt) => pt.productId.equals(productId)))
        .get();
    if (joins.isEmpty) return [];
    final ids = joins.map((j) => j.taxRateId).toList();
    return (select(taxRates)..where((t) => t.id.isIn(ids))).get();
  }

  Future<int> upsertRate(TaxRatesCompanion entry) =>
      into(taxRates).insertOnConflictUpdate(entry);

  Future<void> setProductTaxes(
    int productId,
    List<int> taxRateIds,
  ) async {
    await (delete(productTaxes)
          ..where((pt) => pt.productId.equals(productId)))
        .go();
    await batch((b) {
      b.insertAll(
        productTaxes,
        taxRateIds.map(
          (rId) => ProductTaxesCompanion.insert(
            productId: productId,
            taxRateId: rId,
          ),
        ),
      );
    });
  }
}
