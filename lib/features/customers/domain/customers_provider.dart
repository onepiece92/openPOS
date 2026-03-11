import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/cart/domain/cart_notifier.dart';

final customersStreamProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(databaseProvider).customersDao.watchAll();
});

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
