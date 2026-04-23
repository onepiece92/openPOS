import 'package:flutter/material.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';

class PosProductTile extends StatelessWidget {
  const PosProductTile({
    super.key,
    required this.product,
    required this.fmt,
    required this.qtyInCart,
    required this.onTap,
    required this.onIncrement,
    required this.onDecrement,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final Product product;
  final CurrencyFormatter fmt;
  final int qtyInCart;
  final VoidCallback onTap;       // add to cart (not in cart)
  final VoidCallback onIncrement; // qty++
  final VoidCallback onDecrement; // qty-- / remove
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final inCart = qtyInCart > 0;
    // is_out_of_stock flag OR negative qty (over-sold) → blocked.
    // 0 = unlimited — tappable.
    final outOfStock = product.isOutOfStock || product.stockQuantity < 0;
    // Tracked product already at its stock cap in the cart.
    final atCap = !outOfStock &&
        product.stockQuantity > 0 &&
        qtyInCart >= product.stockQuantity;

    return GestureDetector(
      // Root tile stays tappable at cap — home.dart's allowQty surfaces
      // the "Only N in stock" snackbar. The greyed `+` button is the
      // visual cap indicator.
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
            // ── Favorite star ───────────────────────────────────────────
            GestureDetector(
              onTap: onToggleFavorite,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 20,
                  color: isFavorite
                      ? cs.tertiary
                      : (inCart
                              ? cs.onPrimaryContainer
                              : cs.onSurface)
                          .withValues(alpha: isFavorite ? 1.0 : 0.35),
                ),
              ),
            ),
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
                fmt.formatPlain(product.price),
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
                onIncrement: atCap ? null : onIncrement,
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
  final VoidCallback? onIncrement;
  final VoidCallback onDecrement;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final isLast = qty == 1;
    final incDisabled = onIncrement == null;
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
          color: cs.onPrimaryContainer
              .withValues(alpha: incDisabled ? 0.25 : 1.0),
          bg: cs.onPrimaryContainer
              .withValues(alpha: incDisabled ? 0.04 : 0.15),
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
  final VoidCallback? onTap;
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
