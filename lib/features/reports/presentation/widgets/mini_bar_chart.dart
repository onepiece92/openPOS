import 'package:flutter/material.dart';

import 'package:pos_app/core/theme/tokens.dart';

// ── Mini bar chart ────────────────────────────────────────────────────────────

class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.labels,
    required this.values,
    required this.highlightIndex,
    required this.cs,
  });
  final List<String> labels;
  final List<double> values;
  final int highlightIndex;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final maxVal = values.fold(0.0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(labels.length, (i) {
                final ratio = maxVal > 0 ? values[i] / maxVal : 0.0;
                final isHighlight = i == highlightIndex;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isHighlight && values[i] > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              values[i] >= 1000
                                  ? '${(values[i] / 1000).toStringAsFixed(1)}k'
                                  : values[i].toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                                fontFamily: AppFonts.mono,
                              ),
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOut,
                          height: ratio * 72,
                          decoration: BoxDecoration(
                            color: isHighlight
                                ? cs.primary
                                : cs.primary.withValues(alpha: 0.35),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: labels
                .asMap()
                .entries
                .map((e) => Expanded(
                      child: Text(
                        e.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: e.key == highlightIndex
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: e.key == highlightIndex
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
