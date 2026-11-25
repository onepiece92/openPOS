import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/theme/tokens.dart';
import 'package:pos_app/features/cart/domain/pos_catalog_provider.dart';
import 'package:pos_app/features/cart/presentation/pos_cart_actions.dart';
import 'package:pos_app/features/products/domain/favorites_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/shared/widgets/step_button.dart';

/// Watches only what it shows: this product's main-unit quantity, whether
/// it is a favourite, and the currency format. A cart change elsewhere does
/// not rebuild it, and its taps read the cart when they happen.
class GridProductTile extends ConsumerWidget {
  const GridProductTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fmt = ref.watch(currencyFormatterProvider);
    final qtyInCart = ref.watch(
        cartMainUnitQtyProvider.select((qty) => qty[product.id] ?? 0));
    final isFavorite = ref
        .watch(favoritesProvider.select((ids) => ids.contains(product.id)));

    void onTap() => PosCartActions.of(context).add(product);
    void onIncrement() => PosCartActions.of(context).step(product, 1);
    void onDecrement() => PosCartActions.of(context).step(product, -1);
    void onToggleFavorite() =>
        ref.read(favoritesProvider.notifier).toggle(product.id);
    final onLongPress = product.secondaryUnit == null
        ? null
        : () => PosCartActions.of(context).pickUnit(context, product);

    final inCart = qtyInCart > 0;
    // is_out_of_stock flag OR negative qty (over-sold) → blocked.
    // 0 = unlimited — tappable.
    final outOfStock = product.isOutOfStock || product.stockQuantity < 0;
    // Tracked product already at its stock cap in the cart.
    final atCap = !outOfStock &&
        product.stockQuantity > 0 &&
        qtyInCart >= product.stockQuantity;

    return GestureDetector(
      // Root tile stays tappable at cap — PosCartActions surfaces
      // the "Only N in stock" snackbar. The greyed `+` button is the
      // visual cap indicator.
      onTap: outOfStock ? null : (inCart ? onIncrement : onTap),
      onLongPress: outOfStock ? null : onLongPress,
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
                      ? cs.primary.withValues(alpha: AppOpacity.strong)
                      : Colors.black.withValues(alpha: AppOpacity.soft),
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
                      : fmt.format(product.price),
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
                      StepButton(
                        icon: qtyInCart == 1
                            ? Icons.delete_outline_rounded
                            : Icons.remove_rounded,
                        onTap: onDecrement,
                        isDestructive: qtyInCart == 1,
                      ),
                      const SizedBox(width: 4),
                      StepButton(
                        icon: Icons.add_rounded,
                        onTap: atCap ? null : onIncrement,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // ── Favorite star (bottom-right, hidden when in cart) ─────────
          if (!inCart)
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: onToggleFavorite,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  child: Icon(
                    isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14,
                    color: isFavorite
                        ? cs.tertiary
                        : cs.onSurface.withValues(alpha: 0.3),
                  ),
                ),
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

