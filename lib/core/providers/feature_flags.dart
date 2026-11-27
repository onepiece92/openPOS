import 'package:flutter/foundation.dart' show immutable, listEquals;

/// Every optional part of the app that the shopkeeper can switch off in
/// Features, so the app stays as small as their shop needs.
///
/// Everything not listed here is always on (catalogue, cart, cash and card
/// payment, receipts, order history, refunds, core reports, backup, printer
/// setup and manual print, audit log, settings, help).
///
/// Order matters: it is the order of the Features screen, and a child is
/// listed straight after its parent.
///
enum Feature {
  customers('Customers', 'Keep a customer list and add a customer to a sale.'),
  loyalty('Loyalty points',
      'Customers earn points on sales and spend them at payment.',
      parent: Feature.customers),
  heldTickets('Held tickets', 'Save a cart as a ticket and finish it later.'),
  tables('Tables', 'Give a ticket a table, for table service.',
      parent: Feature.heldTickets),
  discounts('Discounts', 'Take an amount or a percentage off a sale.'),
  taxes('Taxes', 'Add tax to sales and keep a list of tax rates.'),
  tips('Tips', 'Add a tip at payment and track tips in reports.',
      defaultOn: false),
  endOfDay('End-of-day close',
      'Count the cash drawer, close the day and see or share a summary.',
      defaultOn: false),
  stockTracking('Stock tracking',
      'Count stock, take it off on each sale, and show low-stock badges.'),
  bundles('Bundles', 'Sell a product made of other products.',
      parent: Feature.stockTracking),
  units('Units', 'Sell a product in a second unit too, like a box or a dozen.'),
  costProfit('Cost and profit',
      'Record purchase prices and see cost of goods and net profit.'),
  expenses('Expenses', 'Record shop expenses and take them off profit.'),
  dashboardExtras('Dashboard extras',
      'Sales chart, payment mix and top products in Reports.'),
  csvImportExport('CSV import and export',
      'Move products, customers, expenses and orders in and out as CSV files.'),
  autoPrint('Auto-print receipts',
      'Print the receipt as soon as a sale is paid. Print by hand always works.'),
  reviewReminder('Review reminder',
      'Now and then, after a sale, ask for a store review or for feedback.'),
  usageCounting('Usage counting',
      'Count which features you use. The counts stay on this device.'),
  whatsNew('Show what\'s new after updates',
      'After a big update, show what changed, once. What\'s new in Support always works.'),
  themeToggle('Day/night button',
      'A sun/moon button at the top of the sales screen to switch light and dark.');

  const Feature(
    this.label,
    this.description, {
    this.parent,
    this.defaultOn = true,
  });

  /// Name on the Features screen.
  final String label;

  /// One plain line on what it does.
  final String description;

  /// The feature this one needs: it is off whenever its parent is off.
  final Feature? parent;

  /// The value when nothing is stored yet (an upgrade, or a skipped setup):
  /// on for every feature that existed before, off for a later one that
  /// must not appear by itself (Tips).
  final bool defaultOn;
}

/// Settings-box key of the stored switches: a map of [Feature.name] → bool.
/// Loyalty is not in it: `kLoyaltyEnabled` stays its source of truth.
const kFeaturesKey = 'features_v1';

/// The feature switches, read once from the settings box with the rest of
/// `AppSettings`.
///
/// [stored] is what each switch says; the getters ([isOn], [customers], …)
/// are the EFFECTIVE values — the own switch AND every parent's. A child's
/// stored value survives its parent being switched off, so turning
/// Customers back on brings Loyalty back as it was.
@immutable
class FeatureFlags {
  FeatureFlags._(this._own) : _on = _effective(_own);

  /// Every feature at its default.
  factory FeatureFlags.defaults({bool loyalty = false}) =>
      FeatureFlags.fromStored(const {}, loyalty: loyalty);

  /// From the `features_v1` map (anything not a bool, or missing, is the
  /// default) and the loyalty switch.
  factory FeatureFlags.fromStored(Map<Object?, Object?> raw,
          {required bool loyalty}) =>
      FeatureFlags._(List.unmodifiable([
        for (final f in Feature.values)
          if (f == Feature.loyalty)
            loyalty
          else
            switch (raw[f.name]) { final bool v => v, _ => f.defaultOn },
      ]));

  /// Every switch exactly as given; features left out are off.
  factory FeatureFlags.only(Set<Feature> on) => FeatureFlags._(
      List.unmodifiable([for (final f in Feature.values) on.contains(f)]));

  final List<bool> _own;
  final List<bool> _on;

  static List<bool> _effective(List<bool> own) {
    final on = List<bool>.filled(own.length, false);
    // Parents are declared before their children, so one pass is enough.
    for (final f in Feature.values) {
      final p = f.parent;
      on[f.index] = own[f.index] && (p == null || on[p.index]);
    }
    return List.unmodifiable(on);
  }

  /// What [f]'s own switch says, whatever its parent says.
  bool stored(Feature f) => _own[f.index];

  /// Whether [f] is on: its own switch and its parent's.
  bool isOn(Feature f) => _on[f.index];

  /// A copy with [f]'s own switch set to [on].
  FeatureFlags withStored(Feature f, bool on) =>
      FeatureFlags._(List.unmodifiable([..._own]..[f.index] = on));

  /// The `features_v1` map to store: every switch but loyalty.
  Map<String, bool> toStored() => {
        for (final f in Feature.values)
          if (f != Feature.loyalty) f.name: _own[f.index],
      };

  bool get customers => isOn(Feature.customers);
  bool get loyalty => isOn(Feature.loyalty);
  bool get heldTickets => isOn(Feature.heldTickets);
  bool get tables => isOn(Feature.tables);
  bool get discounts => isOn(Feature.discounts);
  bool get taxes => isOn(Feature.taxes);
  bool get tips => isOn(Feature.tips);
  bool get endOfDay => isOn(Feature.endOfDay);
  bool get stockTracking => isOn(Feature.stockTracking);
  bool get bundles => isOn(Feature.bundles);
  bool get units => isOn(Feature.units);
  bool get costProfit => isOn(Feature.costProfit);
  bool get expenses => isOn(Feature.expenses);
  bool get dashboardExtras => isOn(Feature.dashboardExtras);
  bool get csvImportExport => isOn(Feature.csvImportExport);
  bool get autoPrint => isOn(Feature.autoPrint);
  bool get reviewReminder => isOn(Feature.reviewReminder);
  bool get usageCounting => isOn(Feature.usageCounting);

  @override
  bool operator ==(Object other) =>
      other is FeatureFlags && listEquals(other._own, _own);

  @override
  int get hashCode => Object.hashAll(_own);

  @override
  String toString() => 'FeatureFlags(${[
        for (final f in Feature.values)
          if (isOn(f)) f.name
      ].join(', ')})';
}
