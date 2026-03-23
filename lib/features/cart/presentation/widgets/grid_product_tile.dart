import 'package:flutter/material.dart';

import 'package:pos_app/core/database/app_database.dart';

class GridProductTile extends StatelessWidget {
  const GridProductTile({
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
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          // ── Card ──────────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: cs.brightness == Brightness.dark
                    ? [
                        const Color(0xFF1E1E34)
                            .withValues(alpha: inCart ? 0.95 : 0.80),
                        const Color(0xFF14142A)
                            .withValues(alpha: inCart ? 0.90 : 0.70),
                      ]
                    : [
                        Colors.white.withValues(alpha: inCart ? 0.95 : 0.82),
                        Colors.white.withValues(alpha: inCart ? 0.88 : 0.68),
                      ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: inCart
                  ? Border.all(color: cs.primary, width: 1.5)
                  : Border.all(
                      color: cs.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.09)
                          : Colors.white.withValues(alpha: 0.75),
                    ),
              boxShadow: [
                BoxShadow(
                  color: inCart
                      ? cs.primary.withValues(alpha: 0.30)
                      : Colors.black.withValues(alpha: 0.10),
                  blurRadius: inCart ? 12 : 6,
                  spreadRadius: inCart ? 1 : 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Name ────────────────────────────────────────────────
                Expanded(
                  child: Text(
                    product.name,
                    style: tt.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: outOfStock
                          ? cs.onSurface.withValues(alpha: 0.3)
                          : cs.onSurface,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                // ── Price ───────────────────────────────────────────────
                Text(
                  outOfStock
                      ? 'Out of stock'
                      : '$currencySymbol ${product.price.toStringAsFixed(2)}',
                  style: tt.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: outOfStock
                        ? cs.error.withValues(alpha: 0.6)
                        : cs.onSurfaceVariant,
                  ),
                ),
                // ── Stepper row (in-cart only) ───────────────────────────
                if (inCart) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'x$qtyInCart',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      _StepBtn(
                        icon: qtyInCart == 1
                            ? Icons.delete_outline_rounded
                            : Icons.remove_rounded,
                        onTap: onDecrement,
                        isDestructive: qtyInCart == 1,
                        cs: cs,
                      ),
                      const SizedBox(width: 4),
                      _StepBtn(
                        icon: Icons.add_rounded,
                        onTap: onIncrement,
                        cs: cs,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // ── Badge ─────────────────────────────────────────────────────
          if (inCart)
            Positioned(
              top: -8,
              right: -8,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  'x$qtyInCart',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Step button ──────────────────────────────────────────────────────────────

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.onTap,
    required this.cs,
    this.isDestructive = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme cs;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isDestructive
              ? cs.errorContainer.withValues(alpha: 0.6)
              : cs.onSurface.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isDestructive ? cs.error : cs.onSurface,
        ),
      ),
    );
  }
}
