import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PosSortMode { mostSold, nameAZ, nameZA, priceLH, priceHL }

class PosFilterState {
  const PosFilterState({
    this.sortMode = PosSortMode.mostSold,
    this.selectedCategoryId,
    this.isGrid = true,
    this.search = '',
  });

  final PosSortMode sortMode;
  final int? selectedCategoryId;
  final bool isGrid;
  final String search;

  PosFilterState copyWith({
    PosSortMode? sortMode,
    int? selectedCategoryId,
    bool clearCategory = false,
    bool? isGrid,
    String? search,
  }) =>
      PosFilterState(
        sortMode: sortMode ?? this.sortMode,
        selectedCategoryId: clearCategory
            ? null
            : (selectedCategoryId ?? this.selectedCategoryId),
        isGrid: isGrid ?? this.isGrid,
        search: search ?? this.search,
      );
}

class PosFilterNotifier extends StateNotifier<PosFilterState> {
  PosFilterNotifier() : super(const PosFilterState());

  void setSortMode(PosSortMode m) => state = state.copyWith(sortMode: m);
  void setCategory(int? id) => id == null
      ? state = state.copyWith(clearCategory: true)
      : state = state.copyWith(selectedCategoryId: id);
  void toggleView() => state = state.copyWith(isGrid: !state.isGrid);
  void setSearch(String q) => state = state.copyWith(search: q);
  void clearSearch() => state = state.copyWith(search: '');
}

final posFilterProvider =
    StateNotifierProvider<PosFilterNotifier, PosFilterState>(
  (_) => PosFilterNotifier(),
);
