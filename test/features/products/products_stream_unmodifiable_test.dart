import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

import '../../_support/test_db.dart';

/// Several screens read the one list held by productsStreamProvider. It is
/// handed out unmodifiable, so a screen that sorts or edits it in place
/// fails at once instead of quietly reordering the others.
void main() {
  test('the list from productsStreamProvider cannot be changed in place',
      () async {
    final db = openInMemoryDatabase();
    final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() async {
      c.dispose();
      await db.close();
    });
    for (final name in ['Mango', 'Apple']) {
      await db.productsDao.upsert(
          ProductsCompanion.insert(sku: name, name: name, price: 1));
    }
    c.listen(productsStreamProvider, (_, __) {});
    final list = await c.read(productsStreamProvider.future);

    expect(list.map((p) => p.name), ['Mango', 'Apple']);
    expect(() => list.sort((a, b) => a.name.compareTo(b.name)),
        throwsUnsupportedError);
    expect(list.clear, throwsUnsupportedError);
    expect(() => list.removeAt(0), throwsUnsupportedError);

    // Still live: a later change arrives as another unmodifiable list.
    await db.productsDao.upsert(
        ProductsCompanion.insert(sku: 'Kiwi', name: 'Kiwi', price: 1));
    await Future<void>.delayed(Duration.zero);
    await pumpEventQueue();
    final next = c.read(productsStreamProvider).requireValue;
    expect(next, hasLength(3));
    expect(() => next.sort((a, b) => a.name.compareTo(b.name)),
        throwsUnsupportedError);
  });
}
