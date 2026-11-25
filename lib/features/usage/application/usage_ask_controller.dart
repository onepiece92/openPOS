import 'dart:async';

import 'package:flutter/foundation.dart' show ValueNotifier, debugPrint;

import 'package:pos_app/features/review/application/review_controller.dart';
import 'package:pos_app/features/review/data/review_state_store.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/domain/usage_ask_policy.dart';

/// Decides when to show the gentle feedback ask, hanging off the review
/// check that runs after a receipt is closed ([afterReviewCheck]).
///
/// Store guidelines: the ask must never gate or precede the store review.
/// So it is only considered when the review check found the review NOT
/// eligible — never after a request, and never in a session where the
/// review was eligible but the store could not show it (when a store
/// exists, [reviewSupported]). It also shares the 14-day spacing with the
/// review prompt (`kPromptLastShownAt`).
///
/// Showing is done by `UsageHost`, which listens to [pending] and calls
/// [markShown] the moment the ask appears.
class UsageAskController {
  UsageAskController({
    required this.reviewStore,
    required this.counter,
    required this.completedSales,
    required this.appVersion,
    required this.reviewSupported,
    DateTime Function()? clock,
    this.timeout = const Duration(seconds: 5),
  }) : _clock = clock ?? DateTime.now;

  final ReviewStateStore reviewStore;
  final UsageCounter counter;
  final Future<int> Function() completedSales;
  final String appVersion;
  final bool reviewSupported;
  final Duration timeout;
  final DateTime Function() _clock;

  /// True while an ask is waiting to be shown.
  final ValueNotifier<bool> pending = ValueNotifier(false);

  bool _reviewEligibleThisSession = false;
  bool _inFlight = false;

  /// Never throws; never awaited by a UI path.
  void afterReviewCheck(ReviewCheck result) {
    unawaited(evaluate(result));
  }

  /// One evaluation; completes after the (bounded) order count.
  Future<bool> evaluate(ReviewCheck result) async {
    try {
      switch (result) {
        case ReviewCheck.requested:
          _reviewEligibleThisSession = true;
          return false;
        case ReviewCheck.unavailable:
          // The review was eligible; with a store present that blocks the
          // ask for the whole session. Without one there is no review to
          // precede.
          if (reviewSupported) {
            _reviewEligibleThisSession = true;
            return false;
          }
        case ReviewCheck.skipped:
          return false;
        case ReviewCheck.notEligible:
          break;
      }
      if (_reviewEligibleThisSession || _inFlight || pending.value) {
        return false;
      }
      _inFlight = true;
      try {
        await counter.ensureLoaded();
        final now = _clock();
        final s = reviewStore.read();
        bool passes(int sales) => shouldAskForFeedback(
              firstLaunchAt: s.firstLaunchAt,
              lastAnyPromptAt: s.lastAnyPromptAt,
              askedVersion: counter.askedVersion,
              completedSales: sales,
              now: now,
              currentVersion: appVersion,
            );
        if (!passes(kUsageAskMinCompletedSales)) return false;
        if (!passes(await completedSales().timeout(timeout))) return false;
        pending.value = true;
        return true;
      } finally {
        _inFlight = false;
      }
    } catch (e) {
      debugPrint('usage ask: ignored $e');
      return false;
    }
  }

  /// The ask is on screen: it counts as asked for this version (so
  /// dismissing it means "not again this version") and as the latest prompt
  /// for the shared spacing.
  Future<void> markShown() async {
    pending.value = false;
    try {
      await counter.markAsked(appVersion);
      await reviewStore.markAnyPromptShown(_clock());
    } catch (_) {/* best effort */}
  }

  void dispose() => pending.dispose();
}
