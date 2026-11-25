import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/onboarding/domain/business_type.dart';
import 'package:pos_app/features/onboarding/domain/country_default.dart';
import 'package:pos_app/features/onboarding/domain/onboarding_state.dart';

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void setBusinessName(String value) =>
      state = state.copyWith(businessName: value.trim());

  void setCountry(CountryDefault country) => state = state.copyWith(
        country: country,
        taxName: country.taxName,
        taxRate: country.taxRate,
      );

  void setTaxName(String value) =>
      state = state.copyWith(taxName: value.trim());
  void setTaxRate(double value) => state = state.copyWith(taxRate: value);

  /// Picks a business type and pre-sets every switch from its preset.
  void setBusinessType(BusinessType type) => state =
      state.copyWith(businessType: type, switches: presetSwitches(type));

  /// The switches the suggestions step shows: the preset's, or the
  /// defaults (every existing feature on) when no type was picked.
  Map<Feature, bool> get shownSwitches =>
      state.switches ??
      {for (final f in Feature.values) f: _defaults.stored(f)};

  FeatureFlags get _defaults => ref.read(featureFlagsProvider);

  void setSwitch(Feature f, bool on) =>
      state = state.copyWith(switches: {...shownSwitches, f: on});

  /// "Start minimal": every optional feature off.
  void startMinimal() => state =
      state.copyWith(switches: {for (final f in Feature.values) f: false});

  void next() => state = state.copyWith(step: state.step + 1);
  void back() => state = state.copyWith(step: state.step - 1);

  void setSaving(bool value) => state = state.copyWith(saving: value);

  bool _passed(OnboardingStep s) => state.step > s.index;

  /// Writes the switches (features_v1), the business type and whether the
  /// "turn features on or off" intro is still due. [taxFromRate]: the tax
  /// step was passed, so Taxes follows its rate (> 0 = on).
  Future<void> _saveFeatures({required bool taxFromRate}) async {
    final settings = ref.read(settingsProvider.notifier);
    final type = state.businessType;
    if (type != null) await settings.setBusinessType(type.name);
    final chosen = state.switches;
    final values = <Feature, bool>{
      if (chosen != null)
        ...chosen
      else
        // No choice: keep the defaults, but say so in features_v1. Loyalty
        // keeps its own key untouched.
        for (final f in Feature.values)
          if (f != Feature.loyalty) f: _defaults.stored(f),
      if (taxFromRate) Feature.taxes: state.taxRate > 0,
    };
    await settings.setFeatures(values);
    // The suggestions step showed what Features does: no drawer intro.
    if (_passed(OnboardingStep.businessType)) {
      await settings.markFeaturesIntroSeen();
    }
  }

  Future<void> finish() async {
    state = state.copyWith(saving: true);

    final box = ref.read(settingsBoxProvider);
    final db = ref.read(databaseProvider);
    final settings = ref.read(settingsProvider.notifier);

    // Save store profile. A blank name stays blank: businessNameOrDefault
    // prints "My Store" until one is set.
    await settings.setStoreProfile(name: state.businessName);
    await settings.setCurrency(
      symbol: state.country?.symbol ?? '\$',
      code: state.country?.currency ?? 'USD',
    );
    await settings.setLocale(
      countryCode: state.country?.code ?? 'US',
      timezone: state.country?.timezone ?? 'UTC',
    );

    // Insert default tax rate (rate stored as decimal: 13% → 0.13)
    final taxId = await db.taxDao.upsertRate(
      TaxRatesCompanion.insert(
        name: state.taxName.isNotEmpty ? state.taxName : 'Tax',
        rate: state.taxRate / 100.0,
        inclusionType: const Value('exclusive'),
        roundingMode: const Value('half_up'),
      ),
    );
    await settings.setDefaultTaxId(taxId);

    // Seed checklist state
    await box.put('checklist_state', {
      'add_product': false,
      'connect_printer': false,
      'make_sale': false,
      'backup': false,
    });

    await _saveFeatures(taxFromRate: true);
    await settings.setOnboardingComplete(true);
    state = state.copyWith(saving: false);
  }

  /// Skip (on any step): the switches chosen so far, or the defaults.
  Future<void> skip() async {
    state = state.copyWith(saving: true);
    await _saveFeatures(taxFromRate: _passed(OnboardingStep.tax));
    await ref.read(settingsProvider.notifier).setOnboardingComplete(true);
    state = state.copyWith(saving: false);
  }
}

final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
