import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/cart/domain/cart_notifier.dart';
import 'package:pos_app/features/cart/domain/held_orders_notifier.dart';

/// Stream of every defined table, ordered by name.
final tablesStreamProvider = StreamProvider<List<PosTable>>((ref) {
  return ref.watch(databaseProvider).tablesDao.watchAll();
});

/// Resolves the full PosTable for the cart session's selected table, if any.
final cartTableProvider = Provider<PosTable?>((ref) {
  final tableId = ref.watch(cartSessionProvider).tableId;
  if (tableId == null) return null;
  final tables = ref.watch(tablesStreamProvider).valueOrNull ?? [];
  try {
    return tables.firstWhere((t) => t.id == tableId);
  } catch (_) {
    return null;
  }
});

/// Set of table IDs currently in use — i.e. either:
///   - referenced by the active in-progress cart session, OR
///   - referenced by any active (non-archived) held order
final occupiedTableIdsProvider = Provider<Set<int>>((ref) {
  final activeHeld = ref.watch(activeHeldOrdersProvider);
  final cartTableId = ref.watch(cartSessionProvider).tableId;
  return {
    for (final t in activeHeld)
      if (t.tableId != null) t.tableId!,
    if (cartTableId != null) cartTableId,
  };
});
