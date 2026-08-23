/// Cart detail (`/cart`). Header/pickers, line items, summary and the
/// sheets they open live in `widgets/`; this file only lays them out.
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/presentation/widgets/cart_line_item.dart';
import 'package:pos_app/features/cart/presentation/widgets/order_summary.dart';
import 'package:pos_app/features/cart/presentation/widgets/ticket_header.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

class CartDetailScreen extends ConsumerWidget {
  const CartDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final summary = ref.watch(cartSummaryProvider);
    final fmt = ref.watch(currencyFormatterProvider);
    final session = ref.watch(cartSessionProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(cart.isEmpty
            ? 'Cart'
            : 'Cart (${cart.fold(0, (s, i) => s + i.quantity)})'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: const Text('Clear'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 72,
                      color: cs.onSurfaceVariant.withAlpha(80)),
                  const SizedBox(height: 16),
                  Text('Your cart is empty',
                      style: tt.titleMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => context.pop(),
                    child: const Text('Browse Products'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                TicketHeader(session: session),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => CartLineItem(
                      item: cart[i],
                      fmt: fmt,
                    ),
                  ),
                ),
                OrderSummary(summary: summary, fmt: fmt),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.push('/payment'),
                    style: AppTheme.ctaButtonStyle(cs),
                    child: Text(
                      'Checkout  •  ${fmt.format(summary.total)}',
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
