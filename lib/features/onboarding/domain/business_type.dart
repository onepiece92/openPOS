import 'package:pos_app/core/providers/feature_flags.dart';

/// "What kind of business?" — the first setup step. Stored as its [name]
/// under the settings key `business_type`; read back only through
/// [parseBusinessType].
enum BusinessType {
  foodTruck('Food truck or stand', 'food truck or stand'),
  cafe('Café or counter service', 'cafe or counter'),
  restaurant('Restaurant with tables', 'restaurant with tables'),
  retail('Retail shop', 'retail shop'),
  marketStall('Market stall or craft seller', 'market stall or craft seller'),
  services('Services (salon, repair)', 'services'),
  other('Something else', 'something else');

  const BusinessType(this.label, this.usageLabel);

  /// Shown in setup.
  final String label;

  /// The fixed lowercase text of the usage summary's "Business type:" line.
  final String usageLabel;
}

/// The stored value, or null for a missing or unknown one.
BusinessType? parseBusinessType(Object? raw) =>
    raw is String ? BusinessType.values.asNameMap()[raw] : null;

/// On in EVERY preset, the minimal ones and "Start minimal" included
/// (owner decision).
const kAlwaysSuggested = {Feature.reviewReminder, Feature.usageCounting};

/// The non-minimal presets also print automatically.
const _app = {...kAlwaysSuggested, Feature.autoPrint};

/// What setup suggests for each business type. Anything not listed is off.
/// Market stall and Something else are minimal: [kAlwaysSuggested] only.
/// A preset only sets switches: it never touches data.
///
/// TODO(tips, end-of-day): once those Feature values exist, add tips to
/// foodTruck, cafe, restaurant and services, and endOfDay to foodTruck,
/// cafe, restaurant and marketStall.
const Map<BusinessType, Set<Feature>> kPresets = {
  BusinessType.foodTruck: {
    ..._app,
    Feature.heldTickets,
    Feature.discounts,
    Feature.taxes,
    Feature.dashboardExtras,
  },
  BusinessType.cafe: {
    ..._app,
    Feature.heldTickets,
    Feature.discounts,
    Feature.taxes,
    Feature.customers,
    Feature.loyalty,
    Feature.dashboardExtras,
  },
  BusinessType.restaurant: {
    ..._app,
    Feature.tables,
    Feature.heldTickets,
    Feature.discounts,
    Feature.taxes,
    Feature.dashboardExtras,
  },
  BusinessType.retail: {
    ..._app,
    Feature.stockTracking,
    Feature.customers,
    Feature.discounts,
    Feature.taxes,
    Feature.units,
    Feature.bundles,
    Feature.costProfit,
    Feature.expenses,
    Feature.csvImportExport,
    Feature.dashboardExtras,
  },
  BusinessType.marketStall: kAlwaysSuggested,
  BusinessType.services: {
    ..._app,
    Feature.customers,
    Feature.discounts,
    Feature.taxes,
    Feature.expenses,
  },
  BusinessType.other: kAlwaysSuggested,
};

/// Every switch as [type]'s preset sets it.
Map<Feature, bool> presetSwitches(BusinessType type) => {
      for (final f in Feature.values) f: kPresets[type]!.contains(f),
    };
