import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ── Box keys ─────────────────────────────────────────────────────────────────

const _kOnboardingComplete = 'onboarding_complete';
const _kThemeMode = 'theme_mode'; // 'dark' | 'light' | 'system'
const _kDefaultTaxId = 'default_tax_id';
const _kLowStockThreshold = 'low_stock_threshold';
const _kPrinterConfig = 'printer_config'; // JSON
const _kBrandConfig = 'brand_config'; // JSON
const _kChecklistState = 'checklist_state'; // JSON
const kLoyaltyEnabled = 'loyalty_enabled';
const kLoyaltyEarnRate = 'loyalty_earn_rate'; // pts earned per 1 currency unit spent
const kLoyaltyPointValue = 'loyalty_point_value'; // currency value of 1 pt

// Store profile keys
const kBusinessName = 'business_name';
const kBusinessTagline = 'business_tagline';
const kBusinessPhone = 'business_phone';
const kBusinessAddress = 'business_address';
const kBusinessPan = 'business_pan';
const kCurrencySymbol = 'currency_symbol';
const kCurrencyCode = 'currency_code';

// ── Raw box providers ─────────────────────────────────────────────────────────

/// The 'settings' box must be opened in main() before ProviderScope starts.
final settingsBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>('settings');
});

final brandBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>('brand');
});

final printerBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>('printer');
});

// ── Derived preference providers ──────────────────────────────────────────────

/// True once the first-run setup wizard has been completed.
final onboardingCompleteProvider = Provider<bool>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return box.get(_kOnboardingComplete, defaultValue: false) as bool;
});

/// Current ThemeMode. Defaults to system.
final savedThemeModeProvider = Provider<ThemeMode>((ref) {
  final box = ref.watch(settingsBoxProvider);
  final raw = box.get(_kThemeMode, defaultValue: 'system') as String;
  return switch (raw) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => ThemeMode.system,
  };
});

/// Store-wide default tax rate ID (null = no default set yet).
final defaultTaxIdProvider = Provider<int?>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return box.get(_kDefaultTaxId) as int?;
});

/// Low-stock alert threshold (unit count). Default 5.
final lowStockThresholdProvider = Provider<int>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return box.get(_kLowStockThreshold, defaultValue: 5) as int;
});

// ── Write helpers (called from notifiers) ─────────────────────────────────────

Future<void> saveOnboardingComplete(Box<dynamic> box) =>
    box.put(_kOnboardingComplete, true);

Future<void> saveThemeMode(Box<dynamic> box, ThemeMode mode) {
  final raw = switch (mode) {
    ThemeMode.dark => 'dark',
    ThemeMode.light => 'light',
    _ => 'system',
  };
  return box.put(_kThemeMode, raw);
}

Future<void> saveDefaultTaxId(Box<dynamic> box, int taxId) =>
    box.put(_kDefaultTaxId, taxId);

Future<void> saveLowStockThreshold(Box<dynamic> box, int threshold) =>
    box.put(_kLowStockThreshold, threshold);

Future<void> saveLoyaltyEnabled(Box<dynamic> box, bool v) => box.put(kLoyaltyEnabled, v);
Future<void> saveLoyaltyEarnRate(Box<dynamic> box, double v) => box.put(kLoyaltyEarnRate, v);
Future<void> saveLoyaltyPointValue(Box<dynamic> box, double v) => box.put(kLoyaltyPointValue, v);

// Store profile helpers
Future<void> saveBusinessName(Box<dynamic> box, String v) => box.put(kBusinessName, v);
Future<void> saveBusinessTagline(Box<dynamic> box, String v) => box.put(kBusinessTagline, v);
Future<void> saveBusinessPhone(Box<dynamic> box, String v) => box.put(kBusinessPhone, v);
Future<void> saveBusinessAddress(Box<dynamic> box, String v) => box.put(kBusinessAddress, v);
Future<void> saveBusinessPan(Box<dynamic> box, String v) => box.put(kBusinessPan, v);
Future<void> saveCurrencySymbol(Box<dynamic> box, String v) => box.put(kCurrencySymbol, v);
Future<void> saveCurrencyCode(Box<dynamic> box, String v) => box.put(kCurrencyCode, v);

// Store profile providers
final businessNameProvider = Provider<String>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return box.get(kBusinessName, defaultValue: '') as String;
});

final businessTaglineProvider = Provider<String>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return box.get(kBusinessTagline, defaultValue: '') as String;
});

final businessPhoneProvider = Provider<String>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return box.get(kBusinessPhone, defaultValue: '') as String;
});

final businessAddressProvider = Provider<String>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return box.get(kBusinessAddress, defaultValue: '') as String;
});

final businessPanProvider = Provider<String>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return box.get(kBusinessPan, defaultValue: '') as String;
});

final currencyCodeProvider = Provider<String>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return box.get(kCurrencyCode, defaultValue: 'NPR') as String;
});

final loyaltyEnabledProvider = Provider<bool>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return box.get(kLoyaltyEnabled, defaultValue: false) as bool;
});

/// Points earned per 1 currency unit spent. Default: 1 pt per 100 units = 0.01.
final loyaltyEarnRateProvider = Provider<double>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return (box.get(kLoyaltyEarnRate, defaultValue: 1.0) as num).toDouble();
});

/// Currency value of 1 loyalty point. Default: 1 pt = 1 currency unit.
final loyaltyPointValueProvider = Provider<double>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return (box.get(kLoyaltyPointValue, defaultValue: 1.0) as num).toDouble();
});
