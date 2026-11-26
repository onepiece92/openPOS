import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/features/tips/tips_settings.dart';
import 'package:pos_app/shared/widgets/app_sheet.dart';

/// Settings: the preset percentages and the tip base. Shown only while the
/// Tips feature is on.
class TipsSection extends ConsumerWidget {
  const TipsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(tipsSettingsProvider);
    final notifier = ref.read(tipsSettingsProvider.notifier);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ListTile(
            title: const Text('Tip percentages'),
            subtitle: Text(s.presets.map(tipPercentLabel).join(', ')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showAppSheet(
              context: context,
              builder: (_) => const TipPresetsSheet(),
            ),
          ),
          const Divider(height: 1, indent: 16),
          SwitchListTile(
            title: const Text('Tip on total after tax'),
            subtitle: Text(s.postTax
                ? 'Percentages apply to the total with tax'
                : 'Percentages apply to the price before tax'),
            value: s.postTax,
            onChanged: notifier.setPostTax,
          ),
        ],
      ),
    );
  }
}

/// Edits the preset list: up to [kMaxTipPresets] percentages, each above 0
/// and at most 100.
class TipPresetsSheet extends ConsumerStatefulWidget {
  const TipPresetsSheet({super.key});

  @override
  ConsumerState<TipPresetsSheet> createState() => _TipPresetsSheetState();
}

class _TipPresetsSheetState extends ConsumerState<TipPresetsSheet> {
  late final _ctrl = TextEditingController(
      text: ref
          .read(tipsSettingsProvider)
          .presets
          .map((p) => tipPercentLabel(p).replaceAll('%', ''))
          .join(', '));
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final out = <double>[];
    final error = parseTipPresets(_ctrl.text, out);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    await ref.read(tipsSettingsProvider.notifier).setPresets(out);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tip percentages',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Percentages, separated by commas',
              helperText: 'Up to $kMaxTipPresets, from above 0 to 100',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
