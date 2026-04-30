// ignore: unnecessary_import
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/cart/domain/cart_notifier.dart';
import 'package:pos_app/features/cart/domain/held_orders_notifier.dart';
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
    final fmt = ref.watch(currencyFormatterProvider);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final session = ref.watch(cartSessionProvider);
    final assignedCustomerId = session.customerId;
    final assignedTableId = session.tableId;

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
                    ref.read(heldOrdersProvider.notifier).holdCurrentCart();
                    ref.read(cartProvider.notifier).clear();
                  },
                  icon: const Icon(Icons.pause_circle_outline_rounded, size: 18),
                  label: const Text('Save'),
                ),
              ),
              const SizedBox(width: 10),
              // ── Customer button ────────────────────────────────────────
              SizedBox(
                height: 56,
                width: 56,
                child: Tooltip(
                  message: assignedCustomerId != null
                      ? 'Customer assigned'
                      : 'Assign customer',
                  child: OutlinedButton(
                    onPressed: () => context.push('/customers'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: assignedCustomerId != null
                          ? BorderSide(color: cs.primary, width: 2)
                          : null,
                    ),
                    child: Icon(
                      assignedCustomerId != null
                          ? Icons.person_rounded
                          : Icons.person_outline_rounded,
                      color: assignedCustomerId != null ? cs.primary : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // ── Table button ───────────────────────────────────────────
              SizedBox(
                height: 56,
                width: 56,
                child: Tooltip(
                  message: assignedTableId != null
                      ? 'Table assigned'
                      : 'Assign table',
                  child: OutlinedButton(
                    onPressed: () => context.push('/tables'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: assignedTableId != null
                          ? BorderSide(color: cs.primary, width: 2)
                          : null,
                    ),
                    child: Icon(
                      assignedTableId != null
                          ? Icons.table_restaurant_rounded
                          : Icons.table_restaurant_outlined,
                      color: assignedTableId != null ? cs.primary : null,
                    ),
                  ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.shopping_cart_checkout_rounded,
                            color: cs.onPrimary),
                        Text(
                          '$itemCount',
                          style: tt.titleSmall?.copyWith(
                            color: cs.onPrimary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
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
                            fmt.format(summary.total),
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
