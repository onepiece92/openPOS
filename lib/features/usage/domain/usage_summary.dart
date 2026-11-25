import 'package:flutter/foundation.dart' show immutable;

import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/usage_constants.dart';

/// One counter: how often, and in which months (`YYYY-MM`) it was first and
/// last counted.
@immutable
class UsageCount {
  const UsageCount(this.count, {this.firstMonth, this.lastMonth});

  final int count;
  final String? firstMonth;
  final String? lastMonth;

  /// One more, in [month].
  UsageCount bump(String month) => UsageCount(count + 1,
      firstMonth: earlierMonth(firstMonth, month),
      lastMonth: laterMonth(lastMonth, month));

  @override
  bool operator ==(Object other) =>
      other is UsageCount &&
      other.count == count &&
      other.firstMonth == firstMonth &&
      other.lastMonth == lastMonth;

  @override
  int get hashCode => Object.hash(count, firstMonth, lastMonth);

  @override
  String toString() => 'UsageCount($count, $firstMonth, $lastMonth)';
}

final _monthPattern = RegExp(r'^\d{4}-\d{2}$');

/// `YYYY-MM` of [t] (local time).
String usageMonth(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}';

/// Null-tolerant month comparisons; `YYYY-MM` sorts as text.
String? earlierMonth(String? a, String? b) =>
    a == null ? b : (b == null || a.compareTo(b) <= 0 ? a : b);
String? laterMonth(String? a, String? b) =>
    a == null ? b : (b == null || a.compareTo(b) >= 0 ? a : b);

// ── Shop size buckets ────────────────────────────────────────────────────────

/// A count, as one of the fixed ranges sent instead of the number.
String sizeBucket(int n) => switch (n) {
      <= 0 => '0',
      <= 10 => '1-10',
      <= 50 => '11-50',
      <= 200 => '51-200',
      _ => '200+',
    };

/// Raw COUNTs read when the summary screen opens. Never stored and never
/// sent as numbers: [buildUsageSummary] only emits their [sizeBucket].
@immutable
class ShopSizeCounts {
  const ShopSizeCounts({
    required this.products,
    required this.ordersLast7Days,
    required this.customers,
  });
  final int products;
  final int ordersLast7Days;
  final int customers;
}

/// App and device facts read at render time.
@immutable
class UsageEnvironment {
  const UsageEnvironment({
    required this.appVersion,
    required this.platform,
    required this.osMajorVersion,
    required this.locale,
    required this.currencyCode,
  });

  final String appVersion; // e.g. 1.1.0+10
  final String platform; // dart:io Platform.operatingSystem
  final int? osMajorVersion; // null = could not be read safely
  final String locale; // BCP-47 tag, e.g. en-US
  final String currencyCode; // ISO 4217, e.g. USD
}

/// Major OS version from `Platform.operatingSystemVersion`, parsed
/// conservatively: only the "Version 17.2 (Build …)" form that iOS and
/// macOS report is trusted. Android reports a Linux kernel string there
/// (not the Android version), so it — and anything else — gives null.
int? parseOsMajorVersion(String raw) {
  final m = RegExp(r'^Version (\d{1,3})(?:\.\d+)*\b').firstMatch(raw.trim());
  return m == null ? null : int.tryParse(m.group(1)!);
}

// ── Selection ────────────────────────────────────────────────────────────────

/// What the shopkeeper chose on the feedback screen: the areas to improve
/// ([picked]) and which groups of data to include. Nothing that is not
/// ticked is sent.
@immutable
class UsageSelection {
  const UsageSelection({
    this.picked = const {},
    this.tickedAreas = const {},
    this.appInfo = false,
    this.shopSize = false,
  });

  /// Areas the shopkeeper wants improved (the "Improve:" line).
  final Set<FeatureArea> picked;

  /// Areas whose counters are included.
  final Set<FeatureArea> tickedAreas;

  /// Include the app / OS / locale / currency line.
  final bool appInfo;

  /// Include the shop-size ranges.
  final bool shopSize;

  /// Picking an area pre-ticks its counters; un-picking unticks them.
  UsageSelection togglePicked(FeatureArea a) {
    final on = !picked.contains(a);
    return UsageSelection(
      picked: on ? {...picked, a} : ({...picked}..remove(a)),
      tickedAreas: on ? {...tickedAreas, a} : ({...tickedAreas}..remove(a)),
      appInfo: appInfo,
      shopSize: shopSize,
    );
  }

  UsageSelection toggleArea(FeatureArea a) => UsageSelection(
        picked: picked,
        tickedAreas: tickedAreas.contains(a)
            ? ({...tickedAreas}..remove(a))
            : {...tickedAreas, a},
        appInfo: appInfo,
        shopSize: shopSize,
      );

  UsageSelection withAppInfo(bool v) => UsageSelection(
      picked: picked, tickedAreas: tickedAreas, appInfo: v, shopSize: shopSize);

  UsageSelection withShopSize(bool v) => UsageSelection(
      picked: picked, tickedAreas: tickedAreas, appInfo: appInfo, shopSize: v);

  /// Any usage data ticked at all.
  bool get hasData => tickedAreas.isNotEmpty || appInfo || shopSize;
}

/// The message as it will be sent: trimmed and cut to
/// [kFeedbackMessageMaxLength].
String normalizeFeedbackMessage(String message) {
  final t = message.trim();
  return t.length <= kFeedbackMessageMaxLength
      ? t
      : t.substring(0, kFeedbackMessageMaxLength).trimRight();
}

/// Send is allowed with a message, with ticked data, or both.
bool canSendUsageSummary(UsageSelection s, String message) =>
    s.hasData || normalizeFeedbackMessage(message).isNotEmpty;

// ── The payload ──────────────────────────────────────────────────────────────

const kUsageSummaryHeader = 'Open POS feedback and usage summary';

/// Line that starts the shopkeeper's own words; everything after it is the
/// message. It is always the last section, so nothing typed can be
/// mistaken for (or break) the fixed lines above it.
const kUsageMessageMarker = 'Message:';

final _versionPattern = RegExp(r'^\d+(\.\d+)*(\+\d+)?$');
final _platformPattern = RegExp(r'^[a-z]{2,12}$');
final _localePattern = RegExp(r'^[A-Za-z]{2,3}(-[A-Za-z0-9]{2,8}){0,3}$');
final _currencyPattern = RegExp(r'^[A-Z]{3}$');

/// THE text the screen shows and the share / link sends, byte for byte.
///
/// Apart from the shopkeeper's [message] (last, after
/// [kUsageMessageMarker]) it contains only: fixed labels, [UsageEvent]
/// names, integers, `YYYY-MM` months, [sizeBucket] ranges, the app version,
/// platform, OS major version, locale and currency code — each checked
/// against a strict pattern and replaced by `unknown`/`other` when it does
/// not match. Names, products, customers, amounts, notes, the shop name and
/// device identifiers have no way in.
String buildUsageSummary({
  required UsageSelection selection,
  required String message,
  required Map<UsageEvent, UsageCount> counts,
  required UsageEnvironment env,
  required ShopSizeCounts? shop,
}) {
  final lines = <String>[kUsageSummaryHeader];
  final picked = [
    for (final a in FeatureArea.values)
      if (selection.picked.contains(a)) a.label,
  ];
  if (picked.isNotEmpty) lines.add('Improve: ${picked.join(', ')}');

  for (final area in FeatureArea.values) {
    if (!selection.tickedAreas.contains(area)) continue;
    lines.add('${area.label} usage:');
    for (final e in UsageEvent.of(area)) {
      final c = counts[e];
      final n = c?.count ?? 0;
      final first = _month(c?.firstMonth);
      final last = _month(c?.lastMonth);
      final when = n <= 0 || first == null || last == null
          ? ''
          : first == last
              ? ' ($first)'
              : ' ($first to $last)';
      lines.add('- ${e.name}: ${n < 0 ? 0 : n}$when');
    }
  }

  if (selection.appInfo) {
    String safe(String v, RegExp p, String fallback) =>
        p.hasMatch(v) ? v : fallback;
    final os = env.osMajorVersion;
    lines
        .add('App: Open POS ${safe(env.appVersion, _versionPattern, 'unknown')}'
            ', ${safe(env.platform, _platformPattern, 'other')}'
            ', OS ${os == null || os < 0 || os > 999 ? 'unknown' : os}'
            ', locale ${safe(env.locale, _localePattern, 'unknown')}'
            ', currency ${safe(env.currencyCode, _currencyPattern, 'other')}');
  }

  if (selection.shopSize && shop != null) {
    lines.add('Shop size: products ${sizeBucket(shop.products)}'
        ', orders in last 7 days ${sizeBucket(shop.ordersLast7Days)}'
        ', customers ${sizeBucket(shop.customers)}');
  }

  final text = normalizeFeedbackMessage(message);
  if (text.isNotEmpty) {
    lines
      ..add(kUsageMessageMarker)
      ..add(text);
  }
  return lines.join('\n');
}

String? _month(String? m) => m != null && _monthPattern.hasMatch(m) ? m : null;
