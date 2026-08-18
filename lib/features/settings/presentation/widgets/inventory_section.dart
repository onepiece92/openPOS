import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/shared/widgets/app_sheet.dart';

// ── Inventory ─────────────────────────────────────────────────────────────────

class InventorySection extends ConsumerWidget {
  const InventorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threshold = ref.watch(lowStockThresholdProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.inventory_2_outlined),
        title: const Text('Low Stock Threshold'),
        subtitle: Text('Alert when stock falls below $threshold units'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _editThreshold(context, ref, threshold),
      ),
    );
  }

  void _editThreshold(BuildContext context, WidgetRef ref, int current) {
    showAppSheet(
      context: context,
      builder: (_) => _LowStockSheet(current: current),
    );
  }
}

// ── Low stock threshold sheet ─────────────────────────────────────────────────

class _LowStockSheet extends ConsumerStatefulWidget {
  const _LowStockSheet({required this.current});
  final int current;

  @override
  ConsumerState<_LowStockSheet> createState() => _LowStockSheetState();
}

class _LowStockSheetState extends ConsumerState<_LowStockSheet> {
  late final _ctrl = TextEditingController(text: '${widget.current}');

  @override
  void dispose() {
    _ctrl.dispose();
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
          Text('Low Stock Threshold',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Threshold (units)',
              helperText:
                  'Products at or below this quantity show a low-stock badge',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: FilledButton(
              // shape/textStyle inherited from filledButtonTheme
              style: AppTheme.ctaButtonStyle(
                  Theme.of(context).colorScheme),
              onPressed: () async {
                final v = int.tryParse(_ctrl.text);
                if (v == null || v < 0) return;
                final nav = Navigator.of(context);
                await ref
                    .read(settingsProvider.notifier)
                    .setLowStockThreshold(v);
                if (!mounted) return;
                nav.pop();
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
