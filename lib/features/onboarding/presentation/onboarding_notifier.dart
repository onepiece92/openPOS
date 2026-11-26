import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/onboarding/data/country_repository.dart';
import 'package:pos_app/features/onboarding/domain/business_type.dart';
import 'package:pos_app/features/onboarding/domain/locale_country.dart';
import 'package:pos_app/features/onboarding/domain/country_default.dart';
import 'package:pos_app/features/onboarding/domain/onboarding_state.dart';

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => OnboardingState(
      defaultTaxesOn: ref.read(featureFlagsProvider).stored(Feature.taxes));

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

  /// "Start minimal": every optional feature off except Review reminder
  /// and Usage counting (on in every preset); Auto-print off.
  void startMinimal() => state = state.copyWith(switches: {
        for (final f in Feature.values) f: kAlwaysSuggested.contains(f),
      });

  void next() => state = state.copyWith(step: state.step + 1);
  void back() => state = state.copyWith(step: state.step - 1);

  void setSaving(bool value) => state = state.copyWith(saving: value);

  bool _passed(OnboardingStep s) => state.passed(s);

  /// Writes the switches (features_v1), the business type and whether the
  /// "turn features on or off" intro is still due. The switches decide
  /// Taxes; the tax step's rate never turns it on or off.
  Future<void> _saveFeatures() async {
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
    };
    await settings.setFeatures(values);
    // The suggestions step showed what Features does: no drawer intro.
    // Skipped before it: a fresh install gets the neutral line, not "New:".
    if (_passed(OnboardingStep.businessType)) {
      await settings.markFeaturesIntroSeen();
    } else {
      await settings.markFeaturesIntroFresh();
    }
  }

  /// Saves what setup has collected. [all] (Finish): every step, with the
  /// existing fallbacks for blank ones. Otherwise (Skip) only the steps
  /// already passed, so a skip keeps the name, country and currency the
  /// shopkeeper entered — and nothing they never saw.
  Future<void> _saveProfile({required bool all}) async {
    final db = ref.read(databaseProvider);
    final settings = ref.read(settingsProvider.notifier);

    // A blank name stays blank: businessNameOrDefault prints "My Store"
    // until one is set.
    if (all || _passed(OnboardingStep.name) || state.businessName.isNotEmpty) {
      await settings.setStoreProfile(name: state.businessName);
    }
    // The country (and with it the currency) is always saved: the one on
    // screen (picked, or pre-selected from the device region), else the
    // region's — so Skip and a blank Finish give the same result. A region
    // that isn't in the data: USD, no country, no timezone.
    final country = await resolveSetupCountry(ref, state.country);
    await settings.setCurrency(symbol: country.symbol, code: country.currency);
    await settings.setLocale(
        countryCode: country.code, timezone: country.timezone);

    // A tax rate only with Taxes on and a rate > 0 given on the Tax step:
    // a blank (0) rate creates no "Tax 0%" (stored as decimal: 13% → 0.13).
    if (state.taxesOn &&
        (all || _passed(OnboardingStep.tax)) &&
        state.taxRate > 0) {
      final taxId = await db.taxDao.upsertRate(
        TaxRatesCompanion.insert(
          name: state.taxName.isNotEmpty ? state.taxName : 'Tax',
          rate: state.taxRate / 100.0,
          inclusionType: const Value('exclusive'),
          roundingMode: const Value('half_up'),
        ),
      );
      await settings.setDefaultTaxId(taxId);
    }
  }

  Future<void> finish() async {
    state = state.copyWith(saving: true);

    final box = ref.read(settingsBoxProvider);
    final settings = ref.read(settingsProvider.notifier);

    await _saveProfile(all: true);

    // Seed checklist state
    await box.put('checklist_state', {
      'add_product': false,
      'connect_printer': false,
      'make_sale': false,
      'backup': false,
    });

    await _saveFeatures();
    await settings.setOnboardingComplete(true);
    state = state.copyWith(saving: false);
  }

  /// Skip (on any step): what was entered so far, and the switches chosen
  /// so far (or the defaults).
  Future<void> skip() async {
    state = state.copyWith(saving: true);
    await _saveProfile(all: false);
    await _saveFeatures();
    await ref.read(settingsProvider.notifier).setOnboardingComplete(true);
    state = state.copyWith(saving: false);
  }
}

final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);

/// The country setup saves (and Confirm shows): the one [picked] on screen,
/// else the device region's from the bundled data (the US when the locale
/// has no region), else [kUnmatchedCountry] (USD, no country). Loads the
/// country data itself, so it is right even before the Country step's own
/// list has loaded. The region is read here, at setup only.
Future<CountryDefault> resolveSetupCountry(
    Ref ref, CountryDefault? picked) async {
  if (picked != null) return picked;
  List<CountryDefault> countries;
  try {
    countries = await CountryRepository.load();
  } catch (_) {
    countries = const [];
  }
  return countryForRegion(countries, ref.read(deviceRegionProvider)) ??
      kUnmatchedCountry;
}

/// What Finish will save as the country: Confirm reads this, so it never
/// disagrees with [OnboardingNotifier.finish].
final setupCountryProvider = FutureProvider.autoDispose<CountryDefault>((ref) =>
    resolveSetupCountry(
        ref, ref.watch(onboardingNotifierProvider.select((s) => s.country))));
