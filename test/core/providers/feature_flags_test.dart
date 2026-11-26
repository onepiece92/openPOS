import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/providers/hive_provider.dart';

import '../../_support/temp_hive.dart';

void main() {
  group('effective flags', () {
    test('a child is off while its parent is off; its own switch is kept', () {
      final f = FeatureFlags.only(const {Feature.loyalty, Feature.tables,
        Feature.bundles});
      expect(f.stored(Feature.loyalty), isTrue);
      expect(f.loyalty, isFalse, reason: 'needs Customers');
      expect(f.tables, isFalse, reason: 'needs Held tickets');
      expect(f.bundles, isFalse, reason: 'needs Stock tracking');

      final back = f
          .withStored(Feature.customers, true)
          .withStored(Feature.heldTickets, true)
          .withStored(Feature.stockTracking, true);
      expect(back.loyalty, isTrue);
      expect(back.tables, isTrue);
      expect(back.bundles, isTrue);
    });

    test('every parent is declared before its children', () {
      for (final f in Feature.values) {
        final p = f.parent;
        if (p != null) expect(p.index, lessThan(f.index), reason: f.name);
      }
    });

    test('a parent switched off and on brings the child back as it was', () {
      final on = FeatureFlags.only(const {Feature.customers, Feature.loyalty});
      final off = on.withStored(Feature.customers, false);
      expect(off.loyalty, isFalse);
      expect(off.withStored(Feature.customers, true).loyalty, isTrue);
    });
  });

  group('stored in the settings box', () {
    late Box<dynamic> box;
    ProviderContainer container() {
      final c = ProviderContainer(
          overrides: [settingsBoxProvider.overrideWithValue(box)]);
      addTearDown(c.dispose);
      return c;
    }

    setUp(() async => box = await openTempSettingsBox());

    test('upgrade: no features_v1 means every existing feature is on, and '
        'loyalty follows its own key', () async {
      await box.put(kLoyaltyEnabled, true);
      final flags = container().read(featureFlagsProvider);
      for (final f in Feature.values) {
        // Tips and End-of-day close stay off until someone turns them on.
        expect(flags.isOn(f), f != Feature.tips && f != Feature.endOfDay,
            reason: f.name);
      }
      await box.put(kLoyaltyEnabled, false);
      expect(AppSettings.fromBox(box).features.loyalty, isFalse);
      expect(AppSettings.fromBox(box).features.customers, isTrue);
    });

    test('setFeature persists to features_v1 and reads back cold', () async {
      final c = container();
      final n = c.read(settingsProvider.notifier);
      await n.setFeature(Feature.tables, false);
      await n.setFeature(Feature.expenses, false);
      expect(c.read(featureOnProvider(Feature.tables)), isFalse);

      final raw = box.get(kFeaturesKey) as Map;
      expect(raw['tables'], isFalse);
      expect(raw['expenses'], isFalse);
      expect(raw['customers'], isTrue);
      expect(raw.containsKey('loyalty'), isFalse,
          reason: 'loyalty keeps kLoyaltyEnabled');

      final cold = AppSettings.fromBox(box).features;
      expect(cold.tables, isFalse);
      expect(cold.expenses, isFalse);
      expect(cold.heldTickets, isTrue);
    });

    test('loyalty writes kLoyaltyEnabled, the one source of truth', () async {
      final c = container();
      await c
          .read(settingsProvider.notifier)
          .setFeature(Feature.loyalty, true);
      expect(box.get(kLoyaltyEnabled), isTrue);
      expect(c.read(loyaltyEnabledProvider), isTrue);
      await c.read(settingsProvider.notifier).setLoyaltyEnabled(false);
      expect(c.read(featureOnProvider(Feature.loyalty)), isFalse);
    });

    test('a corrupt value falls back to the default', () async {
      await box.put(kFeaturesKey, {'taxes': 'no', 'units': false, 'x': 1});
      final f = AppSettings.fromBox(box).features;
      expect(f.taxes, isTrue);
      expect(f.units, isFalse);
      await box.put(kFeaturesKey, 'garbage');
      expect(AppSettings.fromBox(box).features.units, isTrue);
    });

    test('a per-feature selector does not fire for another flag', () async {
      final c = container();
      var fired = 0;
      c.listen(featureOnProvider(Feature.customers), (_, __) => fired++);
      await c.read(settingsProvider.notifier).setFeature(Feature.taxes, false);
      await pumpEventQueue();
      expect(fired, 0);
      await c
          .read(settingsProvider.notifier)
          .setFeature(Feature.customers, false);
      await pumpEventQueue();
      expect(fired, 1);
    });
  });
}
