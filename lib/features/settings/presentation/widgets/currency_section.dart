import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/shared/widgets/app_sheet.dart';
import 'package:pos_app/features/settings/domain/currencies.dart';

// ── Currency ──────────────────────────────────────────────────────────────────

class CurrencySection extends ConsumerWidget {
  const CurrencySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(currencySymbolProvider);
    final code = ref.watch(currencyCodeProvider);
    final cs = Theme.of(context).colorScheme;

    final match = kPopularCurrencies.where((c) => c.code == code).firstOrNull;
    final displayName = match != null ? '${match.name} (${match.symbol})' : '$code ($symbol)';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Text(
            symbol.length <= 2 ? symbol : symbol[0],
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: const Text('Currency'),
        subtitle: Text(displayName),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _showCurrencyPicker(context, ref, code),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, String current) {
    showAppSheet(
      context: context,
      draggable: true,
      initialSize: 0.6,
      builder: (_) => _CurrencyPickerSheet(current: current),
    );
  }
}

// ── Currency picker sheet ─────────────────────────────────────────────────────

class _CurrencyPickerSheet extends ConsumerWidget {
  const _CurrencyPickerSheet({required this.current});
  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) {
        final cs = Theme.of(ctx).colorScheme;
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Select Currency',
                    style: Theme.of(ctx).textTheme.titleLarge),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                itemCount: kPopularCurrencies.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16),
                itemBuilder: (_, i) {
                  final c = kPopularCurrencies[i];
                  final selected = c.code == current;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: selected
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      child: Text(
                        c.symbol.length <= 2 ? c.symbol : c.symbol[0],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: selected
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    title: Text(c.name),
                    subtitle: Text('${c.code} · ${c.symbol}'),
                    trailing: selected
                        ? Icon(Icons.check_rounded, color: cs.primary)
                        : null,
                    onTap: () async {
                      await ref
                          .read(settingsProvider.notifier)
                          .setCurrency(symbol: c.symbol, code: c.code);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
