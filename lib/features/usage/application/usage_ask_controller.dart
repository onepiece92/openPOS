import 'dart:async';

import 'package:flutter/foundation.dart' show ValueNotifier, debugPrint;

import 'package:pos_app/features/review/application/review_controller.dart';
import 'package:pos_app/features/review/data/review_state_store.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/domain/usage_ask_policy.dart';

/// True in the F-Droid `foss` build, which has no store review at all:
/// build it with `--dart-define=OPENPOS_FOSS=true` (see
/// packages/in_app_review_stub). The stub cannot say so itself — the real
/// package has no such constant to import.
const kFossBuild = bool.fromEnvironment('OPENPOS_FOSS');

/// How long the review must have been unavailable, at every check, before
/// the ask stops yielding to it.
const kReviewUnavailableGiveUp = Duration(days: 14);

/// Decides when to show the gentle feedback ask, hanging off the review
/// check that runs after a receipt is closed ([afterReviewCheck]).
///
/// Store guidelines: the ask must never gate, precede or delay the store
/// review. It is never shown in a session where a review was requested,
/// and it yields whenever the review may become due within 14 days
/// (`shouldAskForFeedback`). [reviewSupported] says whether a store exists
/// at all.
///
/// "Review unavailable" at one receipt is NOT taken as "there is no store":
/// on a Play device that is offline at one receipt and online at the next,
/// the review sheet could follow the ask minutes later. The ask yields to
/// the review exactly as for "not eligible", unless there really is no
/// store to yield to: the F-Droid build ([fossBuild], set by
/// `--dart-define=OPENPOS_FOSS=true`), or a review that has been
/// unavailable at every check for [kReviewUnavailableGiveUp] (since the
/// first unavailable check, kept in the usage box; any review request
/// clears it).
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
    this.fossBuild = kFossBuild,
    DateTime Function()? clock,
    this.timeout = const Duration(seconds: 5),
  }) : _clock = clock ?? DateTime.now;

  final ReviewStateStore reviewStore;
  final UsageCounter counter;
  final Future<int> Function() completedSales;
  final String appVersion;
  final bool reviewSupported;
  final bool fossBuild;
  final Duration timeout;
  final DateTime Function() _clock;

  /// True while an ask is waiting to be shown.
  final ValueNotifier<bool> pending = ValueNotifier(false);

  bool _reviewRequestedThisSession = false;
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
          // Never in the session of a review request.
          _reviewRequestedThisSession = true;
          // The store works: an earlier "unavailable" streak is over.
          await counter.ensureLoaded();
          await counter.setReviewUnavailableSince(null);
          return false;
        case ReviewCheck.skipped:
          return false;
        case ReviewCheck.unavailable:
        case ReviewCheck.notEligible:
          break;
      }
      if (_reviewRequestedThisSession || _inFlight || pending.value) {
        return false;
      }
      _inFlight = true;
      try {
        await counter.ensureLoaded();
        // No box: "asked" could not be remembered, so never ask.
        if (!counter.isLoaded) return false;
        final now = _clock();
        var since = counter.reviewUnavailableSince;
        if (result == ReviewCheck.unavailable && since == null) {
          since = now;
          await counter.setReviewUnavailableSince(now);
        }
        final noStore = fossBuild ||
            (since != null && now.difference(since) >= kReviewUnavailableGiveUp);
        final reviewCanShow = reviewSupported && !noStore;
        final s = reviewStore.read();
        bool passes(int sales) => shouldAskForFeedback(
              review: s,
              askedVersion: counter.askedVersion,
              completedSales: sales,
              now: now,
              currentVersion: appVersion,
              reviewCanShow: reviewCanShow,
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
