import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';

final customersStreamProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(databaseProvider).customersDao.watchAll();
});

/// Names for the customer ids in [key] (sorted ids joined by ','), read once.
/// Used where history shows stored customers while the Customers feature is
/// switched off: stored data stays visible, but nothing is watched.
final customerNamesProvider = FutureProvider.autoDispose
    .family<Map<int, String>, String>((ref, key) {
  if (key.isEmpty) return const {};
  return ref
      .watch(databaseProvider)
      .customersDao
      .namesFor(key.split(',').map(int.parse));
});

/// The [customerNamesProvider] key for [ids].
String customerNamesKey(Iterable<int?> ids) =>
    ({for (final id in ids) if (id != null) id}.toList()..sort()).join(',');

/// Resolves the name of the customer currently assigned to the cart session.
final cartCustomerNameProvider = Provider<String?>((ref) {
  final customerId = ref.watch(cartSessionProvider).customerId;
  if (customerId == null) return null;
  final customers = ref.watch(customersStreamProvider).valueOrNull ?? [];
  try {
    return customers.firstWhere((c) => c.id == customerId).name;
  } catch (_) {
    return null;
  }
});

/// Resolves the full Customer object for the cart session's selected customer.
final cartCustomerProvider = Provider<Customer?>((ref) {
  final customerId = ref.watch(cartSessionProvider).customerId;
  if (customerId == null) return null;
  final customers = ref.watch(customersStreamProvider).valueOrNull ?? [];
  try {
    return customers.firstWhere((c) => c.id == customerId);
  } catch (_) {
    return null;
  }
});
