import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/review/domain/review_policy.dart';

/// Reads/writes the review trigger keys in the `settings` Hive box.
///
/// Backup/restore: the settings box travels with snapshots, so a restore
/// overwrites these keys with the backup's values. That is safe in the
/// direction that matters — an older backup can only *lower* the sale count
/// or move the first-launch date earlier. It can, however, roll back
/// `last_prompt_at`/`last_prompt_version`, which could allow one extra
/// request per version; the OS rate limits (iOS: 3 per 365 days; Play:
/// quota-based) still apply. Intended behaviour after a restore is to keep
/// the EARLIEST first-launch date and the LATEST prompt date/version from
/// the two boxes. Merging needs a hook in the restore path, which lives in
/// `AppRoot` — left as a follow-up (call [mergeAfterRestore] there).
class ReviewStateStore {
  ReviewStateStore(this._box);
  final Box<dynamic> _box;

  ReviewState read() => ReviewState(
        firstLaunchAt: _date(kReviewFirstLaunchAt),
        completedSales: switch (_box.get(kReviewCompletedSales)) {
          final int n when n >= 0 => n,
          _ => 0,
        },
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

  Future<void> incrementCompletedSales() =>
      _box.put(kReviewCompletedSales, read().completedSales + 1);

  Future<void> markPrompted(DateTime at, String version) async {
    await _box.put(kReviewLastPromptAt, at.toIso8601String());
    await _box.put(kReviewLastPromptVersion, version);
  }

  /// Restore-merge helper (see class doc): keeps the earliest first-launch,
  /// the higher sale count and the latest prompt date/version of [before]
  /// (captured pre-restore) and the restored box.
  Future<void> mergeAfterRestore(ReviewState before) async {
    final after = read();
    DateTime? earliest(DateTime? a, DateTime? b) =>
        a == null ? b : (b == null || a.isBefore(b) ? a : b);
    final first = earliest(before.firstLaunchAt, after.firstLaunchAt);
    if (first != null) {
      await _box.put(kReviewFirstLaunchAt, first.toIso8601String());
    }
    if (before.completedSales > after.completedSales) {
      await _box.put(kReviewCompletedSales, before.completedSales);
    }
    final b = before.lastPromptAt;
    final a = after.lastPromptAt;
    if (b != null && (a == null || b.isAfter(a))) {
      await markPrompted(
          b, before.lastPromptVersion ?? after.lastPromptVersion ?? '');
    }
  }
}
