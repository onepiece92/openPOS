import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
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
      'out' => all.where((p) => p.stockQuantity <= 0).toList(),
      'low' =>
        all.where((p) => p.stockQuantity > 0 && p.stockQuantity <= threshold).toList(),
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
          if (all.isEmpty) return const _EmptyState();

          final outCount = all.where((p) => p.stockQuantity <= 0).length;
          final lowCount = all
              .where(
                  (p) => p.stockQuantity > 0 && p.stockQuantity <= threshold)
              .length;
          final filtered = _filtered(all, threshold);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Filter chips ─────────────────────────────────────────────
              _FilterBar(
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
                          style:
                              TextStyle(color: cs.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) => _InventoryCard(
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.total,
    required this.outCount,
    required this.lowCount,
    required this.selected,
    required this.onSelect,
  });

  final int total;
  final int outCount;
  final int lowCount;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        spacing: 8,
        children: [
          _Chip(
            label: 'All ($total)',
            selected: selected == null,
            color: cs.primary,
            onTap: () => onSelect(null),
          ),
          _Chip(
            label: 'Low ($lowCount)',
            selected: selected == 'low',
            color: const Color(0xFFD97706),
            onTap: () => onSelect(selected == 'low' ? null : 'low'),
          ),
          _Chip(
            label: 'Out ($outCount)',
            selected: selected == 'out',
            color: cs.error,
            onTap: () => onSelect(selected == 'out' ? null : 'out'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? color
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─── Inventory card ───────────────────────────────────────────────────────────

class _InventoryCard extends ConsumerWidget {
  const _InventoryCard({
    required this.product,
    required this.threshold,
  });

  final Product product;
  final int threshold;

  Color _badgeColor(ColorScheme cs) {
    if (product.stockQuantity <= 0) return cs.error;
    if (product.stockQuantity <= threshold) return const Color(0xFFD97706);
    return cs.primary;
  }

  Future<void> _nudge(WidgetRef ref, int delta) async {
    final db = ref.read(databaseProvider);
    final newQty = (product.stockQuantity + delta).clamp(0, 999999);
    await db.productsDao.setStock(product.id, newQty);
    await db.inventoryDao.logAdjustment(
      StockAdjustmentsCompanion.insert(
        productId: product.id,
        delta: delta,
        reasonCode: delta > 0 ? 'manual_add' : 'manual_remove',
      ),
    );
  }

  Future<void> _setAbsolute(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(
        text: product.stockQuantity > 0
            ? product.stockQuantity.toString()
            : '');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'New stock quantity',
            border: OutlineInputBorder(),
            suffixText: 'units',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(ctrl.text)),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null) return;

    final db = ref.read(databaseProvider);
    final delta = result - product.stockQuantity;
    await db.productsDao.setStock(product.id, result);
    if (delta != 0) {
      await db.inventoryDao.logAdjustment(
        StockAdjustmentsCompanion.insert(
          productId: product.id,
          delta: delta,
          reasonCode: 'manual_set',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final badgeColor = _badgeColor(cs);
    final qty = product.stockQuantity;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: [
            // Product initial avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                product.name[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + SKU
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    product.sku,
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Inline stepper ── [−] [qty] [+]
            _StepperRow(
              qty: qty,
              badgeColor: badgeColor,
              onDecrement: () => _nudge(ref, -1),
              onIncrement: () => _nudge(ref, 1),
              onQtyTap: () => _setAbsolute(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stepper row ──────────────────────────────────────────────────────────────

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.qty,
    required this.badgeColor,
    required this.onDecrement,
    required this.onIncrement,
    required this.onQtyTap,
  });

  final int qty;
  final Color badgeColor;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onQtyTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decrement
        _StepBtn(
          icon: Icons.remove_rounded,
          onTap: qty > 0 ? onDecrement : null,
          cs: cs,
        ),
        // Quantity tappable badge
        GestureDetector(
          onTap: onQtyTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 44),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: badgeColor.withValues(alpha: 0.3), width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              qty <= 0 ? 'Out' : '$qty',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: badgeColor,
              ),
            ),
          ),
        ),
        // Increment
        _StepBtn(
          icon: Icons.add_rounded,
          onTap: onIncrement,
          cs: cs,
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.onTap,
    required this.cs,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 16),
        color: onTap == null ? cs.onSurfaceVariant.withValues(alpha: 0.3) : cs.primary,
        onPressed: onTap,
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 72, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'No products yet',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
