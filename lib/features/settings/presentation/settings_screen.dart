import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

// ── Popular currencies ────────────────────────────────────────────────────────

const _currencies = [
  (code: 'NPR', symbol: 'Rs', name: 'Nepali Rupee'),
  (code: 'USD', symbol: '\$', name: 'US Dollar'),
  (code: 'EUR', symbol: '€', name: 'Euro'),
  (code: 'GBP', symbol: '£', name: 'British Pound'),
  (code: 'INR', symbol: '₹', name: 'Indian Rupee'),
  (code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
  (code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
  (code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
  (code: 'AED', symbol: 'AED', name: 'UAE Dirham'),
  (code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
  (code: 'PHP', symbol: '₱', name: 'Philippine Peso'),
  (code: 'THB', symbol: '฿', name: 'Thai Baht'),
  (code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah'),
  (code: 'PKR', symbol: '₨', name: 'Pakistani Rupee'),
  (code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
  (code: 'LKR', symbol: '₨', name: 'Sri Lankan Rupee'),
  (code: 'KES', symbol: 'KSh', name: 'Kenyan Shilling'),
  (code: 'NGN', symbol: '₦', name: 'Nigerian Naira'),
  (code: 'ZAR', symbol: 'R', name: 'South African Rand'),
  (code: 'BRL', symbol: 'R\$', name: 'Brazilian Real'),
  (code: 'MXN', symbol: 'MX\$', name: 'Mexican Peso'),
  (code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
  (code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
  (code: 'KRW', symbol: '₩', name: 'South Korean Won'),
];

// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Store Profile'),
          _StoreProfileSection(),
          const _SectionHeader('Currency'),
          _CurrencySection(),
          const _SectionHeader('Tax'),
          _TaxSection(),
          const _SectionHeader('Inventory'),
          _InventorySection(),
          const _SectionHeader('Loyalty'),
          _LoyaltySection(),
          const _SectionHeader('Appearance'),
          _AppearanceSection(),
          const _SectionHeader('Danger Zone'),
          _DangerSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

// ── Store Profile ─────────────────────────────────────────────────────────────

class _StoreProfileSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(businessNameProvider);
    final tagline = ref.watch(businessTaglineProvider);
    final phone = ref.watch(businessPhoneProvider);
    final address = ref.watch(businessAddressProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/settings/profile'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Business name not set' : name,
                      style: tt.titleMedium?.copyWith(
                        color: name.isEmpty ? cs.onSurfaceVariant : null,
                        fontStyle: name.isEmpty ? FontStyle.italic : null,
                      ),
                    ),
                    if (tagline.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(tagline,
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (phone.isNotEmpty)
                          _ProfileTag(
                              icon: Icons.phone_outlined,
                              text: phone,
                              cs: cs,
                              tt: tt),
                        if (address.isNotEmpty)
                          _ProfileTag(
                              icon: Icons.location_on_outlined,
                              text: address,
                              cs: cs,
                              tt: tt),
                        if (phone.isEmpty && address.isEmpty)
                          Text(
                            'Phone & address not set',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.55),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.edit_outlined,
                  size: 18, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTag extends StatelessWidget {
  const _ProfileTag(
      {required this.icon,
      required this.text,
      required this.cs,
      required this.tt});
  final IconData icon;
  final String text;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      );
}

// ── Currency ──────────────────────────────────────────────────────────────────

class _CurrencySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(currencySymbolProvider);
    final code = ref.watch(currencyCodeProvider);
    final cs = Theme.of(context).colorScheme;

    final match = _currencies.where((c) => c.code == code).firstOrNull;
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CurrencyPickerSheet(current: current),
    );
  }
}

// ── Tax ───────────────────────────────────────────────────────────────────────

class _TaxSection extends ConsumerWidget {
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
    showModalBottomSheet(
      context: context,
      builder: (_) => _TaxPickerSheet(rates: rates, currentId: currentId),
    );
  }
}

// ── Inventory ─────────────────────────────────────────────────────────────────

class _InventorySection extends ConsumerWidget {
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LowStockSheet(current: current),
    );
  }
}

// ── Loyalty ───────────────────────────────────────────────────────────────────

class _LoyaltySection extends ConsumerWidget {
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
            onChanged: (v) async {
              await saveLoyaltyEnabled(ref.read(settingsBoxProvider), v);
              ref.invalidate(loyaltyEnabledProvider);
            },
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
              final box = ref.read(settingsBoxProvider);
              await saveLoyaltyEarnRate(box, earn);
              await saveLoyaltyPointValue(box, value);
              ref.invalidate(loyaltyEarnRateProvider);
              ref.invalidate(loyaltyPointValueProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Appearance ────────────────────────────────────────────────────────────────

class _AppearanceSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(savedThemeModeProvider);

    final label = switch (themeMode) {
      ThemeMode.dark => 'Dark',
      ThemeMode.light => 'Light',
      _ => 'System default',
    };

    final icon = switch (themeMode) {
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      _ => Icons.brightness_auto_rounded,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: const Text('Theme'),
        subtitle: Text(label),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _showThemePicker(context, ref, themeMode),
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _ThemePickerSheet(current: current),
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
                itemCount: _currencies.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16),
                itemBuilder: (_, i) {
                  final c = _currencies[i];
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
                      final box = ref.read(settingsBoxProvider);
                      await saveCurrencySymbol(box, c.symbol);
                      await saveCurrencyCode(box, c.code);
                      ref.invalidate(currencySymbolProvider);
                      ref.invalidate(currencyCodeProvider);
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
            await ref.read(settingsBoxProvider).delete('default_tax_id');
            ref.invalidate(defaultTaxIdProvider);
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
                await saveDefaultTaxId(ref.read(settingsBoxProvider), t.id);
                ref.invalidate(defaultTaxIdProvider);
                if (context.mounted) Navigator.pop(context);
              },
            )),
        const SizedBox(height: 16),
      ],
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
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
                await saveLowStockThreshold(
                    ref.read(settingsBoxProvider), v);
                ref.invalidate(lowStockThresholdProvider);
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

// ── Theme picker sheet ────────────────────────────────────────────────────────

class _ThemePickerSheet extends ConsumerWidget {
  const _ThemePickerSheet({required this.current});
  final ThemeMode current;

  static const _options = [
    (ThemeMode.system, 'System default', Icons.brightness_auto_rounded),
    (ThemeMode.light, 'Light', Icons.light_mode_rounded),
    (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text('Theme', style: Theme.of(context).textTheme.titleLarge),
        ),
        ..._options.map((item) {
          final (mode, label, icon) = item;
          return ListTile(
            leading: Icon(icon),
            title: Text(label),
            trailing: current == mode
                ? Icon(Icons.check_rounded, color: cs.primary)
                : null,
            onTap: () async {
              await saveThemeMode(ref.read(settingsBoxProvider), mode);
              ref.invalidate(savedThemeModeProvider);
              if (context.mounted) Navigator.pop(context);
            },
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Danger Zone ───────────────────────────────────────────────────────────────

class _DangerSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: cs.errorContainer.withValues(alpha: 0.2),
      child: ListTile(
        leading: Icon(Icons.delete_forever_rounded, color: cs.error),
        title: Text(
          'Factory Reset',
          style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Erase all data and restart onboarding'),
        trailing: Icon(Icons.chevron_right_rounded, color: cs.error),
        onTap: () => _confirmReset(context, ref),
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Factory Reset?'),
        content: const Text(
          'This will permanently delete ALL products, orders, customers, '
          'expenses, and settings. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _doReset(context, ref);
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _doReset(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final box = ref.read(settingsBoxProvider);

    try {
      await db.transaction(() async {
        await db.delete(db.stockAdjustments).go();
        await db.delete(db.orderTaxOverrides).go();
        await db.delete(db.orderTaxes).go();
        await db.delete(db.orderItems).go();
        await db.delete(db.returns).go();
        await db.delete(db.orders).go();
        await db.delete(db.expenses).go();
        await db.delete(db.productTaxes).go();
        await db.delete(db.productModifiers).go();
        await db.delete(db.productVariants).go();
        await db.delete(db.productComponents).go();
        await db.delete(db.products).go();
        await db.delete(db.customers).go();
        await db.delete(db.categories).go();
        await db.delete(db.taxGroupMembers).go();
        await db.delete(db.taxGroups).go();
        await db.delete(db.taxRates).go();
        await db.delete(db.expenseCategories).go();
        await db.delete(db.auditLog).go();
        await db.delete(db.outboxQueue).go();
      });

      await box.clear();
      ref.invalidate(onboardingCompleteProvider);
      await Future.delayed(Duration.zero);

      if (context.mounted) context.go('/onboarding');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e')),
        );
      }
    }
  }
}
