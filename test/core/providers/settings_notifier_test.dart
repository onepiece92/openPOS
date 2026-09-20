import 'dart:io';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/providers/hive_provider.dart';

/// [SettingsNotifier] against a real Hive box in a temp dir: state updates
/// synchronously, selectors rebuild without `ref.invalidate`, and every write
/// survives a cold re-read of the box.
void main() {
  late Directory tmp;
  late Box<dynamic> box;

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [settingsBoxProvider.overrideWithValue(box)],
      );

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_settings_');
    Hive.init(tmp.path);
    box = await Hive.openBox<dynamic>('settings');
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  test('defaults when the box is empty', () {
    final c = makeContainer();
    addTearDown(c.dispose);
    final s = c.read(settingsProvider);
    expect(s.onboardingComplete, isFalse);
    expect(s.themeMode, ThemeMode.system);
    expect(s.lowStockThreshold, 5);
    expect(s.currencySymbol, 'Rs');
    expect(s.printerPaperWidth, 80);
    expect(s.autoBackupEnabled, isTrue);
    expect(s.businessNameOrDefault, 'My Store');
  });

  test('setter updates state synchronously and persists to the box',
      () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final notifier = c.read(settingsProvider.notifier);

    final future = notifier.setStoreProfile(name: 'Bhatbhateni', pan: '123');
    // State is already new before the Hive write completes.
    expect(c.read(settingsProvider).businessName, 'Bhatbhateni');
    await future;

    expect(box.get(kBusinessName), 'Bhatbhateni');
    expect(box.get(kBusinessPan), '123');
    expect(box.get(kBusinessPhone), isNull); // untouched fields not written
  });

  test('field selectors react — no invalidate needed', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final seen = <String>[];
    c.listen(businessNameProvider, (_, next) => seen.add(next),
        fireImmediately: true);

    await c.read(settingsProvider.notifier).setStoreProfile(name: 'A');
    await c.read(settingsProvider.notifier).setStoreProfile(name: 'B');
    // Unrelated write must not re-fire the businessName selector.
    await c.read(settingsProvider.notifier).setLowStockThreshold(9);

    expect(seen, ['', 'A', 'B']);
  });

  test('every write is visible to a fresh container (cold read)', () async {
    final c1 = makeContainer();
    final n = c1.read(settingsProvider.notifier);
    await n.setOnboardingComplete(true);
    await n.setThemeMode(ThemeMode.dark);
    await n.setDefaultTaxId(7);
    await n.setLoyaltyEnabled(true);
    await n.setLoyaltyRates(earnRate: 0.02, pointValue: 0.5);
    await n.setPrinterDevice(
        address: 'AA:BB', name: 'Rongta', driver: 'star');
    await n.setPrinterPaperWidth(58);
    await n.setCurrency(symbol: '\$', code: 'USD');
    await n.setLocale(countryCode: 'US', timezone: 'America/New_York');
    await n.setAutoBackupEnabled(false);
    await n.markAutoBackupRun(DateTime(2026, 8, 18, 9));
    c1.dispose();

    final c2 = makeContainer();
    addTearDown(c2.dispose);
    final s = c2.read(settingsProvider);
    expect(s.onboardingComplete, isTrue);
    expect(s.themeMode, ThemeMode.dark);
    expect(s.defaultTaxId, 7);
    expect(s.loyaltyEnabled, isTrue);
    expect(s.loyaltyEarnRate, 0.02);
    expect(s.loyaltyPointValue, 0.5);
    expect(s.printerDeviceAddress, 'AA:BB');
    expect(s.printerDeviceName, 'Rongta');
    expect(s.printerPaperWidth, 58);
    expect(s.currencySymbol, '\$');
    expect(s.currencyCode, 'USD');
    expect(s.countryCode, 'US');
    expect(s.timezone, 'America/New_York');
    expect(s.autoBackupEnabled, isFalse);
    expect(s.autoBackupLastAt, DateTime(2026, 8, 18, 9));
    expect(s.printerDriver, 'star',
        reason: 'the driver that found the printer must survive a restart, '
            'or a Star printer gets sent ESC/POS text it cannot read');
  });

  test('pairing a printer records the driver alongside the device', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final n = c.read(settingsProvider.notifier);

    await n.setPrinterDevice(
        address: '00:11:62:00:00:00', name: 'TSP100III', driver: 'star');
    expect(c.read(printerDriverProvider), 'star');
    expect(box.get(kPrinterDriver), 'star');

    // Re-pairing a generic printer must not leave the Star driver behind.
    await n.setPrinterDevice(
        address: 'AA:BB', name: 'Rongta', driver: 'escpos');
    expect(c.read(printerDriverProvider), 'escpos');
  });

  test('a device saved before drivers existed reads back as escpos', () async {
    await box.put(kPrinterDeviceAddress, 'AA:BB');
    await box.put(kPrinterDeviceName, 'Rongta');

    final c = makeContainer();
    addTearDown(c.dispose);
    expect(c.read(printerDriverProvider), 'escpos');
  });

  test('clearing values deletes the keys', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final n = c.read(settingsProvider.notifier);
    await n.setDefaultTaxId(3);
    await n.setPrinterDevice(address: 'X', name: 'Y', driver: 'escpos');

    await n.setDefaultTaxId(null);
    await n.clearPrinterDevice();

    expect(c.read(defaultTaxIdProvider), isNull);
    expect(c.read(printerDeviceAddressProvider), isNull);
    expect(box.containsKey(kPrinterDeviceAddress), isFalse);
    expect(box.containsKey(kPrinterDeviceName), isFalse);
  });

  test('tolerates legacy value types written by older builds', () async {
    await box.put(kPrinterPaperWidth, '58'); // old builds stored a String
    await box.put(kLoyaltyEarnRate, 2); // int instead of double
    final c = makeContainer();
    addTearDown(c.dispose);
    expect(c.read(printerPaperWidthProvider), 58);
    expect(c.read(loyaltyEarnRateProvider), 2.0);
  });

  test('reload() picks up an externally cleared box (factory reset)',
      () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c.read(settingsProvider.notifier).setOnboardingComplete(true);
    await box.clear();
    expect(c.read(onboardingCompleteProvider), isTrue); // stale until reload
    c.read(settingsProvider.notifier).reload();
    expect(c.read(onboardingCompleteProvider), isFalse);
  });
}
