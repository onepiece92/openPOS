import 'package:flutter/material.dart';

import 'package:pos_app/core/theme/tokens.dart';

/// 26×26 circular-ish step button used for quantity increment/decrement on
/// product tiles. Variants follow the call sites: destructive (delete on qty=1),
/// disabled (at-cap increment), or neutral (regular increment/decrement).
class StepButton extends StatelessWidget {
  const StepButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: disabled
              ? cs.onSurface.withValues(alpha: 0.04)
              : isDestructive
                  ? cs.errorContainer.withValues(alpha: 0.6)
                  : cs.onSurface.withValues(alpha: AppOpacity.soft),
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Icon(
          icon,
          size: 14,
          color: disabled
              ? cs.onSurface.withValues(alpha: 0.25)
              : isDestructive
                  ? cs.error
                  : cs.onSurface,
        ),
      ),
    );
  }
}
