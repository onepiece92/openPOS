import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/providers/feature_flags.dart';

import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/domain/usage_summary.dart';
import 'package:pos_app/features/usage/usage_constants.dart';

/// Hive box holding the usage counters and their flags. Travels with
/// backups (it is in `kSnapshotHiveBoxes`) but is opened lazily, after the
/// first frame, never by startup.
const kUsageBoxName = 'usage';

// Box keys. Counters are `e.<UsageEvent.name>` → {'c': int, 'f': 'YYYY-MM',
// 'l': 'YYYY-MM'}; nothing else is ever written under `e.`.
const _eventPrefix = 'e.';
/// Legacy "Stop counting" flag (bool) of installs from before Features.
/// The switch itself is now the Usage counting feature (`features_v1` in
/// the settings box: one source of truth for Features and "Stop
/// counting"). [UsageCounter] moves an old value onto the switch on load
/// and deletes the key; a restore merge deletes it from restored boxes.
const kUsageCountingOnKey = 'counting_on'; // bool
const kUsageDisclosureShownKey = 'disclosure_shown'; // bool
const kUsageAskedVersionKey = 'ask_version'; // kAppVersionFull
/// First of an unbroken run of "review unavailable" checks (ISO-8601);
/// cleared by a review request. See `UsageAskController`.
const kUsageReviewUnavailableSinceKey = 'review_unavailable_since';

String _keyOf(UsageEvent e) => '$_eventPrefix${e.name}';

/// The on-device usage counter.
///
/// [record] is synchronous and allocation-light: a map update and, at most,
/// starting one timer. It never awaits, never touches the disk and never
/// throws, so it is safe on the sell / checkout path. Writes are coalesced:
/// everything counted within [flushDelay] of the first unsaved count is
/// written in one batch, and [onLifecycle] writes at once when the app is
/// paused or detached.
///
/// The box is opened by [ensureLoaded] (after the first frame, see
/// `UsageHost`). Counts made before that are buffered in memory and added
/// on load — or dropped, when counting is off, or when the box cannot be
/// opened (nothing is counted until it can).
///
/// On/off is the Usage counting feature switch: [countingOn] at creation,
/// then [countingEnabled] as `usageCounterProvider` follows the switch.
class UsageCounter {
  UsageCounter({
    Future<Box<dynamic>> Function()? openBox,
    DateTime Function()? clock,
    this.flushDelay = const Duration(seconds: 30),
    bool countingOn = kUsageCountingDefaultOn,
    this.onCarriedCountingChoice,
  })  : _openBox = openBox ?? _defaultOpen,
        _clock = clock ?? DateTime.now,
        countingEnabled = countingOn;

  /// Called on load with an older install's choice found under
  /// [kUsageCountingOnKey], which the owner moves onto the Usage counting
  /// switch.
  final Future<void> Function(bool on)? onCarriedCountingChoice;

  /// Opens the box beside the `settings` box (same folder). When settings is
  /// not open, Hive is not in use (tests, an error screen): nothing is
  /// opened, the counter stays in memory.
  static Future<Box<dynamic>> _defaultOpen() async {
    if (Hive.isBoxOpen(kUsageBoxName)) return Hive.box<dynamic>(kUsageBoxName);
    final settings =
        Hive.isBoxOpen('settings') ? Hive.box<dynamic>('settings').path : null;
    if (settings == null) throw StateError('Hive is not open');
    return Hive.openBox<dynamic>(kUsageBoxName, path: p.dirname(settings));
  }

  final Future<Box<dynamic>> Function() _openBox;
  final DateTime Function() _clock;
  final Duration flushDelay;

  /// Before load: buffered counts only. After load: every counter.
  final Map<UsageEvent, UsageCount> _counts = {};
  final Set<UsageEvent> _dirty = {};
  Box<dynamic>? _box;
  Future<void>? _loading;
  Timer? _timer;
  bool _disposed = false;

  bool get isLoaded => _box != null;

  /// Counting on/off: the Usage counting switch. Honoured by the very next
  /// [record]. Set only by whoever owns the switch.
  bool countingEnabled;

  /// True once opening the box has failed: the saved on/off flag is
  /// unknown, so nothing is counted (not even in memory).
  bool _unavailable = false;

  /// Every counter (after load); events never counted are absent.
  Map<UsageEvent, UsageCount> get counts => Map.unmodifiable(_counts);

  @visibleForTesting
  bool get flushScheduled => _timer != null;

  /// Counts one [event]. See the class doc for the cost guarantees.
  void record(UsageEvent event) {
    if (_disposed || _unavailable || !countingEnabled) return;
    final month = usageMonth(_clock());
    final c = _counts[event];
    _counts[event] = c == null
        ? UsageCount(1, firstMonth: month, lastMonth: month)
        : c.bump(month);
    if (_box != null) {
      _dirty.add(event);
      _schedule();
    }
  }

  String? _lastRoute;

  /// Counts a screen opening for a go_router route template; repeated
  /// notifications for the same screen ([location], or the template when
  /// no location is given) are ignored.
  void recordRoute(String? template, {String? location}) {
    final key = '$template|${location ?? template}';
    if (key == _lastRoute) return;
    _lastRoute = key;
    final e = usageEventForRoute(template);
    if (e != null) record(e);
  }

  void _schedule() {
    _timer ??= Timer(flushDelay, () {
      _timer = null;
      unawaited(flush());
    });
  }

  /// Opens the box and loads the counters. Safe to call repeatedly; never
  /// throws (a box that cannot be opened leaves the counter in memory).
  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final box = await _openBox();
      if (_disposed) return;
      final carried = box.get(kUsageCountingOnKey);
      if (box.containsKey(kUsageCountingOnKey)) {
        if (carried is bool) {
          countingEnabled = carried;
          // The settings write is not part of loading: not awaited.
          final apply = onCarriedCountingChoice;
          if (apply != null) unawaited(apply(carried));
        }
        await box.delete(kUsageCountingOnKey);
        if (_disposed) return;
      }
      final buffered = Map.of(_counts);
      _counts
        ..clear()
        ..addAll(readUsageCounts(box));
      if (countingEnabled) {
        buffered.forEach((e, b) {
          final s = _counts[e];
          _counts[e] = s == null
              ? b
              : UsageCount(s.count + b.count,
                  firstMonth: earlierMonth(s.firstMonth, b.firstMonth),
                  lastMonth: laterMonth(s.lastMonth, b.lastMonth));
          _dirty.add(e);
        });
      }
      _box = box;
      _unavailable = false;
      if (_dirty.isNotEmpty) _schedule();
    } catch (e) {
      _loading = null; // allow a later retry
      // The saved "off" flag could not be read: do not count until it can.
      _unavailable = true;
      _counts.clear();
      _dirty.clear();
      debugPrint('usage: box not available ($e)');
    }
  }

  /// Writes unsaved counters now. Never throws.
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    final box = _box;
    if (box == null || _dirty.isEmpty) return;
    final batch = {
      for (final e in _dirty)
        if (_counts[e] case final c?) _keyOf(e): _encode(c),
    };
    _dirty.clear();
    try {
      await box.putAll(batch);
    } catch (e) {
      debugPrint('usage: flush failed ($e)');
    }
  }

  /// Hook for `AppLifecycleListener`: paused / detached flush at once.
  void onLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(flush());
    }
  }

  /// Deletes every counter (the flags stay).
  Future<void> reset() async {
    _timer?.cancel();
    _timer = null;
    _counts.clear();
    _dirty.clear();
    final box = _box;
    if (box == null) return;
    try {
      await box.deleteAll(
          box.keys.where((k) => k is String && k.startsWith(_eventPrefix)));
    } catch (_) {/* best effort */}
  }

  bool get disclosureShown => _box?.get(kUsageDisclosureShownKey) == true;

  Future<void> markDisclosureShown() async {
    try {
      await _box?.put(kUsageDisclosureShownKey, true);
    } catch (_) {/* best effort */}
  }

  String? get askedVersion => switch (_box?.get(kUsageAskedVersionKey)) {
        final String v => v,
        _ => null,
      };

  DateTime? get reviewUnavailableSince =>
      switch (_box?.get(kUsageReviewUnavailableSinceKey)) {
        final String v => DateTime.tryParse(v),
        _ => null,
      };

  Future<void> setReviewUnavailableSince(DateTime? t) async {
    try {
      if (t == null) {
        if (_box?.containsKey(kUsageReviewUnavailableSinceKey) ?? false) {
          await _box?.delete(kUsageReviewUnavailableSinceKey);
        }
      } else {
        await _box?.put(kUsageReviewUnavailableSinceKey, t.toIso8601String());
      }
    } catch (_) {/* best effort */}
  }

  Future<void> markAsked(String version) async {
    try {
      await _box?.put(kUsageAskedVersionKey, version);
    } catch (_) {/* best effort */}
  }

  /// Container teardown: write what is pending and stop counting.
  void dispose() {
    if (_disposed) return;
    unawaited(flush());
    _disposed = true;
  }
}

Map<String, Object> _encode(UsageCount c) => {
      'c': c.count,
      if (c.firstMonth != null) 'f': c.firstMonth!,
      if (c.lastMonth != null) 'l': c.lastMonth!,
    };

/// Every counter stored in [box]; unknown keys and malformed values are
/// ignored.
Map<UsageEvent, UsageCount> readUsageCounts(Box<dynamic> box) {
  final out = <UsageEvent, UsageCount>{};
  for (final e in UsageEvent.values) {
    final v = box.get(_keyOf(e));
    if (v is! Map) continue;
    final c = v['c'];
    if (c is! int || c <= 0) continue;
    final f = v['f'];
    final l = v['l'];
    out[e] = UsageCount(c,
        firstMonth: f is String ? f : null, lastMonth: l is String ? l : null);
  }
  return out;
}

// ── Backup restore ───────────────────────────────────────────────────────────

/// The usage box as it was before a restore swapped the files.
class UsageSnapshot {
  const UsageSnapshot({
    required this.counts,
    this.countingOn,
    this.disclosureShown,
    this.askedVersion,
  });
  final Map<UsageEvent, UsageCount> counts;
  final bool? countingOn;
  final bool? disclosureShown;
  final String? askedVersion;

  static UsageSnapshot of(Box<dynamic> box) {
    T? typed<T>(String k) => switch (box.get(k)) { final T v => v, _ => null };
    return UsageSnapshot(
      counts: readUsageCounts(box),
      countingOn: typed<bool>(kUsageCountingOnKey),
      disclosureShown: typed<bool>(kUsageDisclosureShownKey),
      askedVersion: typed<String>(kUsageAskedVersionKey),
    );
  }
}

/// Merges [before] (this device, captured pre-restore) into the restored
/// box: per event the higher count, the earlier first month and the later
/// last month; the disclosure-shown flag and the asked version are this
/// device's, as they were before the restore. A legacy counting flag from
/// an older backup is dropped: the switch is in the settings box, put back
/// by [mergeUsageAfterRestore].
Future<void> mergeUsageBox(Box<dynamic> box, UsageSnapshot before) async {
  final after = readUsageCounts(box);
  final puts = <String, Object>{};
  for (final e in UsageEvent.values) {
    final b = before.counts[e];
    final a = after[e];
    if (b == null) continue;
    final merged = a == null
        ? b
        : UsageCount(b.count > a.count ? b.count : a.count,
            firstMonth: earlierMonth(a.firstMonth, b.firstMonth),
            lastMonth: laterMonth(a.lastMonth, b.lastMonth));
    if (merged != a) puts[_keyOf(e)] = _encode(merged);
  }
  if (puts.isNotEmpty) await box.putAll(puts);
  Future<void> keep(String key, Object? local) async {
    if (box.get(key) == local) return;
    if (local == null) {
      await box.delete(key);
    } else {
      await box.put(key, local);
    }
  }

  await keep(kUsageCountingOnKey, null);
  await keep(kUsageDisclosureShownKey, before.disclosureShown);
  await keep(kUsageAskedVersionKey, before.askedVersion);
}

/// Captured by `AppRoot.restoreFrom` before the files are swapped (after
/// the counter was flushed). Null — never an exception — when the box is
/// not open.
///
/// [countingOn] is this device's Usage counting switch. The restore
/// replaces the settings box, so [mergeUsageAfterRestore] writes it back
/// there: a backup never turns counting on or off.
UsageSnapshot? usageSnapshotBeforeRestore({bool? countingOn}) {
  try {
    if (!Hive.isBoxOpen(kUsageBoxName)) return null;
    final s = UsageSnapshot.of(Hive.box<dynamic>(kUsageBoxName));
    return countingOn == null
        ? s
        : UsageSnapshot(
            counts: s.counts,
            countingOn: countingOn,
            disclosureShown: s.disclosureShown,
            askedVersion: s.askedVersion);
  } catch (_) {
    return null;
  }
}

/// Called once the boxes are open again (restored data, or the old data
/// after a rollback, where it changes nothing). Never throws.
Future<void> mergeUsageAfterRestore(UsageSnapshot? before) async {
  if (before == null) return;
  try {
    if (Hive.isBoxOpen(kUsageBoxName)) {
      await mergeUsageBox(Hive.box<dynamic>(kUsageBoxName), before);
    }
    final on = before.countingOn;
    if (on != null && Hive.isBoxOpen('settings')) {
      await keepUsageCountingSwitch(Hive.box<dynamic>('settings'), on);
    }
  } catch (_) {/* best effort */}
}

/// Writes [on] as the Usage counting switch into [settings]' features_v1,
/// leaving every other switch as stored. Runs before the new container
/// reads the settings box.
Future<void> keepUsageCountingSwitch(Box<dynamic> settings, bool on) async {
  final raw = settings.get(kFeaturesKey);
  final map = raw is Map ? Map<String, Object?>.from(raw) : <String, Object?>{};
  if (map[Feature.usageCounting.name] == on) return;
  map[Feature.usageCounting.name] = on;
  await settings.put(kFeaturesKey, map);
}
