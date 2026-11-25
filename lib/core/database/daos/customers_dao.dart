import 'package:drift/drift.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/tables/customers_table.dart';

part 'customers_dao.g.dart';

@DriftAccessor(tables: [Customers])
class CustomersDao extends DatabaseAccessor<AppDatabase>
    with _$CustomersDaoMixin {
  CustomersDao(super.db);

  Stream<List<Customer>> watchAll() => select(customers).watch();

  Future<List<Customer>> getAll() => select(customers).get();

  Future<List<Customer>> search(String query) {
    final term = '%$query%';
    return (select(customers)
          ..where(
            (c) => c.name.like(term) | c.phone.like(term) | c.email.like(term),
          ))
        .get();
  }

  /// Names of just [ids] (one indexed query), for showing stored orders'
  /// customers without loading or watching the whole list.
  Future<Map<int, String>> namesFor(Iterable<int> ids) async {
    final list = ids.toSet();
    if (list.isEmpty) return const {};
    final q = selectOnly(customers)
      ..addColumns([customers.id, customers.name])
      ..where(customers.id.isIn(list));
    return {
      for (final r in await q.get())
        r.read(customers.id)!: r.read(customers.name)!,
    };
  }

  Future<Customer?> getById(int id) =>
      (select(customers)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> upsert(CustomersCompanion entry) =>
      into(customers).insertOnConflictUpdate(entry);

  Future<void> addLoyaltyPoints(int customerId, int points) async {
    await customUpdate(
      'UPDATE customers SET loyalty_points = loyalty_points + ? WHERE id = ?',
      variables: [Variable(points), Variable(customerId)],
      updates: {customers},
    );
  }

  Future<void> redeemLoyaltyPoints(int customerId, int points) async {
    await customUpdate(
      'UPDATE customers SET loyalty_points = MAX(0, loyalty_points - ?) WHERE id = ?',
      variables: [Variable(points), Variable(customerId)],
      updates: {customers},
    );
  }
}
