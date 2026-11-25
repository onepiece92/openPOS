import 'package:pos_app/core/providers/feature_flags.dart';
import 'package:pos_app/features/onboarding/domain/business_type.dart';
import 'package:pos_app/features/onboarding/domain/country_default.dart';

/// The setup steps, in order. The step count, the header and the nav bar
/// all come from this list.
enum OnboardingStep {
  businessType('Type'),
  features('Features'),
  name('Business'),
  country('Country'),
  tax('Tax'),
  confirm('Confirm');

  const OnboardingStep(this.label);

  /// Short label under the progress bar.
  final String label;
}

const kOnboardingSteps = OnboardingStep.values;

class OnboardingState {
  final int step; // index into kOnboardingSteps
  final String businessName;
  final CountryDefault? country;
  final String taxName;
  final double taxRate; // percentage, e.g. 13.0 for 13%
  final bool saving;

  /// Chosen in the first step; null when it was skipped.
  final BusinessType? businessType;

  /// The suggested switches as shown (and edited) in the second step; null
  /// until a business type is chosen or a switch is changed — then setup
  /// keeps the defaults (every existing feature on).
  final Map<Feature, bool>? switches;

  const OnboardingState({
    this.step = 0,
    this.businessName = '',
    this.country,
    this.taxName = '',
    this.taxRate = 0.0,
    this.saving = false,
    this.businessType,
    this.switches,
  });

  OnboardingStep get current => kOnboardingSteps[step];
  bool get isLast => step == kOnboardingSteps.length - 1;

  OnboardingState copyWith({
    int? step,
    String? businessName,
    CountryDefault? country,
    String? taxName,
    double? taxRate,
    bool? saving,
    BusinessType? businessType,
    Map<Feature, bool>? switches,
  }) =>
      OnboardingState(
        step: step ?? this.step,
        businessName: businessName ?? this.businessName,
        country: country ?? this.country,
        taxName: taxName ?? this.taxName,
        taxRate: taxRate ?? this.taxRate,
        saving: saving ?? this.saving,
        businessType: businessType ?? this.businessType,
        switches: switches ?? this.switches,
      );
}
