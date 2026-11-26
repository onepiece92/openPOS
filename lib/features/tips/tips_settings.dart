import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/providers/hive_provider.dart';

/// Tips settings (percentages, tip base), kept in the Hive settings box.
///
/// The on/off switch is the Tips feature in Features. Every tips control
/// asks [tipsEnabled] (or watches [tipsEnabledProvider]). An earlier
/// `tips_enabled` key was never shipped, so it is not read and a stray
/// copy in the box is ignored.

const kTipPresets = 'tip_presets'; // list of percents
const kTipOnPostTax = 'tip_on_post_tax';

const kDefaultTipPresets = <double>[15, 18, 20];
const kMaxTipPresets = 4;

@immutable
class TipsSettings {
  const TipsSettings({this.presets = kDefaultTipPresets, this.postTax = false});
  final List<double> presets;

  /// Tip on the total after tax instead of before it.
  final bool postTax;

  @override
  bool operator ==(Object other) =>
      other is TipsSettings &&
      other.postTax == postTax &&
      listEquals(other.presets, presets);

  @override
  int get hashCode => Object.hash(postTax, Object.hashAll(presets));
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
      presets: stored.isEmpty ? kDefaultTipPresets : stored,
      postTax: box.get(kTipOnPostTax, defaultValue: false) == true,
    );
  }

  Future<void> setPostTax(bool v) async {
    state = TipsSettings(presets: state.presets, postTax: v);
    await ref.read(settingsBoxProvider).put(kTipOnPostTax, v);
  }

  Future<void> setPresets(List<double> presets) async {
    state = TipsSettings(presets: presets, postTax: state.postTax);
    await ref.read(settingsBoxProvider).put(kTipPresets, presets);
  }
}

final tipsSettingsProvider =
    NotifierProvider<TipsSettingsNotifier, TipsSettings>(
        TipsSettingsNotifier.new);

/// The one switch behind every tips control: the Tips feature, effective
/// (default off).
final tipsEnabledProvider =
    Provider<bool>((ref) => ref.watch(featureOnProvider(Feature.tips)));

bool tipsEnabled(WidgetRef ref) => ref.watch(tipsEnabledProvider);

/// Parses "15, 18 20" into percents. Returns an error message, or null and
/// fills [out]. 1 to [kMaxTipPresets] values, each above 0 and at most 100.
String? parseTipPresets(String raw, List<double> out) {
  final parts =
      raw.split(RegExp(r'[,\s]+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'Enter at least one percentage';
  final values = <double>[];
  for (final p in parts) {
    final v = double.tryParse(p.replaceAll('%', ''));
    if (v == null) return '"$p" is not a number';
    if (v <= 0 || v > 100) {
      return 'Each percentage must be above 0 and at most 100';
    }
    if (!values.contains(v)) values.add(v);
  }
  if (values.length > kMaxTipPresets) {
    return 'At most $kMaxTipPresets percentages';
  }
  out
    ..clear()
    ..addAll(values);
  return null;
}

/// "15%" or "12.5%".
String tipPercentLabel(double p) =>
    '${p == p.roundToDouble() ? p.toInt() : p}%';
