import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/audit/presentation/audit_log_screen.dart';
import 'package:pos_app/features/expenses/presentation/expenses_screen.dart';
import 'package:pos_app/features/orders/domain/order_history.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

import '../../_support/test_db.dart';

/// Providers owned by one screen must stop (and so stop re-querying on
/// every database write) once that screen is gone, while the providers the
/// sell screen relies on between sales stay alive.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = openInMemoryDatabase();
    container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  final screenScoped = <String, ProviderListenable<Object?>>{
    'order history': orderHistoryProvider,
    'audit log': auditLogsProvider,
    'expenses': expensesStreamProvider,
    'expense categories': expenseCategoriesStreamProvider,
    'products of one category': productsByCategoryProvider(1),
    'most-sold counts': productSalesCountProvider,
  };

  for (final entry in screenScoped.entries) {
    test('${entry.key} is disposed when its screen stops listening',
        () async {
      final provider = entry.value as ProviderBase<Object?>;
      final screen = container.listen(provider, (_, __) {});
      await pumpEventQueue();
      expect(container.exists(provider), isTrue);

      screen.close();
      await pumpEventQueue();
      expect(container.exists(provider), isFalse);
    });
  }

  test('what the sell screen needs between sales is kept alive', () async {
    final kept = <ProviderBase<Object?>>[
      productsStreamProvider,
      categoriesStreamProvider,
      taxRatesStreamProvider,
    ];
    for (final provider in kept) {
      final screen = container.listen(provider, (_, __) {});
      await pumpEventQueue();
      screen.close();
      await pumpEventQueue();
      expect(container.exists(provider), isTrue, reason: '$provider');
    }
  });
}
