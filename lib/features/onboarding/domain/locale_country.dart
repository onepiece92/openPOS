import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/features/onboarding/domain/country_default.dart';

/// The device region as an ISO 3166 alpha-2 code ("GB"), or null when the
/// locale has none. Read once, when setup needs a default — never at
/// startup. Overridden in tests.
final deviceRegionProvider = Provider<String?>((ref) {
  final fromLocale = PlatformDispatcher.instance.locale.countryCode;
  return normalizeRegion(fromLocale) ?? regionFromLocaleName(_localeName());
});

String? _localeName() {
  try {
    return Platform.localeName;
  } catch (_) {
    return null; // not available on this platform
  }
}

/// [raw] as an upper-case two-letter region, or null.
String? normalizeRegion(String? raw) {
  if (raw == null) return null;
  final r = raw.trim().toUpperCase();
  return RegExp(r'^[A-Z]{2}$').hasMatch(r) ? r : null;
}

/// The region of a POSIX / BCP-47 locale name: "en_GB", "en-GB",
/// "en_GB.UTF-8", "zh_Hant_TW", "sr-Latn-RS@latin" → "GB" / "TW" / "RS".
/// The first two-letter subtag after the language; null when there is none
/// ("en", "C", "POSIX", "es_419").
String? regionFromLocaleName(String? name) {
  if (name == null) return null;
  final base = name.split(RegExp(r'[.@]')).first;
  final parts = base.split(RegExp(r'[-_]'));
  for (final p in parts.skip(1)) {
    final r = normalizeRegion(p);
    if (r != null && p.length == 2) return r;
  }
  return null;
}

/// The United States entry, used only when the locale gives nothing
/// usable (and as the last resort if the country data lacks it).
const kFallbackCountry = CountryDefault(
  code: 'US',
  name: 'United States',
  currency: 'USD',
  symbol: r'$',
  timezone: 'America/New_York',
  taxName: 'Sales Tax',
  taxRate: 0,
);

/// The country of [region] in the bundled country data, else the US.
CountryDefault countryForRegion(List<CountryDefault> countries, String? region) {
  CountryDefault? byCode(String code) =>
      countries.where((c) => c.code == code).firstOrNull;
  final r = normalizeRegion(region);
  return (r == null ? null : byCode(r)) ?? byCode('US') ?? kFallbackCountry;
}
