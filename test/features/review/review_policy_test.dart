import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/review/domain/review_policy.dart';

void main() {
  final now = DateTime.utc(2026, 6, 1, 12);
  const v = '1.0.0+9';

  ReviewState passing({
    int installDaysAgo = 30,
    int? lastPromptDaysAgo,
    String? lastVersion,
  }) =>
      ReviewState(
        firstLaunchAt: now.subtract(Duration(days: installDaysAgo)),
        lastPromptAt: lastPromptDaysAgo == null
            ? null
            : now.subtract(Duration(days: lastPromptDaysAgo)),
        lastPromptVersion: lastVersion,
      );

  bool decide(ReviewState s, {String version = v, int sales = 25}) =>
      shouldRequestReview(s,
          completedSales: sales, now: now, currentVersion: version);

  test('all conditions met → request', () {
    expect(decide(passing()), isTrue);
  });

  test('install age: 6 days no, 7 days yes', () {
    expect(decide(passing(installDaysAgo: 6)), isFalse);
    expect(
        decide(ReviewState(
            firstLaunchAt:
                now.subtract(const Duration(days: 7, seconds: -1)))),
        isFalse,
        reason: 'one second short of 7 days');
    expect(decide(passing(installDaysAgo: 7)), isTrue);
  });

  test('sales: 19 no, 20 yes', () {
    expect(decide(passing(), sales: 19), isFalse);
    expect(decide(passing(), sales: 20), isTrue);
  });

  test('since last prompt: 59 days no, 60 days yes', () {
    expect(decide(passing(lastPromptDaysAgo: 59, lastVersion: '0.9.0')),
        isFalse);
    expect(decide(passing(lastPromptDaysAgo: 60, lastVersion: '0.9.0')),
        isTrue);
  });

  test('same version already prompted → no; new version → yes', () {
    expect(decide(passing(lastPromptDaysAgo: 400, lastVersion: v)), isFalse);
    expect(decide(passing(lastPromptDaysAgo: 400, lastVersion: v),
            version: '1.0.1+10'),
        isTrue);
  });

  test('unknown first launch or future-dated install → no', () {
    expect(decide(const ReviewState(), sales: 100), isFalse);
    expect(decide(passing(installDaysAgo: -3)), isFalse);
  });

  // ── Clock set backwards ────────────────────────────────────────────────

  group('device clock set backwards', () {
    bool at(DateTime t, ReviewState s) =>
        shouldRequestReview(s, completedSales: 25, now: t, currentVersion: v);

    test('now before first launch → no', () {
      final s = ReviewState(firstLaunchAt: now);
      expect(at(now.subtract(const Duration(days: 1)), s), isFalse);
      expect(at(now.subtract(const Duration(days: 400)), s), isFalse);
    });

    test('now before the last prompt → no, even on a new version', () {
      final s = ReviewState(
        firstLaunchAt: now.subtract(const Duration(days: 500)),
        lastPromptAt: now,
        lastPromptVersion: '0.9.0+1',
      );
      // Install is old enough and the version is new: only the prompt date,
      // now in the "future", holds it back.
      expect(at(now.subtract(const Duration(days: 1)), s), isFalse);
      expect(at(now.subtract(const Duration(days: 100)), s), isFalse);
    });

    test('once the clock is right again the normal rule applies', () {
      final s = ReviewState(
        firstLaunchAt: now.subtract(const Duration(days: 500)),
        lastPromptAt: now,
        lastPromptVersion: '0.9.0+1',
      );
      expect(at(now.add(const Duration(days: 59)), s), isFalse);
      expect(at(now.add(const Duration(days: 60)), s), isTrue);
    });
  });

  // ── Restored first-launch date in the future ───────────────────────────

  test('future first launch: no until real time passes it, then normal', () {
    final first = now.add(const Duration(days: 3));
    final s = ReviewState(firstLaunchAt: first);
    bool at(DateTime t) =>
        shouldRequestReview(s, completedSales: 25, now: t, currentVersion: v);

    expect(at(now), isFalse, reason: 'first launch is still ahead');
    expect(at(first), isFalse, reason: 'day 0');
    expect(at(first.add(const Duration(days: 6, hours: 23))), isFalse);
    expect(at(first.add(const Duration(days: 7))), isTrue,
        reason: 'the usual 7 days, counted from the restored date');
    expect(
        shouldRequestReview(s,
            completedSales: 19,
            now: first.add(const Duration(days: 7)),
            currentVersion: v),
        isFalse,
        reason: 'and the other rules still apply');
  });

  // ── Version ────────────────────────────────────────────────────────────

  group('last-prompt version', () {
    test('equal to the current version → never again for that version', () {
      for (final days in [60, 61, 365, 4000]) {
        expect(decide(passing(lastPromptDaysAgo: days, lastVersion: v)),
            isFalse,
            reason: '$days days after the prompt');
      }
    });

    test('different → allowed once 60 days have passed, not before', () {
      expect(decide(passing(lastPromptDaysAgo: 60, lastVersion: '1.0.0+8')),
          isTrue);
      expect(decide(passing(lastPromptDaysAgo: 10, lastVersion: '1.0.0+8')),
          isFalse);
    });

    test('the comparison is on the full name+build string', () {
      const current = '1.1.0+10';
      ReviewState prompted(String version) =>
          passing(lastPromptDaysAgo: 90, lastVersion: version);
      expect(decide(prompted('1.1.0+10'), version: current), isFalse);
      expect(decide(prompted('1.1.0+9'), version: current), isTrue,
          reason: 'same name, other build');
      expect(decide(prompted('1.1.0'), version: current), isTrue,
          reason: 'a bare name is not the same version');
      expect(decide(prompted(''), version: current), isTrue);
    });

    test('a version without a prompt date still blocks that version', () {
      final s = ReviewState(
          firstLaunchAt: now.subtract(const Duration(days: 30)),
          lastPromptVersion: v);
      expect(decide(s), isFalse);
    });
  });

  // ── Exactly at the thresholds ──────────────────────────────────────────

  group('exactly at threshold', () {
    const tick = Duration(microseconds: 1);

    test('7 days since first launch: to the microsecond', () {
      ReviewState installed(Duration ago) =>
          ReviewState(firstLaunchAt: now.subtract(ago));
      const seven = Duration(days: kReviewMinDaysSinceInstall);
      expect(decide(installed(seven - tick)), isFalse);
      expect(decide(installed(seven)), isTrue);
      expect(decide(installed(seven + tick)), isTrue);
    });

    test('20 sales', () {
      expect(decide(passing(), sales: kReviewMinCompletedSales - 1), isFalse);
      expect(decide(passing(), sales: kReviewMinCompletedSales), isTrue);
      expect(decide(passing(), sales: kReviewMinCompletedSales + 1), isTrue);
      expect(decide(passing(), sales: 0), isFalse);
    });

    test('60 days since the last prompt: to the microsecond', () {
      ReviewState prompted(Duration ago) => ReviewState(
            firstLaunchAt: now.subtract(const Duration(days: 365)),
            lastPromptAt: now.subtract(ago),
            lastPromptVersion: '1.0.0+8',
          );
      const sixty = Duration(days: kReviewMinDaysBetweenPrompts);
      expect(decide(prompted(sixty - tick)), isFalse);
      expect(decide(prompted(sixty)), isTrue);
      expect(decide(prompted(sixty + tick)), isTrue);
    });
  });
}
