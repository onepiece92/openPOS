import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/providers/feature_flags.dart';
import 'package:pos_app/features/settings/presentation/widgets/tax_section.dart'
    show invoicePrefixError;

export 'package:pos_app/core/providers/feature_flags.dart';

/// App settings live in the Hive `settings` box, but the app never reads the
/// box directly: [SettingsNotifier] loads it once into an immutable
/// [AppSettings], every setter updates state *and* persists, and the
/// per-field providers below are plain selectors on that state — so any
/// `ref.watch` rebuilds on change with no `ref.invalidate` choreography.

// ── Box keys ─────────────────────────────────────────────────────────────────

const _kOnboardingComplete = 'onboarding_complete';
const _kThemeMode = 'theme_mode'; // 'dark' | 'light' | 'system'
const _kDefaultTaxId = 'default_tax_id';
const _kLowStockThreshold = 'low_stock_threshold';
const kLoyaltyEnabled = 'loyalty_enabled';
const kLoyaltyEarnRate = 'loyalty_earn_rate'; // pts earned per 1 currency unit spent
const kLoyaltyPointValue = 'loyalty_point_value'; // currency value of 1 pt

// Feature switches (see feature_flags.dart; `features_v1` is kFeaturesKey).
/// When Stock tracking was last switched off (ISO-8601). Kept after it is
/// switched back on, for the recount line, until that line is dismissed.
const kStockOffSince = 'stock_off_since';
/// The one-time "New: turn features on or off" drawer line was dismissed
/// (or setup showed the suggested features).
const kFeaturesIntroSeen = 'features_intro_seen';
/// Setup was skipped before its suggestions step (a fresh install): the
/// drawer line is the neutral one, not "New: …".
const kFeaturesIntroFresh = 'features_intro_fresh';
/// `BusinessType.name` chosen in setup (lib/features/onboarding/domain).
const kBusinessType = 'business_type';

// Printer keys
const kPrinterDeviceAddress = 'printer_device_address';
const kPrinterDeviceName = 'printer_device_name';
const kPrinterPaperWidth = 'printer_paper_width'; // '58' | '80'
const kPrinterDriver = 'printer_driver'; // 'escpos' | 'star'

// Backup keys
const kAutoBackupEnabled = 'auto_backup_enabled';
const kAutoBackupLastAt = 'auto_backup_last_at'; // ISO-8601

// Store profile keys
const kBusinessName = 'business_name';
const kBusinessTagline = 'business_tagline';
const kBusinessPhone = 'business_phone';
const kBusinessAddress = 'business_address';
const kBusinessPan = 'business_pan';
const kCurrencySymbol = 'currency_symbol';
const kCurrencyCode = 'currency_code';
const kCountryCode = 'country_code';
const kInvoicePrefix = 'invoice_prefix';
const kTimezone = 'timezone';

// Store-review trigger keys (owned by lib/features/review/data/
// review_state_store.dart, which reads/writes them directly — they are
// bookkeeping, not user-facing settings, so they stay out of AppSettings).
const kReviewFirstLaunchAt = 'review_first_launch_at'; // ISO-8601
const kReviewLastPromptAt = 'review_last_prompt_at'; // ISO-8601
const kReviewLastPromptVersion = 'review_last_prompt_version'; // kAppVersionFull, e.g. '1.1.0+10'

/// When ANY prompt (store review or the feedback ask) was last shown.
/// Written by both; read by the feedback ask, which never shows within
/// `kMinDaysBetweenAnyPrompts` of another prompt. The store review ignores
/// it (it is never delayed by the ask). ISO-8601.
const kPromptLastShownAt = 'prompt_last_shown_at';

// ── Raw box provider ─────────────────────────────────────────────────────────

/// The 'settings' box must be opened in main() before the container exists.
/// Only [SettingsNotifier], the favorites store, the review-state store and
/// backup touch it directly.
final settingsBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>('settings');
});

// ── Typed settings state ─────────────────────────────────────────────────────

@immutable
class AppSettings {
  const AppSettings({
    this.onboardingComplete = false,
    this.themeMode = ThemeMode.system,
    this.defaultTaxId,
    this.lowStockThreshold = 5,
    this.loyaltyEnabled = false,
    this.loyaltyEarnRate = 1.0,
    this.loyaltyPointValue = 1.0,
    this.printerDeviceAddress,
    this.printerDeviceName,
    this.printerPaperWidth = 80,
    this.printerDriver = 'escpos',
    this.businessName = '',
    this.businessTagline = '',
    this.businessPhone = '',
    this.businessAddress = '',
    this.businessPan = '',
    this.currencySymbol = r'$',
    this.currencyCode = 'USD',
    this.countryCode = '',
    this.invoicePrefix = '',
    this.timezone = '',
    this.autoBackupEnabled = true,
    this.autoBackupLastAt,
    FeatureFlags? features,
    this.stockOffSince,
    this.featuresIntroSeen = false,
    this.featuresIntroFresh = false,
    this.businessType,
  }) : _features = features;

  final bool onboardingComplete;
  final ThemeMode themeMode;
  final int? defaultTaxId;
  final int lowStockThreshold;
  final bool loyaltyEnabled;
  final double loyaltyEarnRate; // pts per 1 currency unit spent
  final double loyaltyPointValue; // currency value of 1 pt
  final String? printerDeviceAddress; // BLE MAC or USB id
  final String? printerDeviceName;
  final int printerPaperWidth; // mm

  /// Which driver owns the saved printer: 'escpos' (generic Bluetooth
  /// thermal) or 'star' (Star TSP100III over classic Bluetooth).
  final String printerDriver;
  final String businessName;
  final String businessTagline;
  final String businessPhone;
  final String businessAddress;
  final String businessPan;
  final String currencySymbol;
  final String currencyCode;
  final String countryCode;

  /// Scopes invoice numbering (e.g. fiscal year '2082/83'). Changing it
  /// restarts the bill sequence at 1; old bills keep their numbers.
  final String invoicePrefix;
  final String timezone;
  final bool autoBackupEnabled;
  final DateTime? autoBackupLastAt;

  final FeatureFlags? _features;

  /// The feature switches. Loyalty's own switch is [loyaltyEnabled].
  FeatureFlags get features =>
      (_features ?? FeatureFlags.defaults()).withStored(
          Feature.loyalty, loyaltyEnabled);

  /// Set while Stock tracking is off, and after it is switched back on
  /// until the recount line is dismissed.
  final DateTime? stockOffSince;
  final bool featuresIntroSeen;
  final bool featuresIntroFresh;

  /// Raw `BusinessType.name`; parse it with `parseBusinessType`.
  final String? businessType;

  /// Business name for receipts/print — never blank.
  String get businessNameOrDefault =>
      businessName.isEmpty ? 'My Store' : businessName;

  /// Reads every key from the box, tolerating the loose types older builds
  /// wrote (paper width as String, loyalty rates as int, …).
  factory AppSettings.fromBox(Box<dynamic> box) {
    T get<T>(String key, T fallback) {
      final v = box.get(key);
      return v is T ? v : fallback;
    }

    double num_(String key, double fallback) {
      final v = box.get(key);
      return v is num ? v.toDouble() : fallback;
    }

    final rawWidth = box.get(kPrinterPaperWidth);
    final width = rawWidth is int
        ? rawWidth
        : (rawWidth is String ? int.tryParse(rawWidth) : null) ?? 80;
    final rawLast = box.get(kAutoBackupLastAt);
    final rawFeatures = box.get(kFeaturesKey);
    final rawStockOff = box.get(kStockOffSince);
    final loyalty = get(kLoyaltyEnabled, false);
    final legacy = get(_kOnboardingComplete, false);

    return AppSettings(
      onboardingComplete: get(_kOnboardingComplete, false),
      themeMode: _themeModeFrom(get(_kThemeMode, 'system')),
      defaultTaxId: box.get(_kDefaultTaxId) as int?,
      lowStockThreshold: get(_kLowStockThreshold, 5),
      loyaltyEnabled: loyalty,
      loyaltyEarnRate: num_(kLoyaltyEarnRate, 1.0),
      loyaltyPointValue: num_(kLoyaltyPointValue, 1.0),
      printerDeviceAddress: box.get(kPrinterDeviceAddress) as String?,
      printerDeviceName: box.get(kPrinterDeviceName) as String?,
      printerPaperWidth: width,
      printerDriver: get(kPrinterDriver, 'escpos'),
      businessName: get(kBusinessName, ''),
      businessTagline: get(kBusinessTagline, ''),
      businessPhone: get(kBusinessPhone, ''),
      businessAddress: get(kBusinessAddress, ''),
      businessPan: get(kBusinessPan, ''),
      // No currency stored: an existing install (setup done in an older
      // build, whose Skip saved none) keeps its Rs/NPR; a new install shows
      // $/USD only until setup saves the device region's currency.
      currencySymbol: get(kCurrencySymbol, legacy ? 'Rs' : r'$'),
      currencyCode: get(kCurrencyCode, legacy ? 'NPR' : 'USD'),
      countryCode: get(kCountryCode, ''),
      invoicePrefix: get(kInvoicePrefix, ''),
      timezone: get(kTimezone, ''),
      autoBackupEnabled: get(kAutoBackupEnabled, true),
      autoBackupLastAt:
          rawLast is String ? DateTime.tryParse(rawLast) : null,
      features: FeatureFlags.fromStored(
          rawFeatures is Map ? rawFeatures : const {},
          loyalty: loyalty),
      stockOffSince:
          rawStockOff is String ? DateTime.tryParse(rawStockOff) : null,
      featuresIntroSeen: get(kFeaturesIntroSeen, false),
      featuresIntroFresh: get(kFeaturesIntroFresh, false),
      businessType: box.get(kBusinessType) as String?,
    );
  }

  AppSettings copyWith({
    bool? onboardingComplete,
    ThemeMode? themeMode,
    int? defaultTaxId,
    bool clearDefaultTaxId = false,
    int? lowStockThreshold,
    bool? loyaltyEnabled,
    double? loyaltyEarnRate,
    double? loyaltyPointValue,
    String? printerDeviceAddress,
    String? printerDeviceName,
    bool clearPrinterDevice = false,
    int? printerPaperWidth,
    String? printerDriver,
    String? businessName,
    String? businessTagline,
    String? businessPhone,
    String? businessAddress,
    String? businessPan,
    String? currencySymbol,
    String? currencyCode,
    String? countryCode,
    String? invoicePrefix,
    String? timezone,
    bool? autoBackupEnabled,
    DateTime? autoBackupLastAt,
    FeatureFlags? features,
    DateTime? stockOffSince,
    bool clearStockOffSince = false,
    bool? featuresIntroSeen,
    bool? featuresIntroFresh,
    String? businessType,
  }) =>
      AppSettings(
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        themeMode: themeMode ?? this.themeMode,
        defaultTaxId:
            clearDefaultTaxId ? null : (defaultTaxId ?? this.defaultTaxId),
        lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
        loyaltyEnabled: loyaltyEnabled ?? this.loyaltyEnabled,
        loyaltyEarnRate: loyaltyEarnRate ?? this.loyaltyEarnRate,
        loyaltyPointValue: loyaltyPointValue ?? this.loyaltyPointValue,
        printerDeviceAddress: clearPrinterDevice
            ? null
            : (printerDeviceAddress ?? this.printerDeviceAddress),
        printerDeviceName: clearPrinterDevice
            ? null
            : (printerDeviceName ?? this.printerDeviceName),
        printerPaperWidth: printerPaperWidth ?? this.printerPaperWidth,
        printerDriver: printerDriver ?? this.printerDriver,
        businessName: businessName ?? this.businessName,
        businessTagline: businessTagline ?? this.businessTagline,
        businessPhone: businessPhone ?? this.businessPhone,
        businessAddress: businessAddress ?? this.businessAddress,
        businessPan: businessPan ?? this.businessPan,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        currencyCode: currencyCode ?? this.currencyCode,
        countryCode: countryCode ?? this.countryCode,
        invoicePrefix: invoicePrefix ?? this.invoicePrefix,
        timezone: timezone ?? this.timezone,
        autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
        autoBackupLastAt: autoBackupLastAt ?? this.autoBackupLastAt,
        features: features ?? _features,
        stockOffSince: clearStockOffSince
            ? null
            : (stockOffSince ?? this.stockOffSince),
        featuresIntroSeen: featuresIntroSeen ?? this.featuresIntroSeen,
        featuresIntroFresh: featuresIntroFresh ?? this.featuresIntroFresh,
        businessType: businessType ?? this.businessType,
      );

  static ThemeMode _themeModeFrom(String raw) => switch (raw) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };

  static String _themeModeTo(ThemeMode mode) => switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        _ => 'system',
      };
}

// ── Notifier ─────────────────────────────────────────────────────────────────

/// Single writer for the settings box. State updates synchronously (so the
/// UI and router react at once); the Hive write is awaited afterwards.
class SettingsNotifier extends Notifier<AppSettings> {
  Box<dynamic> get _box => ref.read(settingsBoxProvider);

  @override
  AppSettings build() => AppSettings.fromBox(_box);

  /// Re-reads the box — call after wiping/replacing it (factory reset).
  void reload() => state = AppSettings.fromBox(_box);

  Future<void> _write(AppSettings next, Map<String, Object?> puts) async {
    state = next;
    for (final e in puts.entries) {
      if (e.value == null) {
        await _box.delete(e.key);
      } else {
        await _box.put(e.key, e.value);
      }
    }
  }

  // Onboarding / theme
  Future<void> setOnboardingComplete(bool v) => _write(
      state.copyWith(onboardingComplete: v), {_kOnboardingComplete: v});
  Future<void> setThemeMode(ThemeMode mode) => _write(
      state.copyWith(themeMode: mode),
      {_kThemeMode: AppSettings._themeModeTo(mode)});

  // Tax / stock
  Future<void> setDefaultTaxId(int? id) => _write(
      id == null
          ? state.copyWith(clearDefaultTaxId: true)
          : state.copyWith(defaultTaxId: id),
      {_kDefaultTaxId: id});
  Future<void> setLowStockThreshold(int v) => _write(
      state.copyWith(lowStockThreshold: v), {_kLowStockThreshold: v});

  // Loyalty
  Future<void> setLoyaltyEnabled(bool v) =>
      _write(state.copyWith(loyaltyEnabled: v), {kLoyaltyEnabled: v});
  Future<void> setLoyaltyRates(
          {required double earnRate, required double pointValue}) =>
      _write(
        state.copyWith(loyaltyEarnRate: earnRate, loyaltyPointValue: pointValue),
        {kLoyaltyEarnRate: earnRate, kLoyaltyPointValue: pointValue},
      );

  // Printer
  /// [driver] identifies the transport that found this device ('escpos' or
  /// 'star') — it is saved with the device so printing uses the same driver
  /// that discovered it.
  Future<void> setPrinterDevice({
    required String address,
    required String name,
    required String driver,
  }) =>
      _write(
        state.copyWith(
          printerDeviceAddress: address,
          printerDeviceName: name,
          printerDriver: driver,
        ),
        {
          kPrinterDeviceAddress: address,
          kPrinterDeviceName: name,
          kPrinterDriver: driver,
        },
      );
  Future<void> clearPrinterDevice() => _write(
        state.copyWith(clearPrinterDevice: true),
        {kPrinterDeviceAddress: null, kPrinterDeviceName: null},
      );
  Future<void> setPrinterPaperWidth(int mm) => _write(
      state.copyWith(printerPaperWidth: mm), {kPrinterPaperWidth: mm.toString()});

  // Store profile
  Future<void> setStoreProfile({
    String? name,
    String? tagline,
    String? phone,
    String? address,
    String? pan,
  }) =>
      _write(
        state.copyWith(
          businessName: name,
          businessTagline: tagline,
          businessPhone: phone,
          businessAddress: address,
          businessPan: pan,
        ),
        {
          if (name != null) kBusinessName: name,
          if (tagline != null) kBusinessTagline: tagline,
          if (phone != null) kBusinessPhone: phone,
          if (address != null) kBusinessAddress: address,
          if (pan != null) kBusinessPan: pan,
        },
      );
  Future<void> setCurrency({required String symbol, required String code}) =>
      _write(
        state.copyWith(currencySymbol: symbol, currencyCode: code),
        {kCurrencySymbol: symbol, kCurrencyCode: code},
      );
  /// Throws [ArgumentError] for the reserved imported-orders prefix (any
  /// case, after trimming): the settings dialog blocks it too.
  Future<void> setInvoicePrefix(String v) async {
    final error = invoicePrefixError(v);
    if (error != null) throw ArgumentError.value(v, 'prefix', error);
    await _write(
        state.copyWith(invoicePrefix: v.trim()), {kInvoicePrefix: v.trim()});
  }
  Future<void> setLocale({required String countryCode, required String timezone}) =>
      _write(
        state.copyWith(countryCode: countryCode, timezone: timezone),
        {kCountryCode: countryCode, kTimezone: timezone},
      );

  // Backup
  Future<void> setAutoBackupEnabled(bool v) =>
      _write(state.copyWith(autoBackupEnabled: v), {kAutoBackupEnabled: v});
  Future<void> markAutoBackupRun(DateTime t) => _write(
      state.copyWith(autoBackupLastAt: t), {kAutoBackupLastAt: t.toIso8601String()});

  // Features
  /// Sets [f]'s own switch. Loyalty writes `kLoyaltyEnabled`; every other
  /// feature rewrites the `features_v1` map. Switching Stock tracking off
  /// records the date (for the recount line when it comes back on).
  Future<void> setFeature(Feature f, bool on, {DateTime? now}) =>
      setFeatures({f: on}, now: now);

  /// Sets several switches in one write (setup, "Start minimal").
  Future<void> setFeatures(Map<Feature, bool> values, {DateTime? now}) {
    var flags = state.features;
    for (final e in values.entries) {
      flags = flags.withStored(e.key, e.value);
    }
    final loyalty = flags.stored(Feature.loyalty);
    final stockOff = values[Feature.stockTracking] == false &&
        state.features.stored(Feature.stockTracking) &&
        state.stockOffSince == null;
    final since = (now ?? DateTime.now());
    return _write(
      state.copyWith(
        features: flags,
        loyaltyEnabled: loyalty,
        stockOffSince: stockOff ? since : null,
      ),
      {
        kFeaturesKey: flags.toStored(),
        if (values.containsKey(Feature.loyalty)) kLoyaltyEnabled: loyalty,
        if (stockOff) kStockOffSince: since.toIso8601String(),
      },
    );
  }

  /// "Done" on the recount line.
  Future<void> dismissStockRecount() => _write(
      state.copyWith(clearStockOffSince: true), {kStockOffSince: null});

  Future<void> markFeaturesIntroSeen() => _write(
      state.copyWith(featuresIntroSeen: true), {kFeaturesIntroSeen: true});

  Future<void> markFeaturesIntroFresh() => _write(
      state.copyWith(featuresIntroFresh: true), {kFeaturesIntroFresh: true});

  Future<void> setBusinessType(String name) =>
      _write(state.copyWith(businessType: name), {kBusinessType: name});
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// ── Field selectors (reactive) ───────────────────────────────────────────────
// Kept as named providers so call sites read naturally and only rebuild when
// their own field changes.

Provider<T> _field<T>(T Function(AppSettings s) pick) =>
    Provider<T>((ref) => ref.watch(settingsProvider.select(pick)));

/// True once the first-run setup wizard has been completed.
final onboardingCompleteProvider = _field((s) => s.onboardingComplete);

/// App-wide ThemeMode (persisted).
final themeModeProvider = _field((s) => s.themeMode);

/// Store-wide default tax rate ID (null = no default set yet).
final defaultTaxIdProvider = _field((s) => s.defaultTaxId);

/// Low-stock alert threshold (unit count). Default 5.
final lowStockThresholdProvider = _field((s) => s.lowStockThreshold);

final loyaltyEnabledProvider = _field((s) => s.loyaltyEnabled);
/// Points earned per 1 currency unit spent.
final loyaltyEarnRateProvider = _field((s) => s.loyaltyEarnRate);
/// Currency value of 1 loyalty point.
final loyaltyPointValueProvider = _field((s) => s.loyaltyPointValue);

final businessNameProvider = _field((s) => s.businessName);
final businessTaglineProvider = _field((s) => s.businessTagline);
final businessPhoneProvider = _field((s) => s.businessPhone);
final businessAddressProvider = _field((s) => s.businessAddress);
final businessPanProvider = _field((s) => s.businessPan);
/// Currency symbol shown before amounts (e.g. "Rs", "$").
final currencySymbolProvider = _field((s) => s.currencySymbol);
final currencyCodeProvider = _field((s) => s.currencyCode);
/// Fiscal-year invoice prefix ('' = plain numbering).
final invoicePrefixProvider = _field((s) => s.invoicePrefix);

/// Daily local snapshot on launch (kept in the app's documents dir).
final autoBackupEnabledProvider = _field((s) => s.autoBackupEnabled);
final autoBackupLastAtProvider = _field((s) => s.autoBackupLastAt);

/// MAC address (BLE) or USB device id of the saved thermal printer, if any.
final printerDeviceAddressProvider = _field((s) => s.printerDeviceAddress);
/// Human-readable name of the saved thermal printer, if any.
final printerDeviceNameProvider = _field((s) => s.printerDeviceName);
/// Paper width in millimetres. Defaults to 80.
final printerPaperWidthProvider = _field((s) => s.printerPaperWidth);

/// Driver key of the saved printer: 'escpos' or 'star'.
final printerDriverProvider = _field((s) => s.printerDriver);

/// The EFFECTIVE feature switches (own switch AND parent's), read
/// synchronously from the already-loaded settings — no I/O.
final featureFlagsProvider = _field((s) => s.features);

/// One feature's effective switch. Watch this rather than
/// [featureFlagsProvider] so a widget rebuilds only for its own flag.
final featureOnProvider = Provider.family<bool, Feature>((ref, f) =>
    ref.watch(featureFlagsProvider.select((flags) => flags.isOn(f))));

final stockOffSinceProvider = _field((s) => s.stockOffSince);
final featuresIntroSeenProvider = _field((s) => s.featuresIntroSeen);
final featuresIntroFreshProvider = _field((s) => s.featuresIntroFresh);
final businessTypeNameProvider = _field((s) => s.businessType);
