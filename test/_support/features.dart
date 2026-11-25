import 'package:pos_app/core/providers/hive_provider.dart';

/// Every feature switch on, without a settings box: for tests of
/// behaviour that existed before Features (where everything was on).
final allFeaturesOn = featureFlagsProvider
    .overrideWithValue(FeatureFlags.only(Feature.values.toSet()));
