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

const v = '1.1.0+10';
final now = DateTime(2026, 11, 25, 12);

bool ask({
  DateTime? first,
  DateTime? lastAny,
  String? asked,
  int sales = 50,
  DateTime? at,
  String version = v,
}) =>
    shouldAskForFeedback(
      firstLaunchAt: first ?? now.subtract(const Duration(days: 30)),
      lastAnyPromptAt: lastAny,
      askedVersion: asked,
      completedSales: sales,
      now: at ?? now,
      currentVersion: version,
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
      expect(ask(first: now.subtract(const Duration(days: 29, hours: 23))),
          isFalse);
      expect(ask(sales: 49), isFalse);
      expect(
          shouldAskForFeedback(
              firstLaunchAt: null,
              lastAnyPromptAt: null,
              askedVersion: null,
              completedSales: 999,
              now: now,
              currentVersion: v),
          isFalse);
    });

    test('once per version (shown or dismissed counts the same)', () {
      expect(ask(asked: v), isFalse);
      expect(ask(asked: '1.0.0+9'), isTrue);
    });

    test('never within 14 days of any other prompt', () {
      expect(ask(lastAny: now.subtract(const Duration(days: 13, hours: 23))),
          isFalse);
      expect(ask(lastAny: now.subtract(const Duration(days: 14))), isTrue);
    });

    test('a clock that moved backwards reads as "not yet"', () {
      // Install date and last prompt both "in the future".
      expect(ask(first: now.add(const Duration(days: 40))), isFalse);
      expect(ask(lastAny: now.add(const Duration(days: 1))), isFalse);
      expect(ask(lastAny: now.add(const Duration(days: 400))), isFalse);
    });
  });

  group('shared spacing', () {
    test('promptSpacingAllows', () {
      expect(promptSpacingAllows(null, now), isTrue);
      expect(promptSpacingAllows(now.subtract(const Duration(days: 14)), now),
          isTrue);
      expect(
          promptSpacingAllows(
              now.subtract(const Duration(days: 13, hours: 23)), now),
          isFalse);
      expect(promptSpacingAllows(now.add(const Duration(minutes: 1)), now),
          isFalse);
    });

    test('the review rule also waits 14 days after the feedback ask', () {
      final s = ReviewState(
        firstLaunchAt: now.subtract(const Duration(days: 100)),
        lastPromptShownAt: now.subtract(const Duration(days: 3)),
      );
      expect(
          shouldRequestReview(s,
              completedSales: 100, now: now, currentVersion: v),
          isFalse);
      expect(
          shouldRequestReview(s,
              completedSales: 100,
              now: now.add(const Duration(days: 11)),
              currentVersion: v),
          isTrue);
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

  group('UsageAskController + ReviewController', () {
    late Directory tmp;
    late Box<dynamic> settings;
    late Box<dynamic> usageBox;
    late ReviewStateStore store;
    late UsageCounter counter;
    var clock = now;
    var sales = 60;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('pos_usage_ask_');
      Hive.init(tmp.path);
      settings = await Hive.openBox<dynamic>('settings');
      usageBox = await Hive.openBox<dynamic>(kUsageBoxName);
      store = ReviewStateStore(settings);
      counter = UsageCounter(openBox: () async => usageBox);
      clock = now;
      sales = 60;
      await store.ensureFirstLaunch(now.subtract(const Duration(days: 45)));
    });
    tearDown(() async {
      await Hive.close();
      await tmp.delete(recursive: true);
    });

    UsageAskController askCtl({bool reviewSupported = true}) =>
        UsageAskController(
          reviewStore: store,
          counter: counter,
          completedSales: () async => sales,
          appVersion: v,
          reviewSupported: reviewSupported,
          clock: () => clock,
        );

    ReviewController reviewCtl(ReviewPrompter p, UsageAskController a) =>
        ReviewController(
          store: store,
          prompter: p,
          completedSales: () async => sales,
          appVersion: v,
          clock: () => clock,
          afterCheck: a.afterReviewCheck,
          settleDelay: Duration.zero,
        );

    test('review requested: no ask, for the rest of the session', () async {
      final a = askCtl();
      final p = _Prompter(true);
      final r = reviewCtl(p, a);
      expect(await r.runCheck(), ReviewCheck.requested);
      expect(await a.evaluate(ReviewCheck.requested), isFalse);
      expect(settings.get(kPromptLastShownAt), isNotNull,
          reason: 'the review stamps the shared date');
      // Even 30 days later in the same session, the ask stays away.
      clock = now.add(const Duration(days: 30));
      expect(await a.evaluate(ReviewCheck.notEligible), isFalse);
      expect(a.pending.value, isFalse);
    });

    test('review eligible but unavailable (store present): no ask', () async {
      final a = askCtl();
      final r = reviewCtl(_Prompter(false), a);
      expect(await r.runCheck(), ReviewCheck.unavailable);
      expect(await a.evaluate(ReviewCheck.unavailable), isFalse);
      expect(await a.evaluate(ReviewCheck.notEligible), isFalse);
    });

    test('no store at all (desktop): unavailable does not block', () async {
      final a = askCtl(reviewSupported: false);
      expect(await a.evaluate(ReviewCheck.unavailable), isTrue);
    });

    test('review not eligible: the ask fires once, then never this version',
        () async {
      // The review was already requested 20 days ago for this version.
      await store.markPrompted(now.subtract(const Duration(days: 20)), v);
      final a = askCtl();
      final r = reviewCtl(_Prompter(true), a);
      expect(await r.runCheck(), ReviewCheck.notEligible);
      expect(await a.evaluate(ReviewCheck.notEligible), isTrue);
      expect(a.pending.value, isTrue);
      await a.markShown(); // shown (and maybe dismissed)
      expect(a.pending.value, isFalse);
      expect(counter.askedVersion, v);
      expect(store.read().lastPromptShownAt, now);
      clock = now.add(const Duration(days: 90));
      expect(await a.evaluate(ReviewCheck.notEligible), isFalse);
    });

    test('after the ask, the review waits 14 days', () async {
      await store.markPrompted(now.subtract(const Duration(days: 70)), '1.0.0');
      final a = askCtl();
      await a.markShown();
      final p = _Prompter(true);
      final r = reviewCtl(p, a);
      expect(await r.runCheck(), ReviewCheck.notEligible);
      expect(p.calls, 0);
      clock = now.add(const Duration(days: 14));
      expect(await r.runCheck(), ReviewCheck.requested);
    });

    test('too few orders: no ask', () async {
      await store.markPrompted(now.subtract(const Duration(days: 20)), v);
      sales = 49;
      expect(await askCtl().evaluate(ReviewCheck.notEligible), isFalse);
    });

    test('restore merge keeps the latest shared prompt date', () async {
      final before = ReviewState(
          firstLaunchAt: now.subtract(const Duration(days: 45)),
          lastPromptShownAt: DateTime(2026, 11, 1));
      await settings.put(
          kPromptLastShownAt, DateTime(2026, 3, 1).toIso8601String());
      await store.mergeAfterRestore(before);
      expect(store.read().lastPromptShownAt, DateTime(2026, 11, 1));
      await store.mergeAfterRestore(
          ReviewState(lastPromptShownAt: DateTime(2026, 1, 1)));
      expect(store.read().lastPromptShownAt, DateTime(2026, 11, 1));
    });

    test('a skipped review check never leads to an ask', () async {
      await store.markPrompted(now.subtract(const Duration(days: 20)), v);
      expect(await askCtl().evaluate(ReviewCheck.skipped), isFalse);
    });

    test('onReceiptDismissed hands the review outcome to the ask', () async {
      await store.markPrompted(now.subtract(const Duration(days: 20)), v);
      final a = askCtl();
      final r = reviewCtl(_Prompter(true), a);
      r.onReceiptDismissed();
      for (var i = 0; i < 20 && !a.pending.value; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(a.pending.value, isTrue);
    });
  });
}
