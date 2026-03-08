import 'package:flutter/material.dart';

import 'package:pos_app/core/database/app_database.dart';

class PosProductTile extends StatelessWidget {
  const PosProductTile({
    super.key,
    required this.product,
    required this.currencySymbol,
    required this.qtyInCart,
    required this.onTap,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Product product;
  final String currencySymbol;
  final int qtyInCart;
  final VoidCallback onTap;       // add to cart (not in cart)
  final VoidCallback onIncrement; // qty++
  final VoidCallback onDecrement; // qty-- / remove

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final inCart = qtyInCart > 0;
    // 0  = unlimited (no stock set) — always tappable
    // <0 = depleted after over-selling — blocked
    final outOfStock = product.stockQuantity < 0;

    return GestureDetector(
      onTap: outOfStock ? null : (inCart ? onIncrement : onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: inCart
            ? BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // ── Name ────────────────────────────────────────────────────
            Expanded(
              child: Text(
                product.name,
                style: tt.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: outOfStock
                      ? cs.onSurface.withValues(alpha: 0.3)
                      : inCart
                          ? cs.onPrimaryContainer
                          : cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            // ── Price ───────────────────────────────────────────────────
            if (outOfStock)
              Text(
                'Out of stock',
                style: tt.labelSmall?.copyWith(
                  color: cs.error.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                '$currencySymbol ${product.price.toStringAsFixed(2)}',
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: inCart ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                ),
              ),
            const SizedBox(width: 12),
            // ── Stepper or add ───────────────────────────────────────────
            if (inCart)
              _Stepper(
                qty: qtyInCart,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
                cs: cs,
                tt: tt,
              )
            else if (!outOfStock)
              Icon(Icons.add_rounded, size: 22, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

// ─── Stepper ──────────────────────────────────────────────────────────────────

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
    required this.cs,
    required this.tt,
  });
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final isLast = qty == 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepBtn(
          icon: isLast ? Icons.delete_outline_rounded : Icons.remove_rounded,
          onTap: onDecrement,
          color: isLast ? cs.error : cs.onPrimaryContainer,
          bg: isLast
              ? cs.errorContainer.withValues(alpha: 0.5)
              : cs.onPrimaryContainer.withValues(alpha: 0.15),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onPrimaryContainer,
            ),
          ),
        ),
        _StepBtn(
          icon: Icons.add_rounded,
          onTap: onIncrement,
          color: cs.onPrimaryContainer,
          bg: cs.onPrimaryContainer.withValues(alpha: 0.15),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.bg,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}
