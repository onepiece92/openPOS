import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/shared/widgets/app_empty_state.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/inventory/presentation/widgets/inventory_card.dart';
import 'package:pos_app/features/inventory/presentation/widgets/inventory_filter_bar.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _search = '';
  // null = all, 'low' = low stock, 'out' = out of stock
  String? _filter;
  bool _sortAZ = true;
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> _filtered(List<Product> all, int threshold) {
    var list = switch (_filter) {
      'out' => all
          .where((p) => p.isOutOfStock || p.stockQuantity < 0)
          .toList(),
      'low' => all
          .where((p) =>
              !p.isOutOfStock &&
              p.stockQuantity > 0 &&
              p.stockQuantity <= threshold)
          .toList(),
      _ => all,
    };
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
    final threshold = ref.watch(lowStockThresholdProvider);
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
            : const Text('Inventory'),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
            ),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _search = '';
                _searchCtrl.clear();
              }
            }),
          ),
          IconButton(
            icon: Icon(
              Icons.sort_by_alpha_rounded,
              color: cs.onSurfaceVariant,
            ),
            tooltip: _sortAZ ? 'Sort Z→A' : 'Sort A→Z',
            onPressed: () => setState(() => _sortAZ = !_sortAZ),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (all) {
          if (all.isEmpty) {
            return const AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products yet',
            );
          }

          final outCount = all
              .where((p) => p.isOutOfStock || p.stockQuantity < 0)
              .length;
          final lowCount = all
              .where((p) =>
                  !p.isOutOfStock &&
                  p.stockQuantity > 0 &&
                  p.stockQuantity <= threshold)
              .length;
          final filtered = _filtered(all, threshold);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Filter chips ─────────────────────────────────────────────
              InventoryFilterBar(
                total: all.length,
                outCount: outCount,
                lowCount: lowCount,
                selected: _filter,
                onSelect: (v) => setState(() => _filter = v),
              ),
              // ── List ─────────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No products match.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => InventoryCard(
                          product: filtered[i],
                          threshold: threshold,
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────────
