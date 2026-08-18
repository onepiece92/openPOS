import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
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

  void setTaxName(String value) => state = state.copyWith(taxName: value.trim());
  void setTaxRate(double value) => state = state.copyWith(taxRate: value);

  void next() => state = state.copyWith(step: state.step + 1);
  void back() => state = state.copyWith(step: state.step - 1);

  void setSaving(bool value) => state = state.copyWith(saving: value);

  Future<void> finish() async {
    state = state.copyWith(saving: true);

    final box = ref.read(settingsBoxProvider);
    final db = ref.read(databaseProvider);
    final settings = ref.read(settingsProvider.notifier);

    // Save store profile
    await settings.setStoreProfile(name: state.businessName);
    await settings.setCurrency(
      symbol: state.country?.symbol ?? '\$',
      code: state.country?.currency ?? 'USD',
    );
    await settings.setLocale(
      countryCode: state.country?.code ?? '',
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

    await settings.setOnboardingComplete(true);
    state = state.copyWith(saving: false);
  }

  Future<void> skip() async {
    state = state.copyWith(saving: true);
    await ref.read(settingsProvider.notifier).setOnboardingComplete(true);
    state = state.copyWith(saving: false);
  }
}

final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
