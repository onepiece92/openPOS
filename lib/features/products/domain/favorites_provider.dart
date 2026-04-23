import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/providers/hive_provider.dart';

const _kFavoriteProductIds = 'favorite_product_ids';

class FavoritesNotifier extends StateNotifier<Set<int>> {
  FavoritesNotifier(this._box)
      : super({
          ...(_box.get(_kFavoriteProductIds, defaultValue: const <int>[])
                  as List)
              .cast<int>(),
        });

  final Box<dynamic> _box;

  Future<void> toggle(int productId) async {
    final next = Set<int>.from(state);
    if (!next.add(productId)) next.remove(productId);
    state = next;
    await _box.put(_kFavoriteProductIds, next.toList());
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<int>>((ref) {
  return FavoritesNotifier(ref.watch(settingsBoxProvider));
});
