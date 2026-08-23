import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';

// ─── Cart line item ────────────────────────────────────────────────────────────

class CartLineItem extends ConsumerWidget {
  const CartLineItem({super.key, required this.item, required this.fmt});
  final CartItem item;
  final CurrencyFormatter fmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final notifier = ref.read(cartProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${fmt.formatPlain(item.unitPrice)} each',
                  style: tt.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Qty stepper
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove_rounded,
                onPressed: () => notifier.setQuantity(
                    item.productId, item.quantity - 1),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${item.quantity}',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                onPressed: () => notifier.setQuantity(
                    item.productId, item.quantity + 1),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Line total
          SizedBox(
            width: 72,
            child: Text(
              fmt.formatPlain(item.lineSubtotal),
              textAlign: TextAlign.end,
              style: tt.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          // Delete
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: cs.error),
            onPressed: () => notifier.remove(item.productId),
            iconSize: 20,
            padding: const EdgeInsets.only(left: 4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
