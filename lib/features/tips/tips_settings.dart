import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/providers/hive_provider.dart';

/// Tips settings, kept in the Hive settings box.
///
/// Every tips control asks [tipsEnabled] (or watches [tipsEnabledProvider]);
/// it is the single gate, so moving the switch to another settings home
/// later means changing only [tipsEnabledProvider].

const kTipsEnabled = 'tips_enabled';
const kTipPresets = 'tip_presets'; // list of percents
const kTipOnPostTax = 'tip_on_post_tax';

const kDefaultTipPresets = <double>[15, 18, 20];
const kMaxTipPresets = 4;

@immutable
class TipsSettings {
  const TipsSettings({
    this.enabled = false,
    this.presets = kDefaultTipPresets,
    this.postTax = false,
  });
  final bool enabled;
  final List<double> presets;

  /// Tip on the total after tax instead of before it.
  final bool postTax;

  @override
  bool operator ==(Object other) =>
      other is TipsSettings &&
      other.enabled == enabled &&
      other.postTax == postTax &&
      listEquals(other.presets, presets);

  @override
  int get hashCode => Object.hash(enabled, postTax, Object.hashAll(presets));
}

class TipsSettingsNotifier extends Notifier<TipsSettings> {
  @override
  TipsSettings build() {
    final box = ref.read(settingsBoxProvider);
    final raw = box.get(kTipPresets);
    final stored = raw is List
        ? [
            for (final e in raw)
              if (e is num && e > 0 && e <= 100) e.toDouble()
          ].take(kMaxTipPresets).toList()
        : <double>[];
    return TipsSettings(
      enabled: box.get(kTipsEnabled, defaultValue: false) == true,
      presets: stored.isEmpty ? kDefaultTipPresets : stored,
      postTax: box.get(kTipOnPostTax, defaultValue: false) == true,
    );
  }

  Future<void> setEnabled(bool v) async {
    state = TipsSettings(
        enabled: v, presets: state.presets, postTax: state.postTax);
    await ref.read(settingsBoxProvider).put(kTipsEnabled, v);
  }

  Future<void> setPostTax(bool v) async {
    state = TipsSettings(
        enabled: state.enabled, presets: state.presets, postTax: v);
    await ref.read(settingsBoxProvider).put(kTipOnPostTax, v);
  }

  Future<void> setPresets(List<double> presets) async {
    state = TipsSettings(
        enabled: state.enabled, presets: presets, postTax: state.postTax);
    await ref.read(settingsBoxProvider).put(kTipPresets, presets);
  }
}

final tipsSettingsProvider =
    NotifierProvider<TipsSettingsNotifier, TipsSettings>(
        TipsSettingsNotifier.new);

/// The one switch behind every tips control. Default off.
final tipsEnabledProvider = Provider<bool>(
    (ref) => ref.watch(tipsSettingsProvider.select((s) => s.enabled)));

bool tipsEnabled(WidgetRef ref) => ref.watch(tipsEnabledProvider);

/// Parses "15, 18 20" into percents. Returns an error message, or null and
/// fills [out]. 1 to [kMaxTipPresets] values, each above 0 and at most 100.
String? parseTipPresets(String raw, List<double> out) {
  final parts =
      raw.split(RegExp(r'[,\s]+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'Enter at least one percentage';
  if (parts.length > kMaxTipPresets) {
    return 'At most $kMaxTipPresets percentages';
  }
  final values = <double>[];
  for (final p in parts) {
    final v = double.tryParse(p.replaceAll('%', ''));
    if (v == null) return '"$p" is not a number';
    if (v <= 0 || v > 100) {
      return 'Each percentage must be above 0 and at most 100';
    }
    values.add(v);
  }
  out
    ..clear()
    ..addAll(values);
  return null;
}

/// "15%" or "12.5%".
String tipPercentLabel(double p) =>
    '${p == p.roundToDouble() ? p.toInt() : p}%';
