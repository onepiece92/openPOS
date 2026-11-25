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
///   [kMinDaysBetweenAnyPrompts] days ([promptSpacingAllows]).
///
/// Days are elapsed 24-hour periods: a clock that moved backwards reads as
/// "not yet", never as "long ago".
///
/// The caller additionally never asks in a session where the store review
/// was eligible (see `UsageAskController`).
bool shouldAskForFeedback({
  required DateTime? firstLaunchAt,
  required DateTime? lastAnyPromptAt,
  required String? askedVersion,
  required int completedSales,
  required DateTime now,
  required String currentVersion,
}) {
  if (firstLaunchAt == null) return false;
  if (now.difference(firstLaunchAt) <
      const Duration(days: kUsageAskMinDaysSinceInstall)) {
    return false;
  }
  if (completedSales < kUsageAskMinCompletedSales) return false;
  if (askedVersion == currentVersion) return false;
  if (!promptSpacingAllows(lastAnyPromptAt, now)) return false;
  return true;
}
