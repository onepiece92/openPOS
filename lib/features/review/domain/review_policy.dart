import 'package:flutter/foundation.dart' show immutable;

/// Thresholds for the automatic review request.
const kReviewMinDaysSinceInstall = 7;
const kReviewMinCompletedSales = 20;
const kReviewMinDaysBetweenPrompts = 60;

/// Persisted trigger state (see `ReviewStateStore`).
@immutable
class ReviewState {
  const ReviewState({
    this.firstLaunchAt,
    this.completedSales = 0,
    this.lastPromptAt,
    this.lastPromptVersion,
  });

  final DateTime? firstLaunchAt;
  final int completedSales;
  final DateTime? lastPromptAt;
  final String? lastPromptVersion;
}

/// Pure decision: request a review only when ALL hold —
/// * ≥ [kReviewMinDaysSinceInstall] days since first launch,
/// * ≥ [kReviewMinCompletedSales] completed sales,
/// * ≥ [kReviewMinDaysBetweenPrompts] days since the last request (or never),
/// * [currentVersion] has not been prompted yet.
///
/// "Days" are elapsed 24-hour periods, so a clock that jumps backwards (or a
/// restored first-launch date in the future) simply reads as "not yet".
bool shouldRequestReview(
  ReviewState s, {
  required DateTime now,
  required String currentVersion,
}) {
  final first = s.firstLaunchAt;
  if (first == null) return false;
  if (now.difference(first) < const Duration(days: kReviewMinDaysSinceInstall)) {
    return false;
  }
  if (s.completedSales < kReviewMinCompletedSales) return false;
  final last = s.lastPromptAt;
  if (last != null &&
      now.difference(last) <
          const Duration(days: kReviewMinDaysBetweenPrompts)) {
    return false;
  }
  if (s.lastPromptVersion == currentVersion) return false;
  return true;
}
