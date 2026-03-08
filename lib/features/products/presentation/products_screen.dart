import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  int? _selectedCategoryId;
  String _search = '';
  bool _showSearch = false;
  bool _outOfStockOnly = false;
  bool _sortAZ = true;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> _applyFilter(List<Product> all) {
    var list = _selectedCategoryId == null
        ? all
        : all.where((p) => p.categoryId == _selectedCategoryId).toList();
    if (_outOfStockOnly) {
      list = list.where((p) => p.stockQuantity <= 0).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q))
          .toList();
    }
    list.sort((a, b) =>
        _sortAZ ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _search = v),
              )
            : const Text('Products'),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
            ),
            tooltip: _showSearch ? 'Close search' : 'Search',
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _search = '';
                _searchCtrl.clear();
              }
            }),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'categories':
                  context.push('/categories');
                case 'tax':
                  context.push('/tax');
                case 'sort':
                  setState(() => _sortAZ = !_sortAZ);
                case 'outofstock':
                  setState(() => _outOfStockOnly = !_outOfStockOnly);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'categories',
                child: ListTile(
                  leading: Icon(Icons.category_rounded),
                  title: Text('Manage Categories'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'tax',
                child: ListTile(
                  leading: Icon(Icons.percent_rounded),
                  title: Text('Manage Tax Rates'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'sort',
                child: ListTile(
                  leading: Icon(
                    _sortAZ
                        ? Icons.sort_by_alpha_rounded
                        : Icons.sort_rounded,
                  ),
                  title: Text(_sortAZ ? 'Sort: A → Z' : 'Sort: Z → A'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'outofstock',
                child: ListTile(
                  leading: Icon(
                    _outOfStockOnly
                        ? Icons.inventory_2_rounded
                        : Icons.warning_amber_rounded,
                    color: _outOfStockOnly ? null : cs.error,
                  ),
                  title: Text(
                    _outOfStockOnly
                        ? 'Show All Products'
                        : 'Out of Stock Only',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Category filter chips ────────────────────────────────────────
          categoriesAsync.when(
            data: (cats) => _CategoryChips(
              categories: cats,
              selected: _selectedCategoryId,
              onSelect: (id) => setState(() => _selectedCategoryId = id),
            ),
            loading: () => const SizedBox(height: 48),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // ── Active filter indicator ──────────────────────────────────────
          if (_outOfStockOnly)
            Container(
              width: double.infinity,
              color: cs.errorContainer.withValues(alpha: 0.5),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: cs.onErrorContainer),
                  const SizedBox(width: 6),
                  Text(
                    'Showing out-of-stock only',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _outOfStockOnly = false),
                    child: Icon(Icons.close_rounded,
                        size: 14, color: cs.onErrorContainer),
                  ),
                ],
              ),
            ),
          // ── Product list ─────────────────────────────────────────────────
          Expanded(
            child: productsAsync.when(
              data: (all) {
                final catMap = <int?, String>{
                  for (final c in categoriesAsync.valueOrNull ?? [])
                    c.id: c.name
                };
                final filtered = _applyFilter(all);

                if (all.isEmpty) {
                  return _EmptyState(
                      onAdd: () => context.push('/products/add'));
                }
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No products match your search.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) => _ProductTile(
                    product: filtered[i],
                    categoryName: catMap[filtered[i].categoryId],
                    currencySymbol: symbol,
                    onTap: () =>
                        context.push('/products/${filtered[i].id}'),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/products/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
      ),
    );
  }
}

// ── Category filter chips ─────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });
  final List<Category> categories;
  final int? selected;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _Chip(
              label: 'All',
              selected: selected == null,
              onTap: () => onSelect(null)),
          ...categories.map((c) => _Chip(
                label: c.name,
                selected: selected == c.id,
                onTap: () => onSelect(c.id),
              )),
        ],
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
        ),
      );
}

// ── Product list tile ─────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.currencySymbol,
    required this.onTap,
    this.categoryName,
  });
  final Product product;
  final String? categoryName;
  final String currencySymbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final outOfStock = product.stockQuantity <= 0;
    final lowStock = product.stockQuantity <= 5 && !outOfStock;

    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.inventory_2_rounded,
          size: 22,
          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
      title: Text(
        product.name,
        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (categoryName != null) ...[
            Text(
              categoryName!,
              style: tt.labelSmall
                  ?.copyWith(color: cs.primary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 6),
            Text('·',
                style: tt.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(width: 6),
          ],
          Text(
            'SKU: ${product.sku}',
            style:
                tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currencySymbol ${product.price.toStringAsFixed(2)}',
                style: tt.bodyMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              _StockBadge(
                qty: product.stockQuantity,
                lowStock: lowStock,
                outOfStock: outOfStock,
                cs: cs,
                tt: tt,
              ),
            ],
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}

// ── Stock badge ───────────────────────────────────────────────────────────────

class _StockBadge extends StatelessWidget {
  const _StockBadge({
    required this.qty,
    required this.lowStock,
    required this.outOfStock,
    required this.cs,
    required this.tt,
  });
  final int qty;
  final bool lowStock;
  final bool outOfStock;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    if (outOfStock) {
      bg = cs.errorContainer;
      fg = cs.onErrorContainer;
      label = 'Out of stock';
    } else if (lowStock) {
      bg = cs.tertiaryContainer;
      fg = cs.onTertiaryContainer;
      label = '$qty left';
    } else {
      bg = cs.secondaryContainer;
      fg = cs.onSecondaryContainer;
      label = '$qty in stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: tt.labelSmall?.copyWith(color: fg)),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 72,
              color: cs.onSurfaceVariant.withValues(alpha: 0.31)),
          const SizedBox(height: 16),
          Text('No products yet',
              style:
                  tt.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Add your first product to get started.',
              style:
                  tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Product'),
          ),
        ],
      ),
    );
  }
}
