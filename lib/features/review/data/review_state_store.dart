import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/review/domain/review_policy.dart';

/// Reads/writes the review trigger keys in the `settings` Hive box.
///
/// Backup/restore: the settings box travels with snapshots, so a restore
/// overwrites these keys with the backup's values. (The sale count is not
/// stored here — it is read from the orders table, so it always matches the
/// data in use.) An older backup can only move the first-launch date
/// earlier, which is harmless. It can, however, roll back
/// `last_prompt_at`/`last_prompt_version`, which could allow one extra
/// request per version; the OS rate limits (iOS: 3 per 365 days; Play:
/// quota-based) still apply. Intended behaviour after a restore is to keep
/// the EARLIEST first-launch date and the LATEST prompt date/version from
/// the two boxes: `AppRoot.restoreFrom` captures the state with
/// [reviewStateBeforeRestore] before the files are swapped and calls
/// [mergeReviewStateAfterRestore] once the box is open again.
class ReviewStateStore {
  ReviewStateStore(this._box);
  final Box<dynamic> _box;

  ReviewState read() => ReviewState(
        firstLaunchAt: _date(kReviewFirstLaunchAt),
        lastPromptAt: _date(kReviewLastPromptAt),
        lastPromptVersion: switch (_box.get(kReviewLastPromptVersion)) {
          final String v => v,
          _ => null,
        },
      );

  DateTime? _date(String key) {
    final v = _box.get(key);
    return v is String ? DateTime.tryParse(v) : null;
  }

  /// Records the first launch if it isn't known yet. Call once at startup.
  Future<void> ensureFirstLaunch(DateTime now) async {
    if (_date(kReviewFirstLaunchAt) != null) return;
    await _box.put(kReviewFirstLaunchAt, now.toIso8601String());
  }

  Future<void> markPrompted(DateTime at, String version) async {
    await _box.put(kReviewLastPromptAt, at.toIso8601String());
    await _box.put(kReviewLastPromptVersion, version);
  }

  /// Restore-merge helper (see class doc): keeps the earliest first-launch
  /// and the latest prompt date/version of [before]
  /// (captured pre-restore) and the restored box.
  Future<void> mergeAfterRestore(ReviewState before) async {
    final after = read();
    DateTime? earliest(DateTime? a, DateTime? b) =>
        a == null ? b : (b == null || a.isBefore(b) ? a : b);
    final first = earliest(before.firstLaunchAt, after.firstLaunchAt);
    // Nothing is written when the box already holds the merged values (e.g.
    // after a rollback, when it is the pre-restore box again).
    if (first != null && first != after.firstLaunchAt) {
      await _box.put(kReviewFirstLaunchAt, first.toIso8601String());
    }
    final b = before.lastPromptAt;
    final a = after.lastPromptAt;
    if (b != null && (a == null || b.isAfter(a))) {
      await markPrompted(
          b, before.lastPromptVersion ?? after.lastPromptVersion ?? '');
    }
  }
}

/// The review state of the open `settings` box, captured by the restore flow
/// BEFORE the Hive files are swapped. Null (and never an exception) when the
/// box is not open or cannot be read: the restore then simply skips the merge.
ReviewState? reviewStateBeforeRestore() {
  try {
    if (!Hive.isBoxOpen(_settingsBox)) return null;
    return ReviewStateStore(Hive.box<dynamic>(_settingsBox)).read();
  } catch (_) {
    return null;
  }
}

/// Called by the restore flow once the `settings` box is open again — on the
/// restored data, or on the old data after a rollback (where it changes
/// nothing). Never throws: review bookkeeping must not be able to fail or
/// undo a restore.
Future<void> mergeReviewStateAfterRestore(ReviewState? before) async {
  if (before == null) return;
  try {
    if (!Hive.isBoxOpen(_settingsBox)) return;
    await ReviewStateStore(Hive.box<dynamic>(_settingsBox))
        .mergeAfterRestore(before);
  } catch (_) {/* best effort */}
}

const _settingsBox = 'settings';
