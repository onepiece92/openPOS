import 'package:flutter/material.dart';

class WizardHeader extends StatelessWidget {
  const WizardHeader(
      {super.key, required this.step, required this.labels, this.onSkip});
  final int step;

  /// One short label per step; the step count is its length.
  final List<String> labels;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final count = labels.length;

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
                    '${step + 1} of $count',
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
              value: (step + 1) / count,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(count, (i) {
              final active = i == step;
              final done = i < step;
              return Expanded(
                child: Center(
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall?.copyWith(
                      color: (done || active)
                          ? cs.primary
                          : cs.onSurfaceVariant.withAlpha(100),
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
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
