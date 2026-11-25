import 'package:pos_app/features/review/domain/review_policy.dart';

/// Thresholds for the gentle feedback ask (`kFeedbackAskText`).
const kUsageAskMinDaysSinceInstall = 30;
const kUsageAskMinCompletedSales = 50;

/// Pure decision for the feedback ask. Ask only when ALL hold —
/// * ≥ [kUsageAskMinDaysSinceInstall] days since first launch,
/// * [completedSales] ≥ [kUsageAskMinCompletedSales],
/// * [currentVersion] was not asked yet ([askedVersion]); being shown at
///   all counts, so dismissing it means "not again this version",
/// * no prompt of any kind (store review included) in the last
///   [kMinDaysBetweenAnyPrompts] days ([promptSpacingAllows]),
/// * the ask yields to the store review: when the review can be shown on
///   this device ([reviewCanShow]), it is skipped whenever the review is
///   due now or may become due within [kMinDaysBetweenAnyPrompts] days
///   ([reviewEligibleWithin]). The review rule itself ignores the ask, so
///   the review is never delayed by it.
///
/// Days are elapsed 24-hour periods: a clock that moved backwards reads as
/// "not yet", never as "long ago".
bool shouldAskForFeedback({
  required ReviewState review,
  required String? askedVersion,
  required int completedSales,
  required DateTime now,
  required String currentVersion,
  required bool reviewCanShow,
}) {
  final first = review.firstLaunchAt;
  if (first == null) return false;
  if (now.difference(first) <
      const Duration(days: kUsageAskMinDaysSinceInstall)) {
    return false;
  }
  if (completedSales < kUsageAskMinCompletedSales) return false;
  if (askedVersion == currentVersion) return false;
  if (!promptSpacingAllows(review.lastAnyPromptAt, now)) return false;
  if (reviewCanShow &&
      reviewEligibleWithin(review,
          now: now,
          currentVersion: currentVersion,
          window: const Duration(days: kMinDaysBetweenAnyPrompts))) {
    return false;
  }
  return true;
}
