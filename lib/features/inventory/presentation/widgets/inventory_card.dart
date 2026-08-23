import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/utils/async_feedback.dart';

class InventoryCard extends ConsumerWidget {
  const InventoryCard({super.key, 
    required this.product,
    required this.threshold,
  });

  final Product product;
  final int threshold;

  Color _badgeColor(ColorScheme cs) {
    if (product.isOutOfStock || product.stockQuantity < 0) return cs.error;
    if (product.stockQuantity > 0 && product.stockQuantity <= threshold) {
      return const Color(0xFFD97706);
    }
    return cs.primary;
  }

  String _qtyLabel() {
    if (product.isOutOfStock || product.stockQuantity < 0) return 'Out';
    if (product.stockQuantity == 0) return '∞';
    return '${product.stockQuantity}';
  }

  /// Stepper state machine for TRACKED products only: Out ↔ 1 ↔ 2 ↔ 3 ↔ …
  ///
  /// Unlimited products (qty=0, !isOutOfStock) disable the stepper entirely —
  /// the only way in/out of unlimited is the overflow menu's "Track stock" toggle.
  ///
  /// All writes batched in one transaction → single stream emission per tap.
  Future<void> _increment(BuildContext context, WidgetRef ref) async {
    final qty = product.stockQuantity;
    final isOut = product.isOutOfStock;

    final int newQty;
    final bool newIsOut;
    final int delta;
    final String reason;

    if (isOut) {
      // Out → 1
      newQty = 1;
      newIsOut = false;
      delta = 1;
      reason = 'manual_add';
    } else if (qty > 0) {
      // N → N+1
      newQty = qty + 1;
      newIsOut = false;
      delta = 1;
      reason = 'manual_add';
    } else {
      // Unlimited — shouldn't fire (button disabled)
      return;
    }

    await _apply(context, ref,
        newQty: newQty, newIsOut: newIsOut, delta: delta, reason: reason);
  }

  Future<void> _decrement(BuildContext context, WidgetRef ref) async {
    final qty = product.stockQuantity;

    final int newQty;
    final bool newIsOut;
    final int delta;
    final String reason;

    if (qty > 1) {
      // N → N-1
      newQty = qty - 1;
      newIsOut = false;
      delta = -1;
      reason = 'manual_remove';
    } else if (qty == 1) {
      // 1 → Out
      newQty = 0;
      newIsOut = true;
      delta = -1;
      reason = 'manual_remove';
    } else {
      // Out or unlimited — shouldn't fire (button disabled)
      return;
    }

    await _apply(context, ref,
        newQty: newQty, newIsOut: newIsOut, delta: delta, reason: reason);
  }

  Future<void> _apply(
    BuildContext context,
    WidgetRef ref, {
    required int newQty,
    required bool newIsOut,
    required int delta,
    required String reason,
  }) async {
    final db = ref.read(databaseProvider);
    await withErrorSnackbar(
      context,
      () => db.transaction(() async {
        await db.productsDao.setStockState(
          product.id,
          stockQuantity: newQty,
          isOutOfStock: newIsOut,
        );
        await db.inventoryDao.logAdjustment(
          StockAdjustmentsCompanion.insert(
            productId: product.id,
            delta: delta,
            reasonCode: reason,
          ),
        );
      }),
      failurePrefix: 'Stock update failed',
    );
  }

  Future<void> _setAbsolute(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(
        text:
            product.stockQuantity > 0 ? product.stockQuantity.toString() : '');
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
            helperText: '0 = out of stock',
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
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || !context.mounted) return;

    // Tracked product entering 0 → Out (qty=0, isOutOfStock=true).
    // Entering N > 0 → tracked N, clear out-of-stock flag.
    // Unlimited products use the overflow menu's Track Stock toggle instead.
    final delta = result - product.stockQuantity;
    await _apply(
      context,
      ref,
      newQty: result,
      newIsOut: result == 0,
      delta: delta,
      reason: 'manual_set',
    );
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
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    product.sku,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Inline stepper ── [−] [qty] [+]
            _StepperRow(
              qtyLabel: _qtyLabel(),
              badgeColor: badgeColor,
              canDecrement: qty > 0,
              canIncrement: product.isOutOfStock || qty > 0,
              onDecrement: () => _decrement(context, ref),
              onIncrement: () => _increment(context, ref),
              onQtyTap: () => _setAbsolute(context, ref),
            ),
            // Overflow menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              tooltip: 'More',
              onSelected: (v) async {
                if (v == 'mark_out') {
                  await _apply(context, ref,
                      newQty: product.stockQuantity,
                      newIsOut: true,
                      delta: 0,
                      reason: 'mark_out_of_stock');
                } else if (v == 'mark_in') {
                  await _apply(context, ref,
                      newQty: product.stockQuantity,
                      newIsOut: false,
                      delta: 0,
                      reason: 'mark_back_in_stock');
                } else if (v == 'stop_tracking') {
                  await _apply(context, ref,
                      newQty: 0,
                      newIsOut: false,
                      delta: 0,
                      reason: 'stop_tracking');
                } else if (v == 'start_tracking') {
                  await _apply(context, ref,
                      newQty: 1,
                      newIsOut: false,
                      delta: 1,
                      reason: 'start_tracking');
                }
              },
              itemBuilder: (_) {
                final isUnlimited =
                    product.stockQuantity == 0 && !product.isOutOfStock;
                return [
                  if (isUnlimited)
                    const PopupMenuItem(
                      value: 'start_tracking',
                      child: ListTile(
                        leading: Icon(Icons.analytics_outlined),
                        title: Text('Track stock'),
                        subtitle: Text('Start counting inventory'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  else ...[
                    if (!product.isOutOfStock)
                      const PopupMenuItem(
                        value: 'mark_out',
                        child: ListTile(
                          leading: Icon(Icons.block_rounded),
                          title: Text('Mark out of stock'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'mark_in',
                        child: ListTile(
                          leading: Icon(Icons.check_circle_outline_rounded),
                          title: Text('Back in stock'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'stop_tracking',
                      child: ListTile(
                        leading: Icon(Icons.all_inclusive_rounded),
                        title: Text('Don\'t track stock'),
                        subtitle: Text('Mark as unlimited'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ];
              },
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
    required this.qtyLabel,
    required this.badgeColor,
    required this.canDecrement,
    required this.canIncrement,
    required this.onDecrement,
    required this.onIncrement,
    required this.onQtyTap,
  });

  final String qtyLabel;
  final Color badgeColor;
  final bool canDecrement;
  final bool canIncrement;
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
          onTap: canDecrement ? onDecrement : null,
          cs: cs,
        ),
        // Quantity tappable badge
        GestureDetector(
          onTap: onQtyTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: badgeColor.withValues(alpha: 0.3), width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              qtyLabel,
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
          onTap: canIncrement ? onIncrement : null,
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
        color: onTap == null
            ? cs.onSurfaceVariant.withValues(alpha: 0.3)
            : cs.primary,
        onPressed: onTap,
      ),
    );
  }
}
