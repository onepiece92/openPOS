import 'package:pos_app/core/providers/feature_flags.dart';
import 'package:pos_app/features/onboarding/domain/business_type.dart';
import 'package:pos_app/features/onboarding/domain/country_default.dart';

/// Every setup step, in order. The steps a run actually shows are
/// [OnboardingState.steps] (the Tax step only while Taxes is on); the
/// step count, the header and the nav bar all come from that list.
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
  final int step; // index into [steps]
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
    this.defaultTaxesOn = true,
  });

  /// Taxes when no switch was chosen yet (the stored default).
  final bool defaultTaxesOn;

  /// Taxes as the chosen switches say — they decide, never the pre-fill.
  bool get taxesOn => switches?[Feature.taxes] ?? defaultTaxesOn;

  /// The steps of this run: the Tax step is skipped while Taxes is off.
  List<OnboardingStep> get steps => [
        for (final s in OnboardingStep.values)
          if (s != OnboardingStep.tax || taxesOn) s,
      ];

  /// Whether [s] is in this run and already behind the current step.
  bool passed(OnboardingStep s) {
    final i = steps.indexOf(s);
    return i >= 0 && step > i;
  }

  OnboardingStep get current => steps[step];
  bool get isLast => step == steps.length - 1;

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
        defaultTaxesOn: defaultTaxesOn,
      );
}
