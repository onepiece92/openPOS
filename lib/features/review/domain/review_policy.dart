import 'package:flutter/foundation.dart' show immutable;

/// Thresholds for the automatic review request.
const kReviewMinDaysSinceInstall = 7;
const kReviewMinCompletedSales = 20;
const kReviewMinDaysBetweenPrompts = 60;

/// Shared spacing: no prompt of any kind (store review, feedback ask) within
/// this many days of the last one. See [promptSpacingAllows].
const kMinDaysBetweenAnyPrompts = 14;

/// True when at least [kMinDaysBetweenAnyPrompts] full days have passed since
/// [lastAnyPromptAt] (or no prompt was ever shown). A last prompt in the
/// future (clock moved backwards, or a restored date from a fast clock)
/// reads as "too soon", like the review rule's own date checks.
bool promptSpacingAllows(DateTime? lastAnyPromptAt, DateTime now) =>
    lastAnyPromptAt == null ||
    now.difference(lastAnyPromptAt) >=
        const Duration(days: kMinDaysBetweenAnyPrompts);

/// Persisted trigger state (see `ReviewStateStore`). The number of sales is
/// not part of it: that is counted from the orders table when needed.
@immutable
class ReviewState {
  const ReviewState({
    this.firstLaunchAt,
    this.lastPromptAt,
    this.lastPromptVersion,
    this.lastPromptShownAt,
  });

  final DateTime? firstLaunchAt;

  /// Last store-review request.
  final DateTime? lastPromptAt;
  final String? lastPromptVersion;

  /// Last time ANY prompt was shown (shared with the feedback ask).
  final DateTime? lastPromptShownAt;

  /// The later of [lastPromptShownAt] and [lastPromptAt]: installs from
  /// before the shared key only have the review date.
  DateTime? get lastAnyPromptAt {
    final a = lastPromptShownAt;
    final b = lastPromptAt;
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }
}

/// Pure decision: request a review only when ALL hold —
/// * ≥ [kReviewMinDaysSinceInstall] days since first launch,
/// * [completedSales] ≥ [kReviewMinCompletedSales] (orders with status
///   'completed' in the database),
/// * ≥ [kReviewMinDaysBetweenPrompts] days since the last request (or never),
/// * [currentVersion] has not been prompted yet,
/// * no other prompt was shown in the last [kMinDaysBetweenAnyPrompts]
///   days ([promptSpacingAllows]).
///
/// "Days" are elapsed 24-hour periods, so a clock that jumps backwards (or a
/// restored first-launch date in the future) simply reads as "not yet".
bool shouldRequestReview(
  ReviewState s, {
  required int completedSales,
  required DateTime now,
  required String currentVersion,
}) {
  final first = s.firstLaunchAt;
  if (first == null) return false;
  if (now.difference(first) < const Duration(days: kReviewMinDaysSinceInstall)) {
    return false;
  }
  if (completedSales < kReviewMinCompletedSales) return false;
  final last = s.lastPromptAt;
  if (last != null &&
      now.difference(last) <
          const Duration(days: kReviewMinDaysBetweenPrompts)) {
    return false;
  }
  if (s.lastPromptVersion == currentVersion) return false;
  if (!promptSpacingAllows(s.lastAnyPromptAt, now)) return false;
  return true;
}
