import 'package:drift/drift.dart';

import 'package:pos_app/core/database/tables/tax_groups_table.dart';
import 'package:pos_app/core/database/tables/tax_rates_table.dart';

/// Join table: which tax rates belong to which tax group.
class TaxGroupMembers extends Table {
  IntColumn get groupId => integer().references(TaxGroups, #id)();
  IntColumn get taxRateId => integer().references(TaxRates, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {groupId, taxRateId};
}
