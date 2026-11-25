import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/review/application/review_controller.dart';
import 'package:pos_app/features/review/data/review_state_store.dart';
import 'package:pos_app/features/review/domain/review_policy.dart';
import 'package:pos_app/features/review/domain/review_prompter.dart';
import 'package:pos_app/features/usage/application/usage_ask_controller.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/domain/usage_ask_policy.dart';
import 'package:pos_app/features/usage/usage_constants.dart';

const v = '1.1.0+10';
final now = DateTime(2026, 11, 25, 12);

/// A review already requested for [v] 20 days ago: the review is not due
/// for 40 more days, so the ask has nothing to yield to.
final reviewedThisVersion = ReviewState(
  firstLaunchAt: now.subtract(const Duration(days: 45)),
  lastPromptAt: now.subtract(const Duration(days: 20)),
  lastPromptVersion: v,
  lastPromptShownAt: now.subtract(const Duration(days: 20)),
);

bool ask({
  ReviewState? review,
  String? asked,
  int sales = 50,
  DateTime? at,
  bool reviewCanShow = true,
}) =>
    shouldAskForFeedback(
      review: review ?? reviewedThisVersion,
      askedVersion: asked,
      completedSales: sales,
      now: at ?? now,
      currentVersion: v,
      reviewCanShow: reviewCanShow,
    );

class _Prompter implements ReviewPrompter {
  _Prompter(this.available);
  final bool available;
  int calls = 0;
  @override
  Future<bool> maybeRequestReview() async {
    calls++;
    return available;
  }

  @override
  Future<void> openStoreListing({required String appStoreId}) async {}
}

void main() {
  group('shouldAskForFeedback', () {
    test('asks at 30 days AND 50 completed orders', () {
      expect(ask(), isTrue);
      expect(
          ask(
              review: ReviewState(
                  firstLaunchAt:
                      now.subtract(const Duration(days: 29, hours: 23)),
                  lastPromptAt: now.subtract(const Duration(days: 20)),
                  lastPromptVersion: v)),
          isFalse);
      expect(ask(sales: 49), isFalse);
      expect(ask(review: const ReviewState()), isFalse);
    });

    test('once per version (shown or dismissed counts the same)', () {
      expect(ask(asked: v), isFalse);
      expect(ask(asked: '1.0.0+9'), isTrue);
    });

    test('never within 14 days of any other prompt', () {
      ReviewState shownAt(DateTime t) => ReviewState(
          firstLaunchAt: reviewedThisVersion.firstLaunchAt,
          lastPromptAt: reviewedThisVersion.lastPromptAt,
          lastPromptVersion: v,
          lastPromptShownAt: t);
      expect(ask(review: shownAt(now.subtract(const Duration(days: 13)))),
          isFalse);
      expect(
          ask(review: shownAt(now.subtract(const Duration(days: 14)))), isTrue);
    });

    test('yields when the review is due now or within 14 days', () {
      // This version never reviewed; last review long ago: due now.
      final dueNow = ReviewState(
          firstLaunchAt: now.subtract(const Duration(days: 100)),
          lastPromptAt: now.subtract(const Duration(days: 90)),
          lastPromptVersion: '1.0.0');
      expect(ask(review: dueNow), isFalse);
      // Due in 10 days (last review 50 days ago).
      final dueSoon = ReviewState(
          firstLaunchAt: now.subtract(const Duration(days: 100)),
          lastPromptAt: now.subtract(const Duration(days: 50)),
          lastPromptVersion: '1.0.0');
      expect(ask(review: dueSoon), isFalse);
      // Due in 15 days: the ask may go first.
      final dueLater = ReviewState(
          firstLaunchAt: now.subtract(const Duration(days: 100)),
          lastPromptAt: now.subtract(const Duration(days: 45)),
          lastPromptVersion: '1.0.0');
      expect(ask(review: dueLater), isTrue);
      // No store review on this device: nothing to yield to.
      expect(ask(review: dueNow, reviewCanShow: false), isTrue);
    });

    test('a clock that moved backwards reads as "not yet"', () {
      expect(
          ask(
              review: ReviewState(
                  firstLaunchAt: now.add(const Duration(days: 40)),
                  lastPromptVersion: v)),
          isFalse);
      expect(
          ask(
              review: ReviewState(
                  firstLaunchAt: reviewedThisVersion.firstLaunchAt,
                  lastPromptAt: reviewedThisVersion.lastPromptAt,
                  lastPromptVersion: v,
                  lastPromptShownAt: now.add(const Duration(days: 1)))),
          isFalse);
    });

    test('the ask text does not mention counting', () {
      expect(kFeedbackAskText,
          "What's the one thing you'd change about Open POS?");
      expect(kOfflineFirstShortLine, 'Open POS works offline first.');
      for (final t in [kFeedbackAskText, kOfflineFirstShortLine]) {
        expect(t.toLowerCase(), isNot(contains('count')));
        expect(t.toLowerCase(), isNot(contains('usage')));
      }
    });
  });

  group('the review is never delayed by the ask', () {
    test('promptSpacingAllows', () {
      expect(promptSpacingAllows(null, now), isTrue);
      expect(promptSpacingAllows(now.subtract(const Duration(days: 14)), now),
          isTrue);
      expect(promptSpacingAllows(now.subtract(const Duration(days: 13)), now),
          isFalse);
      expect(promptSpacingAllows(now.add(const Duration(minutes: 1)), now),
          isFalse);
    });

    test('shouldRequestReview ignores a recent ask', () {
      final s = ReviewState(
        firstLaunchAt: now.subtract(const Duration(days: 100)),
        lastPromptShownAt: now.subtract(const Duration(days: 1)),
      );
      expect(
          shouldRequestReview(s,
              completedSales: 100, now: now, currentVersion: v),
          isTrue);
    });

    test('reviewEligibleWithin', () {
      final s = ReviewState(
          firstLaunchAt: now.subtract(const Duration(days: 1)),
          lastPromptAt: null);
      const w = Duration(days: 14);
      expect(reviewEligibleWithin(s, now: now, currentVersion: v, window: w),
          isTrue,
          reason: 'install +7 days falls inside the window');
      expect(
          reviewEligibleWithin(
              ReviewState(firstLaunchAt: s.firstLaunchAt, lastPromptVersion: v),
              now: now,
              currentVersion: v,
              window: w),
          isFalse,
          reason: 'already requested for this version');
    });

    test('review thresholds are unchanged', () {
      expect(kReviewMinDaysSinceInstall, 7);
      expect(kReviewMinCompletedSales, 20);
      expect(kReviewMinDaysBetweenPrompts, 60);
      expect(kMinDaysBetweenAnyPrompts, 14);
      expect(kUsageAskMinDaysSinceInstall, 30);
      expect(kUsageAskMinCompletedSales, 50);
    });

    test('lastAnyPromptAt falls back to the review date (older installs)', () {
      final r = DateTime(2026, 5, 1);
      expect(ReviewState(lastPromptAt: r).lastAnyPromptAt, r);
      expect(
          ReviewState(lastPromptAt: r, lastPromptShownAt: DateTime(2026, 6, 1))
              .lastAnyPromptAt,
          DateTime(2026, 6, 1));
    });
  });

  group('controllers', () {
    late Directory tmp;
    late Box<dynamic> settings;
    late Box<dynamic> usageBox;
    late ReviewStateStore store;
    late UsageCounter counter;
    var clock = now;
    var sales = 60;

    Future<void> openFresh() async {
      tmp = await Directory.systemTemp.createTemp('pos_usage_ask_');
      Hive.init(tmp.path);
      settings = await Hive.openBox<dynamic>('settings');
      usageBox = await Hive.openBox<dynamic>(kUsageBoxName);
      store = ReviewStateStore(settings);
      counter = UsageCounter(openBox: () async => usageBox);
    }

    Future<void> closeAll() async {
      await Hive.close();
      await tmp.delete(recursive: true);
    }

    setUp(() async {
      await openFresh();
      clock = now;
      sales = 60;
      await store.ensureFirstLaunch(now.subtract(const Duration(days: 45)));
    });
    tearDown(closeAll);

    UsageAskController askCtl(
            {bool reviewSupported = true,
            String version = v,
            bool fossBuild = false}) =>
        UsageAskController(
          reviewStore: store,
          counter: counter,
          completedSales: () async => sales,
          appVersion: version,
          reviewSupported: reviewSupported,
          fossBuild: fossBuild,
          clock: () => clock,
        );

    ReviewController reviewCtl(ReviewPrompter p, UsageAskController a,
            {String version = v}) =>
        ReviewController(
          store: store,
          prompter: p,
          completedSales: () async => sales,
          appVersion: version,
          clock: () => clock,
          afterCheck: a.afterReviewCheck,
          settleDelay: Duration.zero,
        );

    test('review requested: no ask, for the rest of the session', () async {
      final a = askCtl();
      final r = reviewCtl(_Prompter(true), a);
      expect(await r.runCheck(), ReviewCheck.requested);
      expect(await a.evaluate(ReviewCheck.requested), isFalse);
      expect(settings.get(kPromptLastShownAt), isNotNull);
      clock = now.add(const Duration(days: 30));
      expect(await a.evaluate(ReviewCheck.notEligible), isFalse);
      expect(a.pending.value, isFalse);
    });

    test('F-Droid build, review unavailable: the ask may show', () async {
      final a = askCtl(fossBuild: true);
      final r = reviewCtl(_Prompter(false), a);
      expect(await r.runCheck(), ReviewCheck.unavailable);
      expect(store.read().lastPromptVersion, isNull,
          reason: 'an unavailable review is never marked prompted');
      expect(await a.evaluate(ReviewCheck.unavailable), isTrue);
      await a.markShown();
      // …and on later days it does not repeat for this version.
      clock = now.add(const Duration(days: 20));
      expect(await a.evaluate(ReviewCheck.unavailable), isFalse);
    });

    test('Play offline at one receipt, online at the next: the ask yields',
        () async {
      // The review is due now (45 days in, never asked).
      final a = askCtl();
      final offline = reviewCtl(_Prompter(false), a);
      expect(await offline.runCheck(), ReviewCheck.unavailable);
      expect(await a.evaluate(ReviewCheck.unavailable), isFalse,
          reason: 'one unavailable check is not "no store"');
      expect(a.pending.value, isFalse);
      expect(counter.reviewUnavailableSince, now);

      clock = now.add(const Duration(minutes: 5));
      final online = reviewCtl(_Prompter(true), a);
      expect(await online.runCheck(), ReviewCheck.requested);
      expect(await a.evaluate(ReviewCheck.requested), isFalse);
      expect(counter.reviewUnavailableSince, isNull,
          reason: 'a request ends the unavailable streak');
    });

    test('review unavailable for 14 days or more: the ask may show',
        () async {
      final a = askCtl();
      final r = reviewCtl(_Prompter(false), a);
      expect(await r.runCheck(), ReviewCheck.unavailable);
      expect(await a.evaluate(ReviewCheck.unavailable), isFalse);
      clock = now.add(const Duration(days: 13, hours: 23));
      expect(await a.evaluate(ReviewCheck.unavailable), isFalse);
      clock = now.add(kReviewUnavailableGiveUp);
      expect(await a.evaluate(ReviewCheck.unavailable), isTrue);
    });

    test('review not eligible: the ask fires once, then never this version',
        () async {
      await store.markPrompted(now.subtract(const Duration(days: 20)), v);
      final a = askCtl();
      final r = reviewCtl(_Prompter(true), a);
      expect(await r.runCheck(), ReviewCheck.notEligible);
      expect(await a.evaluate(ReviewCheck.notEligible), isTrue);
      await a.markShown();
      expect(counter.askedVersion, v);
      expect(store.read().lastPromptShownAt, now);
      clock = now.add(const Duration(days: 90));
      expect(await a.evaluate(ReviewCheck.notEligible), isFalse);
    });

    test('too few orders, or a skipped check: no ask', () async {
      await store.markPrompted(now.subtract(const Duration(days: 20)), v);
      expect(await askCtl().evaluate(ReviewCheck.skipped), isFalse);
      sales = 49;
      expect(await askCtl().evaluate(ReviewCheck.notEligible), isFalse);
    });

    test('no usage box: no ask (it could not be remembered)', () async {
      await store.markPrompted(now.subtract(const Duration(days: 20)), v);
      counter = UsageCounter(openBox: () async => throw StateError('no box'));
      expect(await askCtl().evaluate(ReviewCheck.notEligible), isFalse);
    });

    test('restore merge keeps the latest shared prompt date', () async {
      await settings.put(
          kPromptLastShownAt, DateTime(2026, 3, 1).toIso8601String());
      await store.mergeAfterRestore(ReviewState(
          firstLaunchAt: now.subtract(const Duration(days: 45)),
          lastPromptShownAt: DateTime(2026, 11, 1)));
      expect(store.read().lastPromptShownAt, DateTime(2026, 11, 1));
      await store.mergeAfterRestore(
          ReviewState(lastPromptShownAt: DateTime(2026, 1, 1)));
      expect(store.read().lastPromptShownAt, DateTime(2026, 11, 1));
    });

    test('onReceiptDismissed hands the review outcome to the ask', () async {
      await store.markPrompted(now.subtract(const Duration(days: 20)), v);
      final a = askCtl();
      reviewCtl(_Prompter(true), a).onReceiptDismissed();
      for (var i = 0; i < 20 && !a.pending.value; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(a.pending.value, isTrue);
    });

    /// One simulated year, a receipt closed every day, 3 orders a day and
    /// a new app version every few weeks. Returns the days the store review
    /// was requested (and the days the ask was shown).
    Future<({List<int> reviews, List<int> asks})> simulateYear(
        {required bool withAsk}) async {
      await closeAll();
      await openFresh();
      final start = DateTime(2026, 1, 1, 18);
      await store.ensureFirstLaunch(start);
      const releases = [0, 25, 70, 96, 150, 170, 230, 262, 300, 340];
      final reviews = <int>[];
      final asks = <int>[];
      for (var day = 0; day < 365; day++) {
        clock = start.add(Duration(days: day));
        sales = 3 * (day + 1);
        final version = '1.${releases.lastIndexWhere((d) => d <= day)}.0';
        // A fresh session each day.
        final a = askCtl(version: version);
        final p = _Prompter(true);
        final r = reviewCtl(p, a, version: version);
        final result = await r.runCheck();
        if (result == ReviewCheck.requested) reviews.add(day);
        if (withAsk && await a.evaluate(result)) {
          await a.markShown(); // shown, then dismissed
          asks.add(day);
        }
      }
      return (reviews: reviews, asks: asks);
    }

    test('a year day by day: the review fires on exactly the same days',
        () async {
      final alone = await simulateYear(withAsk: false);
      final both = await simulateYear(withAsk: true);
      // ignore: avoid_print
      print('review days: ${alone.reviews}; ask days: ${both.asks}');
      expect(alone.reviews, isNotEmpty);
      expect(both.asks, isNotEmpty, reason: 'the ask must get a turn');
      expect(both.reviews, alone.reviews);
      // And the ask never comes within 14 days before a review.
      for (final ask in both.asks) {
        for (final review in both.reviews) {
          expect(review - ask >= 0 && review - ask < 14, isFalse,
              reason: 'ask on day $ask, review on day $review');
        }
      }
    });
  });
}
