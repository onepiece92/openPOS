import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/customers_table.dart';

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
