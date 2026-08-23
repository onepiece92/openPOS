import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/features/onboarding/data/country_repository.dart';
import 'package:pos_app/features/onboarding/domain/country_default.dart';
import 'package:pos_app/features/onboarding/domain/onboarding_state.dart';
import 'package:pos_app/features/onboarding/presentation/onboarding_notifier.dart';
import 'package:pos_app/features/onboarding/presentation/widgets/business_name_step.dart';
import 'package:pos_app/features/onboarding/presentation/widgets/confirm_step.dart';
import 'package:pos_app/features/onboarding/presentation/widgets/country_step.dart';
import 'package:pos_app/features/onboarding/presentation/widgets/tax_step.dart';
import 'package:pos_app/features/onboarding/presentation/widgets/wizard_header.dart';
import 'package:pos_app/features/onboarding/presentation/widgets/wizard_nav_bar.dart';

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
            WizardHeader(step: state.step, onSkip: state.saving ? null : _skip),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  BusinessNameStep(controller: _businessNameCtrl),
                  CountryStep(
                    countries: _filtered,
                    loading: _loadingCountries,
                    selected: state.country,
                    searchController: _searchCtrl,
                    onSearch: _filterCountries,
                    onSelect: _selectCountry,
                  ),
                  TaxStep(
                    nameController: _taxNameCtrl,
                    rateController: _taxRateCtrl,
                    currencySymbol: state.country?.symbol ?? '\$',
                  ),
                  ConfirmStep(state: state),
                ],
              ),
            ),
            OnboardingNavBar(
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
