// ignore: unnecessary_import
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/cart/domain/cart_notifier.dart';
import 'package:pos_app/features/cart/domain/held_orders_notifier.dart';
import 'package:pos_app/features/customers/domain/customers_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

// ─── Checkout bar (bottomNavigationBar slot) ──────────────────────────────────

class CheckoutBar extends ConsumerWidget {
  const CheckoutBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final itemCount = cart.fold(0, (s, i) => s + i.quantity);
    if (itemCount == 0) return const SizedBox.shrink();

    final summary = ref.watch(cartSummaryProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final customerName = ref.watch(cartCustomerNameProvider);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: AppTheme.frostedBar(cs),
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
          child: Row(
            children: [
              // ── Save as ticket ─────────────────────────────────────────
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(heldOrdersProvider.notifier).hold(
                          cart,
                          customerName: customerName,
                        );
                    ref.read(cartProvider.notifier).clear();
                  },
                  icon: const Icon(Icons.pause_circle_outline_rounded, size: 18),
                  label: const Text('Save'),
                ),
              ),
              const SizedBox(width: 10),
              // ── Checkout CTA ───────────────────────────────────────────
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: () => context.push('/cart'),
                    style: AppTheme.ctaButtonStyle(cs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Checkout  ·  $itemCount ${itemCount == 1 ? 'item' : 'items'}',
                            style: tt.titleSmall?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: cs.onPrimary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$symbol ${summary.total.toStringAsFixed(2)}',
                            style: tt.labelLarge?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
