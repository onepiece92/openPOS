import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/usage_providers.dart';

import '../../_support/temp_hive.dart';

/// Features → Usage counting and "Stop counting" are ONE flag
/// (features_v1), and the app's counter follows it.
void main() {
  late Box<dynamic> settings;
  late Box<dynamic> usage;

  setUp(() async {
    settings = await openTempSettingsBox(more: [kUsageBoxName]);
    usage = Hive.box<dynamic>(kUsageBoxName);
  });

  ProviderContainer container() {
    final c = ProviderContainer(
        overrides: [settingsBoxProvider.overrideWithValue(settings)]);
    addTearDown(c.dispose);
    return c;
  }

  test('the counter follows the switch; off = record returns at once',
      () async {
    final c = container();
    final counter = c.read(usageCounterProvider);
    await counter.ensureLoaded();
    counter.record(UsageEvent.saleCompleted);
    await c
        .read(settingsProvider.notifier)
        .setFeature(Feature.usageCounting, false);
    await pumpEventQueue();
    expect(counter.countingEnabled, isFalse);
    counter.record(UsageEvent.saleCompleted);
    expect(counter.counts[UsageEvent.saleCompleted]!.count, 1);
    expect(identical(c.read(usageCounterProvider), counter), isTrue,
        reason: 'the counter is never rebuilt by the switch');

    await c
        .read(settingsProvider.notifier)
        .setFeature(Feature.usageCounting, true);
    await pumpEventQueue();
    counter.record(UsageEvent.saleCompleted);
    expect(counter.counts[UsageEvent.saleCompleted]!.count, 2);
  });

  test('starts off when the switch is stored off', () async {
    await settings.put(kFeaturesKey, {'usageCounting': false});
    final counter = container().read(usageCounterProvider);
    counter.record(UsageEvent.saleCompleted);
    await counter.ensureLoaded();
    expect(counter.counts, isEmpty);
  });

  test('an older install\'s "Stop counting" moves onto the switch', () async {
    await usage.put(kUsageCountingOnKey, false);
    final c = container();
    await c.read(usageCounterProvider).ensureLoaded();
    expect(c.read(featureOnProvider(Feature.usageCounting)), isFalse);
    expect((settings.get(kFeaturesKey) as Map)['usageCounting'], isFalse);
    expect(usage.containsKey(kUsageCountingOnKey), isFalse);
  });

  test("a restore keeps this device's choice, not the backup's", () async {
    // Device: counting off. The restored settings box says on, and the
    // restored usage box carries an older backup's legacy flag.
    final snap = UsageSnapshot(
        counts: UsageSnapshot.of(usage).counts,
        countingOn: false); // what restoreFrom passes
    await settings.put(kFeaturesKey, {'usageCounting': true, 'taxes': false});
    await usage.put(kUsageCountingOnKey, true);
    await mergeUsageAfterRestore(snap);
    expect(usage.containsKey(kUsageCountingOnKey), isFalse);
    expect((settings.get(kFeaturesKey) as Map)['taxes'], isFalse,
        reason: "the other switches are the backup's");
    final c = container();
    await c.read(usageCounterProvider).ensureLoaded();
    expect(c.read(featureOnProvider(Feature.usageCounting)), isFalse);
  });

  test('usageSnapshotBeforeRestore carries the switch', () {
    expect(usageSnapshotBeforeRestore(countingOn: false)!.countingOn, isFalse);
  });
}
