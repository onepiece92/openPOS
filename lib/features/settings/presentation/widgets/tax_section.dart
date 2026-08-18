import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/shared/widgets/app_sheet.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

// ── Tax ───────────────────────────────────────────────────────────────────────

class TaxSection extends ConsumerWidget {
  const TaxSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxAsync = ref.watch(taxRatesStreamProvider);
    final defaultTaxId = ref.watch(defaultTaxIdProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: taxAsync.when(
        data: (rates) {
          final defaultRate = rates.where((t) => t.id == defaultTaxId).firstOrNull;
          final label = defaultRate != null
              ? '${defaultRate.name} · ${(defaultRate.rate * 100).toStringAsFixed(0)}%'
              : 'None';
          return ListTile(
            leading: const Icon(Icons.percent_rounded),
            title: const Text('Default Tax Rate'),
            subtitle: Text(label),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: rates.isEmpty
                ? null
                : () => _showTaxPicker(context, ref, rates, defaultTaxId),
          );
        },
        loading: () => const ListTile(
          leading: Icon(Icons.percent_rounded),
          title: Text('Default Tax Rate'),
          trailing: SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => const ListTile(
          leading: Icon(Icons.percent_rounded),
          title: Text('Default Tax Rate'),
          subtitle: Text('Error loading rates'),
        ),
      ),
    );
  }

  void _showTaxPicker(
    BuildContext context,
    WidgetRef ref,
    List<TaxRate> rates,
    int? currentId,
  ) {
    showAppSheet(
      context: context,
      builder: (_) => _TaxPickerSheet(rates: rates, currentId: currentId),
    );
  }
}

// ── Tax picker sheet ──────────────────────────────────────────────────────────

class _TaxPickerSheet extends ConsumerWidget {
  const _TaxPickerSheet({required this.rates, required this.currentId});
  final List<TaxRate> rates;
  final int? currentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text('Default Tax Rate',
              style: Theme.of(context).textTheme.titleLarge),
        ),
        ListTile(
          leading: const Icon(Icons.block_rounded),
          title: const Text('None'),
          trailing: currentId == null
              ? Icon(Icons.check_rounded, color: cs.primary)
              : null,
          onTap: () async {
            await ref.read(settingsProvider.notifier).setDefaultTaxId(null);
            if (context.mounted) Navigator.pop(context);
          },
        ),
        const Divider(height: 1),
        ...rates.map((t) => ListTile(
              title: Text(t.name),
              subtitle: Text(
                  '${(t.rate * 100).toStringAsFixed(1)}% · ${t.inclusionType}'),
              trailing: t.id == currentId
                  ? Icon(Icons.check_rounded, color: cs.primary)
                  : null,
              onTap: () async {
                await ref
                    .read(settingsProvider.notifier)
                    .setDefaultTaxId(t.id);
                if (context.mounted) Navigator.pop(context);
              },
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}
