import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;

import 'package:pos_app/features/review/data/review_state_store.dart';
import 'package:pos_app/features/review/domain/review_policy.dart';
import 'package:pos_app/features/review/domain/review_prompter.dart';

/// What one [ReviewController.runCheck] found.
enum ReviewCheck {
  /// The rule did not pass: nothing was asked.
  notEligible,

  /// The OS was asked to show its review sheet (or may be showing it).
  requested,

  /// The rule passed but the store said review is unavailable.
  unavailable,

  /// Not evaluated: a check was already running, or something threw.
  skipped,
}

/// Wires the pure [shouldRequestReview] rule to persisted state and the
/// platform [ReviewPrompter].
///
/// Hook: [onReceiptDismissed] when the receipt screen goes away. Sales are
/// not counted here — [completedSales] reads the number of completed orders
/// from the database, so viewing a receipt again can never inflate it.
///
/// The hook returns no Future: everything runs unawaited, after
/// [settleDelay] (so the next screen has finished navigating), bounded by
/// [timeout] and wrapped in a catch-all. A throwing, hanging or "unavailable"
/// store (no network, sideloaded APK, no Play services) is silently ignored
/// and can never block or delay checkout.
class ReviewController {
  ReviewController({
    required this.store,
    required this.prompter,
    required this.completedSales,
    required this.appVersion,
    DateTime Function()? clock,
    this.settleDelay = const Duration(seconds: 1),
    this.timeout = const Duration(seconds: 5),
    this.afterCheck,
    this.enabled,
  }) : _clock = clock ?? DateTime.now;

  /// The Review reminder switch. While it says false, [onReceiptDismissed]
  /// does nothing at all: no store review, no feedback ask, no I/O.
  final bool Function()? enabled;

  /// Called after every check from [onReceiptDismissed] with its outcome —
  /// the feedback ask hangs off this so it only ever runs when the review
  /// request did not (see `UsageAskController`). Must not throw.
  final void Function(ReviewCheck result)? afterCheck;

  final ReviewStateStore store;
  final ReviewPrompter prompter;

  /// Completed orders in the database; may stop counting at
  /// [kReviewMinCompletedSales].
  final Future<int> Function() completedSales;
  final String appVersion;
  final Duration settleDelay;
  final Duration timeout;
  final DateTime Function() _clock;

  bool _inFlight = false;

  void onReceiptDismissed() {
    if (enabled?.call() == false) return;
    unawaited(_guard(() async {
      await Future<void>.delayed(settleDelay);
      final result = await runCheck();
      afterCheck?.call(result);
      return result;
    }));
  }

  /// One evaluation of the rule (+ the request when it passes). Completes
  /// within about [timeout]; never throws.
  @visibleForTesting
  Future<ReviewCheck> runCheck() => _guard(() async {
        if (_inFlight) return ReviewCheck.skipped;
        final now = _clock();
        final state = store.read();
        bool passes(int sales) => shouldRequestReview(state,
            completedSales: sales, now: now, currentVersion: appVersion);
        // Dates and version first (no I/O): the database is only asked
        // when the sale count is the one thing left to decide.
        if (!passes(kReviewMinCompletedSales)) return ReviewCheck.notEligible;
        _inFlight = true;
        try {
          if (!passes(await completedSales().timeout(timeout))) {
            return ReviewCheck.notEligible;
          }
          bool asked;
          try {
            asked = await prompter.maybeRequestReview().timeout(timeout);
          } on TimeoutException {
            // The sheet may be up; count it so we don't re-ask next sale.
            asked = true;
          }
          if (!asked) return ReviewCheck.unavailable;
          await store.markPrompted(now, appVersion);
          return ReviewCheck.requested;
        } finally {
          _inFlight = false;
        }
      });

  Future<ReviewCheck> _guard(Future<ReviewCheck> Function() body) async {
    try {
      return await body();
    } catch (e) {
      debugPrint('review: ignored $e');
      return ReviewCheck.skipped;
    }
  }
}
