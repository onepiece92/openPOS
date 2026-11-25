import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/review/domain/review_policy.dart';

void main() {
  final now = DateTime.utc(2026, 6, 1, 12);
  const v = '1.0.0+9';

  ReviewState passing({
    int installDaysAgo = 30,
    int sales = 25,
    int? lastPromptDaysAgo,
    String? lastVersion,
  }) =>
      ReviewState(
        firstLaunchAt: now.subtract(Duration(days: installDaysAgo)),
        completedSales: sales,
        lastPromptAt: lastPromptDaysAgo == null
            ? null
            : now.subtract(Duration(days: lastPromptDaysAgo)),
        lastPromptVersion: lastVersion,
      );

  bool decide(ReviewState s, {String version = v}) =>
      shouldRequestReview(s, now: now, currentVersion: version);

  test('all conditions met → request', () {
    expect(decide(passing()), isTrue);
  });

  test('install age: 6 days no, 7 days yes', () {
    expect(decide(passing(installDaysAgo: 6)), isFalse);
    expect(
        decide(ReviewState(
            firstLaunchAt: now.subtract(const Duration(days: 7, seconds: -1)),
            completedSales: 25)),
        isFalse,
        reason: 'one second short of 7 days');
    expect(decide(passing(installDaysAgo: 7)), isTrue);
  });

  test('sales: 19 no, 20 yes', () {
    expect(decide(passing(sales: 19)), isFalse);
    expect(decide(passing(sales: 20)), isTrue);
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
    expect(decide(const ReviewState(completedSales: 100)), isFalse);
    expect(decide(passing(installDaysAgo: -3)), isFalse);
  });
}
