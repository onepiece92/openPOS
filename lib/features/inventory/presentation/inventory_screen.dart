import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _search = '';
  bool _showSearch = false;
  bool _lowStockOnly = false;
  bool _sortAZ = true;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> _filter(List<Product> all, int threshold) {
    var list = _lowStockOnly
        ? all.where((p) => p.stockQuantity <= threshold).toList()
        : all;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.sku.toLowerCase().contains(q),
          )
          .toList();
    }
    list.sort((a, b) =>
        _sortAZ ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
    return list;
  }

  void _showAdjustDialog(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AdjustStockSheet(product: product),
    );
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
              Icons.warning_amber_rounded,
              color: _lowStockOnly ? cs.error : cs.onSurfaceVariant,
            ),
            tooltip: _lowStockOnly ? 'Show all' : 'Low stock only',
            onPressed: () => setState(() => _lowStockOnly = !_lowStockOnly),
          ),
          IconButton(
            icon: const Icon(Icons.sort_by_alpha_rounded),
            tooltip: _sortAZ ? 'Sort Z→A' : 'Sort A→Z',
            onPressed: () => setState(() => _sortAZ = !_sortAZ),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (all) {
          final filtered = _filter(all, threshold);

          if (all.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 72,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          if (filtered.isEmpty) {
            return Center(
              child: Text(
                'No products match your filter.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            );
          }

          final outCount = all.where((p) => p.stockQuantity <= 0).length;
          final lowCount = all
              .where((p) => p.stockQuantity > 0 && p.stockQuantity <= threshold)
              .length;

          return Column(
            children: [
              _SummaryBar(
                total: all.length,
                outOfStock: outCount,
                lowStock: lowCount,
                cs: cs,
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16),
                  itemBuilder: (_, i) => _InventoryTile(
                    product: filtered[i],
                    threshold: threshold,
                    onAdjust: () => _showAdjustDialog(filtered[i]),
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

// ── Summary bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.total,
    required this.outOfStock,
    required this.lowStock,
    required this.cs,
  });

  final int total;
  final int outOfStock;
  final int lowStock;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: cs.surfaceContainerLow,
      child: Row(
        children: [
          _StatChip(label: 'Total', value: '$total', color: cs.primary),
          const SizedBox(width: 16),
          _StatChip(
            label: 'Low Stock',
            value: '$lowStock',
            color: const Color(0xFFD97706),
          ),
          const SizedBox(width: 16),
          _StatChip(
            label: 'Out of Stock',
            value: '$outOfStock',
            color: cs.error,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ── Inventory tile ─────────────────────────────────────────────────────────────

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.product,
    required this.threshold,
    required this.onAdjust,
  });

  final Product product;
  final int threshold;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final outOfStock = product.stockQuantity <= 0;
    final lowStock = !outOfStock && product.stockQuantity <= threshold;

    final Color badgeColor;
    final Color badgeFg;
    final String badgeLabel;

    if (outOfStock) {
      badgeColor = cs.errorContainer;
      badgeFg = cs.onErrorContainer;
      badgeLabel = 'Out';
    } else if (lowStock) {
      badgeColor = const Color(0xFFFEF3C7);
      badgeFg = const Color(0xFF92400E);
      badgeLabel = '${product.stockQuantity} low';
    } else {
      badgeColor = cs.secondaryContainer;
      badgeFg = cs.onSecondaryContainer;
      badgeLabel = '${product.stockQuantity} in stock';
    }

    return ListTile(
      title: Text(product.name, style: tt.bodyLarge),
      subtitle: Text(
        product.sku,
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeLabel,
              style: tt.labelSmall?.copyWith(
                color: badgeFg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Adjust stock',
            onPressed: onAdjust,
          ),
        ],
      ),
    );
  }
}

// ── Adjust stock sheet ────────────────────────────────────────────────────────

class _AdjustStockSheet extends ConsumerStatefulWidget {
  const _AdjustStockSheet({required this.product});
  final Product product;

  @override
  ConsumerState<_AdjustStockSheet> createState() => _AdjustStockSheetState();
}

class _AdjustStockSheetState extends ConsumerState<_AdjustStockSheet> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _mode = 'add'; // 'add' | 'remove' | 'set'
  bool _loading = false;
  bool _showLog = false;
  List<StockAdjustment> _log = [];

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  Future<void> _loadLog() async {
    final db = ref.read(databaseProvider);
    final entries = await db.inventoryDao
        .getAdjustmentsForProduct(widget.product.id);
    if (mounted) setState(() => _log = entries);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  int get _currentQty => widget.product.stockQuantity;
  int? get _parsed => int.tryParse(_amountCtrl.text);

  int get _previewQty {
    final d = _parsed ?? 0;
    return switch (_mode) {
      'add' => _currentQty + d,
      'remove' => (_currentQty - d).clamp(0, 999999),
      _ => d,
    };
  }

  Future<void> _apply() async {
    final d = _parsed;
    if (d == null || d < 0) return;
    setState(() => _loading = true);

    final db = ref.read(databaseProvider);
    final delta = switch (_mode) {
      'add' => d,
      'remove' => -d,
      _ => _previewQty - _currentQty,
    };
    final newQty = (_currentQty + delta).clamp(0, 999999);

    await db.productsDao.upsert(
      ProductsCompanion(
        id: Value(widget.product.id),
        stockQuantity: Value(newQty),
      ),
    );

    await db.inventoryDao.logAdjustment(
      StockAdjustmentsCompanion.insert(
        productId: widget.product.id,
        delta: delta,
        reasonCode:
            _notesCtrl.text.trim().isEmpty ? _mode : _notesCtrl.text.trim(),
      ),
    );

    if (mounted) {
      setState(() => _loading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Adjust Stock',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.product.name} · Current: $_currentQty units',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'add',
                label: Text('Add'),
                icon: Icon(Icons.add),
              ),
              ButtonSegment(
                value: 'remove',
                label: Text('Remove'),
                icon: Icon(Icons.remove),
              ),
              ButtonSegment(
                value: 'set',
                label: Text('Set'),
                icon: Icon(Icons.edit_rounded),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() {
              _mode = s.first;
              _amountCtrl.clear();
            }),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _mode == 'set' ? 'New quantity' : 'Amount',
              border: const OutlineInputBorder(),
              suffixText: 'units',
            ),
          ),
          const SizedBox(height: 12),

          if (_parsed != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'New stock: $_previewQty units',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _previewQty <= 0 ? cs.error : cs.primary,
                ),
              ),
            ),

          const SizedBox(height: 12),

          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Reason / notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: (_loading || _parsed == null) ? null : _apply,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Apply Adjustment'),
          ),

          if (_log.isNotEmpty) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => setState(() => _showLog = !_showLog),
              child: Row(
                children: [
                  Text(
                    'Adjustment History (${_log.length})',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showLog
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: cs.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (_showLog) ...[
              const SizedBox(height: 8),
              ...(_log.take(20).map((adj) {
                final sign = adj.delta >= 0 ? '+' : '';
                final color = adj.delta >= 0 ? cs.primary : cs.error;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '$sign${adj.delta}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          adj.reasonCode,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
                      Text(
                        '${adj.createdAt.day}/${adj.createdAt.month}',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              })),
            ],
          ],
        ],
      ),
    );
  }
}
