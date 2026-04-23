import 'package:flutter/material.dart';

import 'package:pos_app/core/theme/tokens.dart';

/// Shared empty-state view used across orders, products, inventory, expenses
/// and customers lists. Icon sits in a rounded surface tile; title/subtitle
/// use the theme's titleMedium / bodySmall scales; optional trailing action.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Radii.xxl),
            ),
            child: Icon(icon, size: 40, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: Spacing.xl),
          Text(
            title,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: Spacing.xl),
            action!,
          ],
        ],
      ),
    );
  }
}
