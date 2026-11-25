import 'package:flutter/material.dart';

import 'package:pos_app/features/onboarding/domain/business_type.dart';

const kBusinessTypeTitle = 'What kind of business?';
const kBusinessTypeSubtitle =
    "Pick the closest one. We'll suggest which features to turn on.";

/// Step 1: a plain text list; one tap picks a type and moves on.
class BusinessTypeStep extends StatelessWidget {
  const BusinessTypeStep(
      {super.key, required this.selected, required this.onPick});
  final BusinessType? selected;
  final ValueChanged<BusinessType> onPick;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(kBusinessTypeTitle,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(kBusinessTypeSubtitle,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        for (final t in BusinessType.values)
          ListTile(
            key: ValueKey('business-${t.name}'),
            contentPadding: EdgeInsets.zero,
            title: Text(t.label),
            selected: t == selected,
            onTap: () => onPick(t),
          ),
      ],
    );
  }
}
