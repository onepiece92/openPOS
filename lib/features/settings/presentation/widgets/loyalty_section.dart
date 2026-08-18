import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/shared/widgets/app_sheet.dart';

// ── Loyalty ───────────────────────────────────────────────────────────────────

class LoyaltySection extends ConsumerWidget {
  const LoyaltySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(loyaltyEnabledProvider);
    final earnRate = ref.watch(loyaltyEarnRateProvider);
    final pointValue = ref.watch(loyaltyPointValueProvider);
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.stars_rounded,
                color: enabled ? cs.primary : cs.onSurfaceVariant),
            title: const Text('Enable Loyalty Points'),
            subtitle: const Text('Customers earn and redeem points on purchases'),
            value: enabled,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setLoyaltyEnabled(v),
          ),
          if (enabled) ...[
            const Divider(height: 1, indent: 16),
            ListTile(
              leading: const Icon(Icons.add_circle_outline_rounded),
              title: const Text('Earn Rate'),
              subtitle: Text(
                  '${earnRate.toStringAsFixed(earnRate % 1 == 0 ? 0 : 2)} pt per 1 currency unit spent'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showRateSheet(context, ref, earnRate, pointValue),
            ),
            const Divider(height: 1, indent: 16),
            ListTile(
              leading: const Icon(Icons.redeem_rounded),
              title: const Text('Point Value'),
              subtitle: Text(
                  '1 pt = ${pointValue.toStringAsFixed(pointValue % 1 == 0 ? 0 : 2)} currency unit'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showRateSheet(context, ref, earnRate, pointValue),
            ),
          ],
        ],
      ),
    );
  }

  void _showRateSheet(
    BuildContext context,
    WidgetRef ref,
    double earnRate,
    double pointValue,
  ) {
    showAppSheet(
      context: context,
      builder: (_) => _LoyaltyRateSheet(
        earnRate: earnRate,
        pointValue: pointValue,
      ),
    );
  }
}

class _LoyaltyRateSheet extends ConsumerStatefulWidget {
  const _LoyaltyRateSheet({
    required this.earnRate,
    required this.pointValue,
  });
  final double earnRate;
  final double pointValue;

  @override
  ConsumerState<_LoyaltyRateSheet> createState() => _LoyaltyRateSheetState();
}

class _LoyaltyRateSheetState extends ConsumerState<_LoyaltyRateSheet> {
  late final _earnCtrl =
      TextEditingController(text: widget.earnRate.toStringAsFixed(
          widget.earnRate % 1 == 0 ? 0 : 2));
  late final _valueCtrl =
      TextEditingController(text: widget.pointValue.toStringAsFixed(
          widget.pointValue % 1 == 0 ? 0 : 2));

  @override
  void dispose() {
    _earnCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Loyalty Rates',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Set how many points customers earn and what each point is worth.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _earnCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Earn rate (pts per 1 currency unit)',
              helperText: 'e.g. 1 means 1 pt earned per 1 unit spent',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Point value (currency per 1 pt)',
              helperText: 'e.g. 1 means 1 pt = 1 currency unit discount',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              final earn = double.tryParse(_earnCtrl.text);
              final value = double.tryParse(_valueCtrl.text);
              if (earn == null || earn <= 0 || value == null || value <= 0) {
                return;
              }
              await ref
                  .read(settingsProvider.notifier)
                  .setLoyaltyRates(earnRate: earn, pointValue: value);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
