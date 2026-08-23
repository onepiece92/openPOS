import 'package:flutter/material.dart';

class WizardHeader extends StatelessWidget {
  const WizardHeader({super.key, required this.step, this.onSkip});
  final int step;
  final VoidCallback? onSkip;

  static const _labels = ['Business', 'Country', 'Tax', 'Confirm'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Set up your store',
                style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              Row(
                children: [
                  Text(
                    '${step + 1} of 4',
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (onSkip != null) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Skip'),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (step + 1) / 4,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(4, (i) {
              final active = i == step;
              final done = i < step;
              return Expanded(
                child: Center(
                  child: Text(
                    _labels[i],
                    style: tt.labelSmall?.copyWith(
                      color: (done || active)
                          ? cs.primary
                          : cs.onSurfaceVariant.withAlpha(100),
                      fontWeight:
                          active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Nav bar ─────────────────────────────────────────────────────────────────
