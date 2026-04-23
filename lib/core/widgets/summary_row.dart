import 'package:flutter/material.dart';

import 'package:pos_app/core/theme/tokens.dart';

enum SummaryEmphasis { normal, bold, muted }

/// A label+value row used in cart/receipt/onboarding summaries.
/// Single source of truth replacing the per-feature `_SummaryRow` / `_BillRow`
/// copies that had drifted apart over time.
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.emphasis = SummaryEmphasis.normal,
  });

  final String label;
  final String value;
  final IconData? icon;
  final SummaryEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final (TextStyle? labelStyle, TextStyle? valueStyle) = switch (emphasis) {
      SummaryEmphasis.bold => (
          tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          tt.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.primary,
              fontFamily: AppFonts.mono),
        ),
      SummaryEmphasis.muted => (
          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant, fontFamily: AppFonts.mono),
        ),
      SummaryEmphasis.normal => (
          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600, fontFamily: AppFonts.mono),
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: Spacing.md),
          ],
          Text(label, style: labelStyle),
          const Spacer(),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
