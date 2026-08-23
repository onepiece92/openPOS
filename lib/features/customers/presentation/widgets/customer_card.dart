import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';

class CustomerCard extends ConsumerWidget {
  const CustomerCard({super.key, required this.customer, required this.onEdit});
  final Customer customer;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final selectedId = ref.watch(cartSessionProvider).customerId;
    final isSelected = selectedId == customer.id;
    void toggle() {
      final notifier = ref.read(cartSessionProvider.notifier);
      if (isSelected) {
        notifier.setCustomer(null);
        notifier.setOrderDiscount(0, isPercent: false);
      } else {
        notifier.setCustomer(customer.id);
        if (customer.defaultDiscount > 0) {
          notifier.setOrderDiscount(
            customer.defaultDiscount,
            isPercent: customer.defaultDiscountIsPercent,
          );
        }
        context.go('/pos');
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isSelected ? cs.primaryContainer : null,
      child: InkWell(
        onTap: toggle,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              // ── Radio ───────────────────────────────────────────────────
              RadioGroup<int?>(
                groupValue: selectedId,
                onChanged: (_) => toggle(),
                child: Radio<int?>(
                  value: customer.id,
                  toggleable: true,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 14),

              // ── Info ────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? cs.onPrimaryContainer : null,
                      ),
                    ),
                    if (customer.phone != null || customer.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (customer.phone != null) customer.phone!,
                          if (customer.email != null) customer.email!,
                        ].join('  ·  '),
                        style: tt.bodySmall?.copyWith(
                          color: isSelected
                              ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                              : cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // ── Badges ──────────────────────────────────────────
                    if (customer.defaultDiscount > 0 ||
                        customer.loyaltyPoints > 0 ||
                        customer.isTaxExempt) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (customer.defaultDiscount > 0)
                            _Badge(
                              icon: Icons.local_offer_rounded,
                              label: customer.defaultDiscountIsPercent
                                  ? '${customer.defaultDiscount.toStringAsFixed(customer.defaultDiscount % 1 == 0 ? 0 : 1)}% off'
                                  : '${customer.defaultDiscount.toStringAsFixed(0)} off',
                              bg: cs.errorContainer,
                              fg: cs.onErrorContainer,
                            ),
                          if (customer.loyaltyPoints > 0)
                            _Badge(
                              icon: Icons.stars_rounded,
                              label: '${customer.loyaltyPoints} pts',
                              bg: cs.tertiaryContainer,
                              fg: cs.onTertiaryContainer,
                            ),
                          if (customer.isTaxExempt)
                            _Badge(
                              icon: Icons.receipt_long_outlined,
                              label: 'Tax exempt',
                              bg: cs.secondaryContainer,
                              fg: cs.onSecondaryContainer,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ── Edit ────────────────────────────────────────────────────
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 18,
                    color: isSelected
                        ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                        : cs.onSurfaceVariant),
                onPressed: onEdit,
                tooltip: 'Edit',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge chip ────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Customer form (bottom sheet) ──────────────────────────────────────────────
