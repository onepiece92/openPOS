import 'package:pos_app/features/onboarding/domain/country_default.dart';

class OnboardingState {
  final int step; // 0–3
  final String businessName;
  final CountryDefault? country;
  final String taxName;
  final double taxRate; // percentage, e.g. 13.0 for 13%
  final bool saving;

  const OnboardingState({
    this.step = 0,
    this.businessName = '',
    this.country,
    this.taxName = '',
    this.taxRate = 0.0,
    this.saving = false,
  });

  OnboardingState copyWith({
    int? step,
    String? businessName,
    CountryDefault? country,
    String? taxName,
    double? taxRate,
    bool? saving,
  }) =>
      OnboardingState(
        step: step ?? this.step,
        businessName: businessName ?? this.businessName,
        country: country ?? this.country,
        taxName: taxName ?? this.taxName,
        taxRate: taxRate ?? this.taxRate,
        saving: saving ?? this.saving,
      );
}
