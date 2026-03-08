import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/features/onboarding/data/country_repository.dart';
import 'package:pos_app/features/onboarding/domain/country_default.dart';
import 'package:pos_app/features/onboarding/domain/onboarding_state.dart';
import 'package:pos_app/features/onboarding/presentation/onboarding_notifier.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _businessNameCtrl = TextEditingController();
  final _taxNameCtrl = TextEditingController();
  final _taxRateCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  List<CountryDefault> _countries = [];
  List<CountryDefault> _filtered = [];
  bool _loadingCountries = true;

  @override
  void initState() {
    super.initState();
    _businessNameCtrl.addListener(() {
      ref
          .read(onboardingNotifierProvider.notifier)
          .setBusinessName(_businessNameCtrl.text);
    });
    _taxNameCtrl.addListener(() {
      ref
          .read(onboardingNotifierProvider.notifier)
          .setTaxName(_taxNameCtrl.text);
    });
    _taxRateCtrl.addListener(() {
      final v = double.tryParse(_taxRateCtrl.text);
      if (v != null) {
        ref.read(onboardingNotifierProvider.notifier).setTaxRate(v);
      }
    });
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final countries = await CountryRepository.load();
    if (!mounted) return;
    final nepal = countries.firstWhere(
      (c) => c.code == 'NP',
      orElse: () => countries.first,
    );
    ref.read(onboardingNotifierProvider.notifier).setCountry(nepal);
    _taxNameCtrl.text = nepal.taxName;
    _taxRateCtrl.text = nepal.taxRate.toStringAsFixed(1);
    setState(() {
      _countries = countries;
      _filtered = countries;
      _loadingCountries = false;
    });
  }

  void _filterCountries(String q) {
    final ql = q.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _countries
          : _countries
              .where(
                (c) =>
                    c.name.toLowerCase().contains(ql) ||
                    c.currency.toLowerCase().contains(ql) ||
                    c.code.toLowerCase().contains(ql),
              )
              .toList();
    });
  }

  void _selectCountry(CountryDefault c) {
    ref.read(onboardingNotifierProvider.notifier).setCountry(c);
    _taxNameCtrl.text = c.taxName;
    _taxRateCtrl.text = c.taxRate.toStringAsFixed(1);
  }

  bool _canProceed(OnboardingState state) {
    switch (state.step) {
      case 0:
        return state.businessName.isNotEmpty;
      case 1:
        return state.country != null;
      default:
        return true;
    }
  }

  void _next() {
    final state = ref.read(onboardingNotifierProvider);
    if (!_canProceed(state)) return;
    if (state.step < 3) {
      ref.read(onboardingNotifierProvider.notifier).next();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    final state = ref.read(onboardingNotifierProvider);
    if (state.step > 0) {
      ref.read(onboardingNotifierProvider.notifier).back();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    try {
      await ref.read(onboardingNotifierProvider.notifier).finish();
      // Wait one frame so the router reacts to the invalidated provider.
      await Future.delayed(Duration.zero);
      if (mounted) context.go('/pos');
    } catch (e) {
      ref.read(onboardingNotifierProvider.notifier).setSaving(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup failed: $e')),
        );
      }
    }
  }

  Future<void> _skip() async {
    await ref.read(onboardingNotifierProvider.notifier).skip();
    await Future.delayed(Duration.zero);
    if (mounted) context.go('/pos');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameCtrl.dispose();
    _taxNameCtrl.dispose();
    _taxRateCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _WizardHeader(step: state.step, onSkip: state.saving ? null : _skip),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _BusinessNameStep(controller: _businessNameCtrl),
                  _CountryStep(
                    countries: _filtered,
                    loading: _loadingCountries,
                    selected: state.country,
                    searchController: _searchCtrl,
                    onSearch: _filterCountries,
                    onSelect: _selectCountry,
                  ),
                  _TaxStep(
                    nameController: _taxNameCtrl,
                    rateController: _taxRateCtrl,
                    currencySymbol: state.country?.symbol ?? '\$',
                  ),
                  _ConfirmStep(state: state),
                ],
              ),
            ),
            _NavBar(
              step: state.step,
              saving: state.saving,
              canNext: _canProceed(state),
              onBack: _back,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.step, this.onSkip});
  final int step;
  final VoidCallback? onSkip;

  static const _labels = ['Business', 'Country', 'Tax', 'Confirm'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
                    '${step + 1} of 4',
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
              value: (step + 1) / 4,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(4, (i) {
              final active = i == step;
              final done = i < step;
              return Expanded(
                child: Center(
                  child: Text(
                    _labels[i],
                    style: tt.labelSmall?.copyWith(
                      color: (done || active)
                          ? cs.primary
                          : cs.onSurfaceVariant.withAlpha(100),
                      fontWeight:
                          active ? FontWeight.bold : FontWeight.normal,
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

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.step,
    required this.saving,
    required this.canNext,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final bool saving;
  final bool canNext;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Row(
        children: [
          if (step > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onBack,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: canNext && !saving ? onNext : null,
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(step < 3 ? 'Continue' : 'Finish Setup'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 0: Business Name ────────────────────────────────────────────────────

class _BusinessNameStep extends StatelessWidget {
  const _BusinessNameStep({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.storefront_rounded,
                size: 44,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'What\'s your business called?',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This will appear on receipts and reports.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Business name',
              hintText: 'e.g. Rebuzz Store',
              prefixIcon: Icon(Icons.business_rounded),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Country ──────────────────────────────────────────────────────────

class _CountryStep extends StatelessWidget {
  const _CountryStep({
    required this.countries,
    required this.loading,
    required this.selected,
    required this.searchController,
    required this.onSearch,
    required this.onSelect,
  });

  final List<CountryDefault> countries;
  final bool loading;
  final CountryDefault? selected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<CountryDefault> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where are you located?',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Sets your currency, timezone, and default tax.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            searchController.clear();
                            onSearch('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: countries.length,
                  itemBuilder: (context, i) {
                    final c = countries[i];
                    final isSelected = selected?.code == c.code;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: cs.primaryContainer.withAlpha(80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? cs.primary
                            : cs.surfaceContainerHighest,
                        child: Text(
                          c.code,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? cs.onPrimary
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      title: Text(
                        c.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${c.currency} (${c.symbol})  •  ${c.taxName} ${c.taxRate}%',
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: cs.primary)
                          : null,
                      onTap: () => onSelect(c),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Step 2: Tax ──────────────────────────────────────────────────────────────

class _TaxStep extends StatelessWidget {
  const _TaxStep({
    required this.nameController,
    required this.rateController,
    required this.currencySymbol,
  });

  final TextEditingController nameController;
  final TextEditingController rateController;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.percent_rounded,
                size: 44,
                color: cs.onTertiaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Set up your tax rate',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ve pre-filled values from your selected country. You can customise them here.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Tax name',
              hintText: 'e.g. VAT, GST, Sales Tax',
              prefixIcon: Icon(Icons.label_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: rateController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Tax rate (%)',
              hintText: '13.0',
              prefixIcon: Icon(Icons.percent_rounded),
              border: OutlineInputBorder(),
              suffixText: '%',
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tax is calculated as exclusive — added on top of the item price.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 3: Confirm ──────────────────────────────────────────────────────────

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({required this.state});
  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 44,
                color: cs.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'You\'re all set!',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s a summary of your store setup.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          _SummaryCard(
            children: [
              _SummaryRow(
                icon: Icons.storefront_rounded,
                label: 'Business',
                value: state.businessName,
              ),
              _SummaryRow(
                icon: Icons.location_on_rounded,
                label: 'Country',
                value: state.country?.name ?? '—',
              ),
              _SummaryRow(
                icon: Icons.currency_exchange_rounded,
                label: 'Currency',
                value: state.country != null
                    ? '${state.country!.currency} (${state.country!.symbol})'
                    : '—',
              ),
              _SummaryRow(
                icon: Icons.schedule_rounded,
                label: 'Timezone',
                value: state.country?.timezone ?? '—',
              ),
              _SummaryRow(
                icon: Icons.percent_rounded,
                label: state.taxName.isNotEmpty ? state.taxName : 'Tax',
                value: '${state.taxRate.toStringAsFixed(1)}%',
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'You can change these later in Settings.',
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 12),
              Text(
                label,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                value,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: cs.outlineVariant,
          ),
      ],
    );
  }
}
