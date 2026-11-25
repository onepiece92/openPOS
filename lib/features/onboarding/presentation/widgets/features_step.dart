import 'package:flutter/material.dart';

import 'package:pos_app/core/providers/feature_flags.dart';
import 'package:pos_app/features/features/presentation/features_screen.dart'
    show needsLine;

const kSuggestTitle = "Here's what we suggest";
const kSuggestSubtitle =
    'Turn on what you need. Switching a feature off never deletes data.';
const kStartMinimal = 'Start minimal';
const kSuggestFooter = 'You can change these any time in Features.';

/// Step 2: every switch pre-set from the preset, one line each, editable.
class FeaturesStep extends StatelessWidget {
  const FeaturesStep({
    super.key,
    required this.switches,
    required this.onChanged,
    required this.onStartMinimal,
  });
  final Map<Feature, bool> switches;
  final void Function(Feature, bool) onChanged;
  final VoidCallback onStartMinimal;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    bool on(Feature f) {
      final p = f.parent;
      return (switches[f] ?? false) && (p == null || on(p));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(kSuggestTitle,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(kSuggestSubtitle,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey('start-minimal'),
            onPressed: onStartMinimal,
            child: const Text(kStartMinimal),
          ),
        ),
        for (final f in Feature.values)
          Builder(builder: (_) {
            final p = f.parent;
            final blocked = p != null && !on(p);
            return SwitchListTile(
              key: ValueKey('suggest-${f.name}'),
              contentPadding: EdgeInsets.only(left: p == null ? 0 : 16),
              title: Text(f.label),
              subtitle: Text(blocked ? needsLine(p) : f.description),
              value: switches[f] ?? false,
              onChanged: blocked ? null : (v) => onChanged(f, v),
            );
          }),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(kSuggestFooter,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ),
      ],
    );
  }
}
