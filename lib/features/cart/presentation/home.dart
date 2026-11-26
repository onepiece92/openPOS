import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/demo_data_service.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/domain/pos_catalog_provider.dart';
import 'package:pos_app/features/cart/domain/pos_filter_provider.dart';
import 'package:pos_app/features/cart/presentation/widgets/grid_product_tile.dart';
import 'package:pos_app/features/cart/presentation/widgets/checkout_bar.dart';
import 'package:pos_app/features/cart/presentation/widgets/held_tickets_bar.dart';
import 'package:pos_app/features/cart/presentation/widgets/product_tile.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';
import 'package:pos_app/features/usage/usage_providers.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';

/// Main POS screen: product catalog + persistent cart bar at the bottom.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _shortcutsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = ref.read(posFilterProvider).search;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _shortcutsFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _shortcutsFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nothing here watches the cart or the product list: a tap on a tile
    // rebuilds that tile and the checkout bar, not this screen.
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final cs = Theme.of(context).colorScheme;
    final filter = ref.watch(posFilterProvider);
    final filterN = ref.read(posFilterProvider.notifier);

    if (_searchCtrl.text != filter.search) {
      _searchCtrl.text = filter.search;
      _searchCtrl.selection =
          TextSelection.collapsed(offset: _searchCtrl.text.length);
    }

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(
        title: const Text('POS'),
        actions: [
          const _ClearCartButton(),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'products':
                  await context.push('/products');
                case 'orders':
                  await context.push('/orders');
                case 'customers':
                  await context.push('/customers');
                case 'clear_cart':
                  ref.read(cartProvider.notifier).clear();
              }
            },
            itemBuilder: (_) {
              final cartEmpty = ref.read(cartProvider).isEmpty;
              return [
                const PopupMenuItem(
                  value: 'products',
                  child: ListTile(
                    leading: Icon(Icons.inventory_2_outlined),
                    title: Text('Products'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'orders',
                  child: ListTile(
                    leading: Icon(Icons.receipt_long_outlined),
                    title: Text('Order History'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'customers',
                  child: ListTile(
                    leading: Icon(Icons.people_outline_rounded),
                    title: Text('Customers'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (!cartEmpty) ...[
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'clear_cart',
                    child: ListTile(
                      leading: Icon(Icons.remove_shopping_cart_outlined),
                      title: Text('Clear Cart'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ];
            },
          ),
        ],
      ),
      bottomNavigationBar: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeldTicketsBar(),
          CheckoutBar(),
        ],
      ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () {
            _searchFocus.requestFocus();
          },
          const SingleActivator(LogicalKeyboardKey.escape): () {
            filterN.clearSearch();
            _searchCtrl.clear();
            _searchFocus.unfocus();
          },
          const SingleActivator(LogicalKeyboardKey.enter, meta: true): () {
            if (ref.read(cartProvider).isNotEmpty) context.push('/cart');
          },
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
            ref.read(cartProvider.notifier).clear();
          },
          const SingleActivator(LogicalKeyboardKey.keyG, meta: true): () {
            filterN.toggleView();
          },
        },
        child: Focus(
          focusNode: _shortcutsFocus,
          child: Column(
            children: [
              // ── Search bar ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocus,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: filter.search.isNotEmpty
                              ? IconButton(
                                  icon:
                                      const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () {
                                    filterN.clearSearch();
                                    _searchCtrl.clear();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: cs.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        onChanged: (q) {
                          // One count per search, not per keystroke.
                          if (q.isNotEmpty &&
                              ref.read(posFilterProvider).search.isEmpty) {
                            ref
                                .read(usageCounterProvider)
                                .record(UsageEvent.productSearched);
                          }
                          filterN.setSearch(q);
                        },
                      ),
                    ),
                    PopupMenuButton<PosSortMode>(
                      icon: Icon(
                        Icons.sort_rounded,
                        color: filter.sortMode == PosSortMode.mostSold
                            ? cs.onSurfaceVariant
                            : cs.primary,
                      ),
                      tooltip: 'Sort',
                      initialValue: filter.sortMode,
                      onSelected: filterN.setSortMode,
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: PosSortMode.mostSold,
                          child: ListTile(
                            leading: Icon(Icons.trending_up_rounded),
                            title: Text('Most sold'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: PosSortMode.nameAZ,
                          child: ListTile(
                            leading: Icon(Icons.sort_by_alpha_rounded),
                            title: Text('Name A → Z'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: PosSortMode.nameZA,
                          child: ListTile(
                            leading: Icon(Icons.sort_by_alpha_rounded),
                            title: Text('Name Z → A'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: PosSortMode.priceLH,
                          child: ListTile(
                            leading: Icon(Icons.arrow_upward_rounded),
                            title: Text('Price low → high'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: PosSortMode.priceHL,
                          child: ListTile(
                            leading: Icon(Icons.arrow_downward_rounded),
                            title: Text('Price high → low'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(filter.isGrid
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded),
                      tooltip: filter.isGrid ? 'List view' : 'Grid view',
                      onPressed: filterN.toggleView,
                    ),
                  ],
                ),
              ),
              // ── Category chips ─────────────────────────────────────────────
              categoriesAsync.when(
                data: (cats) => _CategoryRow(
                  categories: cats,
                  selected: filter.selectedCategoryId,
                  onSelect: filterN.setCategory,
                  favoritesOnly: filter.favoritesOnly,
                  onToggleFavoritesOnly: filterN.toggleFavoritesOnly,
                  onSelectAll: () {
                    filterN.setCategory(null);
                    if (filter.favoritesOnly) filterN.toggleFavoritesOnly();
                  },
                ),
                loading: () => const SizedBox(height: 44),
                error: (_, __) => const SizedBox.shrink(),
              ),
              // ── Product list ───────────────────────────────────────────────
              const Expanded(child: _ProductArea()),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Clear-cart button ────────────────────────────────────────────────────────

/// The only part of the app bar that cares about the cart, and only about
/// whether it is empty.
class _ClearCartButton extends ConsumerWidget {
  const _ClearCartButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartEmpty = ref.watch(cartProvider.select((c) => c.isEmpty));
    return IconButton(
      icon: const Icon(Icons.remove_shopping_cart_rounded),
      tooltip: 'Clear cart',
      onPressed:
          cartEmpty ? null : () => ref.read(cartProvider.notifier).clear(),
    );
  }
}

// ─── Product area ─────────────────────────────────────────────────────────────

/// Grid or list of the filtered, sorted catalogue. Rebuilds when that list
/// or the grid/list toggle changes — never on a cart change.
class _ProductArea extends ConsumerWidget {
  const _ProductArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(posCatalogProvider);
    final (isGrid, favoritesOnly) =
        ref.watch(posFilterProvider.select((f) => (f.isGrid, f.favoritesOnly)));
    return catalog.when(
      data: (view) {
        if (view.catalogEmpty) {
          return _EmptyProductsState(
            onAddProduct: () => context.push('/products/add'),
          );
        }
        if (view.products.isEmpty) {
          return Center(
            child: Text(
              favoritesOnly
                  ? 'No favorites yet — tap the star on any product'
                  : 'No results',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          );
        }
        return isGrid
            ? _PosProductGrid(products: view.products)
            : _PosProductList(products: view.products);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyProductsState extends ConsumerStatefulWidget {
  const _EmptyProductsState({required this.onAddProduct});
  final VoidCallback onAddProduct;

  @override
  ConsumerState<_EmptyProductsState> createState() =>
      _EmptyProductsStateState();
}

class _EmptyProductsStateState extends ConsumerState<_EmptyProductsState> {
  bool _loading = false;

  Future<void> _loadDemo() async {
    setState(() => _loading = true);
    try {
      await ref.read(demoDataServiceProvider).seed();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 72, color: cs.onSurfaceVariant.withAlpha(80)),
            const SizedBox(height: 16),
            Text(
              'No products yet',
              style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              kDebugMode
                  ? 'Add your first product or load demo data\nto explore all features.'
                  : 'Add your first product to get started.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: widget.onAddProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Product'),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : OutlinedButton.icon(
                      onPressed: _loadDemo,
                      icon: const Icon(Icons.dataset_rounded),
                      label: const Text('Load Demo Data'),
                    ),
            ],
            if (kDebugMode && !_loading) ...[
              const SizedBox(height: 8),
              Text(
                '6 categories · 46 bakery products · 5 customers',
                style: tt.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant.withAlpha(140)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Category row ─────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.favoritesOnly,
    required this.onToggleFavoritesOnly,
    required this.onSelectAll,
  });
  final List<Category> categories;
  final int? selected;
  final ValueChanged<int?> onSelect;
  final bool favoritesOnly;
  final VoidCallback onToggleFavoritesOnly;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            _Chip(
              label: '★',
              selected: favoritesOnly,
              onTap: onToggleFavoritesOnly,
            ),
            _Chip(
              label: 'All',
              selected: selected == null && !favoritesOnly,
              onTap: onSelectAll,
            ),
            ...categories.map((c) => _Chip(
                  label: c.name,
                  selected: selected == c.id,
                  onTap: () => onSelect(selected == c.id ? null : c.id),
                )),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
}

// ─── POS product grid ─────────────────────────────────────────────────────────

class _PosProductGrid extends StatelessWidget {
  const _PosProductGrid({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => GridProductTile(product: products[i]),
    );
  }
}

// ─── POS product list ─────────────────────────────────────────────────────────

class _PosProductList extends StatelessWidget {
  const _PosProductList({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      itemCount: products.length,
      separatorBuilder: (_, i) => _ListSeparator(
        productId: products[i].id,
        nextProductId: products[i + 1 < products.length ? i + 1 : i].id,
      ),
      itemBuilder: (_, i) => PosProductTile(product: products[i]),
    );
  }
}

/// A hairline between two rows, replaced by a small gap when either row is
/// highlighted as in the cart. Watches just that one fact.
class _ListSeparator extends ConsumerWidget {
  const _ListSeparator({required this.productId, required this.nextProductId});
  final int productId;
  final int nextProductId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eitherInCart = ref.watch(cartMainUnitQtyProvider.select(
        (qty) => (qty[productId] ?? 0) > 0 || (qty[nextProductId] ?? 0) > 0));
    if (eitherInCart) return const SizedBox(height: 2);
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color:
          Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}
