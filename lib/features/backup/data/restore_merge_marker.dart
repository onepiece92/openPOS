import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/features/review/data/review_state_store.dart';
import 'package:pos_app/features/review/domain/review_policy.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/domain/usage_summary.dart';

/// The bookkeeping a restore merges back afterwards (review state and the
/// usage box), kept on disk from just before the swap until the merge has
/// run. If the restore ends on the error screen and the app is then killed
/// — or "Try again" finds the restore was in fact accepted — the merge is
/// finished from this file instead of being lost.
///
/// It lives beside the `settings` box. Merging is safe on any data: on the
/// device's own (rolled-back) data it changes nothing.
const kRestoreMergeMarkerName = 'restore_merge.json';

File? _markerFile() {
  if (!Hive.isBoxOpen('settings')) return null;
  final path = Hive.box<dynamic>('settings').path;
  return path == null
      ? null
      : File(p.join(p.dirname(path), kRestoreMergeMarkerName));
}

/// Written synchronously by `AppRoot.restoreFrom` before the stores close.
/// Never throws.
void writeRestoreMergeMarker(ReviewState? review, UsageSnapshot? usage) {
  try {
    final f = _markerFile();
    if (f == null || (review == null && usage == null)) return;
    f.writeAsStringSync(
        jsonEncode({
          if (review != null) 'review': _reviewToJson(review),
          if (usage != null) 'usage': _usageToJson(usage),
        }),
        flush: true);
  } catch (_) {/* best effort */}
}

/// Drops the marker (the merge ran, or nothing was swapped). Never throws.
void deleteRestoreMergeMarker() {
  try {
    final f = _markerFile();
    if (f != null && f.existsSync()) f.deleteSync();
  } catch (_) {/* best effort */}
}

/// Called once the stores are open again (startup, or "Try again"): runs a
/// merge left pending by an interrupted restore and removes the marker.
/// Returns true when [recovered] says the restore was accepted and its
/// merge has now run — the caller then says "The backup was restored."
/// Costs one `exists` check when there is no marker. Never throws.
Future<bool> finishPendingRestoreMerge(RestoreRecovery recovered) async {
  try {
    final f = _markerFile();
    if (f == null || !f.existsSync()) return false;
    Map<String, Object?>? json;
    try {
      json = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
    } catch (_) {/* unreadable: nothing to merge */}
    if (json != null) {
      final review = _reviewFromJson(json['review']);
      final usage = _usageFromJson(json['usage']);
      await mergeReviewStateAfterRestore(review);
      if (usage != null) {
        if (!Hive.isBoxOpen(kUsageBoxName)) {
          await Hive.openBox<dynamic>(kUsageBoxName, path: p.dirname(f.path));
        }
        await mergeUsageAfterRestore(usage);
      }
    }
    f.deleteSync();
    return json != null && recovered == RestoreRecovery.completed;
  } catch (_) {
    return false;
  }
}

Map<String, Object?> _reviewToJson(ReviewState s) => {
      'first': s.firstLaunchAt?.toIso8601String(),
      'last': s.lastPromptAt?.toIso8601String(),
      'version': s.lastPromptVersion,
      'shown': s.lastPromptShownAt?.toIso8601String(),
    };

ReviewState? _reviewFromJson(Object? j) {
  if (j is! Map) return null;
  DateTime? d(String k) => j[k] is String ? DateTime.tryParse(j[k]) : null;
  return ReviewState(
    firstLaunchAt: d('first'),
    lastPromptAt: d('last'),
    lastPromptVersion: j['version'] is String ? j['version'] as String : null,
    lastPromptShownAt: d('shown'),
  );
}

Map<String, Object?> _usageToJson(UsageSnapshot s) => {
      'counts': {
        for (final e in s.counts.entries)
          e.key.name: {
            'c': e.value.count,
            'f': e.value.firstMonth,
            'l': e.value.lastMonth,
          },
      },
      'on': s.countingOn,
      'disclosed': s.disclosureShown,
      'asked': s.askedVersion,
    };

UsageSnapshot? _usageFromJson(Object? j) {
  if (j is! Map) return null;
  final counts = <UsageEvent, UsageCount>{};
  final raw = j['counts'];
  if (raw is Map) {
    for (final e in UsageEvent.values) {
      final v = raw[e.name];
      if (v is! Map || v['c'] is! int) continue;
      counts[e] = UsageCount(v['c'] as int,
          firstMonth: v['f'] is String ? v['f'] as String : null,
          lastMonth: v['l'] is String ? v['l'] as String : null);
    }
  }
  return UsageSnapshot(
    counts: counts,
    countingOn: j['on'] is bool ? j['on'] as bool : null,
    disclosureShown: j['disclosed'] is bool ? j['disclosed'] as bool : null,
    askedVersion: j['asked'] is String ? j['asked'] as String : null,
  );
}
