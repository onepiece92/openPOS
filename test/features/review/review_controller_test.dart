import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/review/application/review_controller.dart';
import 'package:pos_app/features/review/data/review_state_store.dart';
import 'package:pos_app/features/review/domain/review_policy.dart';
import 'package:pos_app/features/review/domain/review_prompter.dart';

enum _Mode { ok, unavailable, throws, hangs }

class _FakePrompter implements ReviewPrompter {
  _FakePrompter(this.mode);
  final _Mode mode;
  int calls = 0;

  @override
  Future<bool> maybeRequestReview() {
    calls++;
    return switch (mode) {
      _Mode.ok => Future.value(true),
      _Mode.unavailable => Future.value(false),
      _Mode.throws => Future.error(StateError('Play services missing')),
      _Mode.hangs => Completer<bool>().future, // never completes
    };
  }

  @override
  Future<void> openStoreListing({required String appStoreId}) async {}
}

void main() {
  late Directory tmp;
  late Box<dynamic> box;
  late ReviewStateStore store;
  final now = DateTime(2026, 6, 1);
  // What the fake "database" reports, and how often it was asked.
  late int sales;
  late int salesQueries;
  const version = '1.0.0+9';

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_review_');
    Hive.init(tmp.path);
    box = await Hive.openBox<dynamic>('settings');
    store = ReviewStateStore(box);
    sales = 0;
    salesQueries = 0;
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  Future<void> eligible() async {
    await store.ensureFirstLaunch(now.subtract(const Duration(days: 10)));
    sales = kReviewMinCompletedSales;
  }

  ReviewController controller(_FakePrompter p,
          {Future<int> Function()? completedSales}) =>
      ReviewController(
        store: store,
        prompter: p,
        completedSales: completedSales ??
            () async {
              salesQueries++;
              return sales;
            },
        appVersion: version,
        clock: () => now,
        settleDelay: Duration.zero,
        timeout: const Duration(milliseconds: 50),
      );

  test('store: first launch kept', () async {
    await store.ensureFirstLaunch(now);
    await store.ensureFirstLaunch(now.add(const Duration(days: 5)));
    expect(store.read().firstLaunchAt, now);
  });

  test('sales come from the database count: 19 no, 20 yes', () async {
    await eligible();
    sales = kReviewMinCompletedSales - 1;
    final p = _FakePrompter(_Mode.ok);
    final c = controller(p);
    await c.runCheck();
    expect(p.calls, 0);
    sales = kReviewMinCompletedSales;
    await c.runCheck();
    expect(p.calls, 1);
    expect(salesQueries, 2);
  });

  test('a leftover counter key from the old scheme is ignored', () async {
    await eligible();
    sales = 0;
    await box.put('review_completed_sales', 500);
    final p = _FakePrompter(_Mode.ok);
    await controller(p).runCheck();
    expect(p.calls, 0);
  });

  test('database is not queried when dates or version already say no',
      () async {
    await store.ensureFirstLaunch(now); // installed today
    sales = 500;
    final p = _FakePrompter(_Mode.ok);
    await controller(p).runCheck();
    expect(salesQueries, 0);
    expect(p.calls, 0);
  });

  test('a throwing or hanging sales count is swallowed and bounded',
      () async {
    await eligible();
    final p = _FakePrompter(_Mode.ok);
    final throwing = controller(p,
        completedSales: () => Future.error(StateError('db closed')));
    await expectLater(throwing.runCheck(), completes);
    final hanging =
        controller(p, completedSales: () => Completer<int>().future);
    await hanging.runCheck().timeout(const Duration(seconds: 2));
    expect(p.calls, 0);
    expect(store.read().lastPromptAt, isNull);
    // Neither failure leaves the controller stuck "in flight".
    await throwing.runCheck();
    await hanging.runCheck();
    final ok = controller(p);
    await ok.runCheck();
    expect(p.calls, 1);
  });

  test('eligible + available → asks once and records date/version', () async {
    await eligible();
    final p = _FakePrompter(_Mode.ok);
    final c = controller(p);
    await c.runCheck();
    expect(p.calls, 1);
    expect(store.read().lastPromptAt, now);
    expect(store.read().lastPromptVersion, version);
    await c.runCheck(); // same version → no second ask
    expect(p.calls, 1);
  });

  test('not eligible → prompter never called', () async {
    await store.ensureFirstLaunch(now);
    final p = _FakePrompter(_Mode.ok);
    await controller(p).runCheck();
    expect(p.calls, 0);
  });

  test('unavailable (sideloaded / no Play) → silent, nothing recorded',
      () async {
    await eligible();
    final p = _FakePrompter(_Mode.unavailable);
    await controller(p).runCheck();
    expect(p.calls, 1);
    expect(store.read().lastPromptAt, isNull);
  });

  test('throwing prompter → swallowed, nothing recorded', () async {
    await eligible();
    final p = _FakePrompter(_Mode.throws);
    await expectLater(controller(p).runCheck(), completes);
    expect(store.read().lastPromptAt, isNull);
  });

  test('hanging prompter → bounded by timeout', () async {
    await eligible();
    final p = _FakePrompter(_Mode.hangs);
    final sw = Stopwatch()..start();
    await controller(p).runCheck().timeout(const Duration(seconds: 2));
    expect(sw.elapsed, lessThan(const Duration(seconds: 1)));
    expect(store.read().lastPromptVersion, version,
        reason: 'a timed-out request counts so we do not re-ask every sale');
  });

  test('receipt hook returns synchronously even if the prompter hangs',
      () async {
    await eligible();
    final c = controller(_FakePrompter(_Mode.hangs));
    final sw = Stopwatch()..start();
    c.onReceiptDismissed();
    expect(sw.elapsedMilliseconds, lessThan(20));
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });

  test('restore merge keeps earliest install and latest prompt',
      () async {
    final before = ReviewState(
      firstLaunchAt: DateTime(2026, 1, 1),
      lastPromptAt: DateTime(2026, 5, 1),
      lastPromptVersion: '1.0.0+9',
    );
    // Box now holds an older backup's values.
    await box.put(kReviewFirstLaunchAt, DateTime(2026, 2, 1).toIso8601String());
    await store.markPrompted(DateTime(2026, 3, 1), '1.0.0+8');
    await store.mergeAfterRestore(before);
    final s = store.read();
    expect(s.firstLaunchAt, DateTime(2026, 1, 1));
    expect(s.lastPromptAt, DateTime(2026, 5, 1));
    expect(s.lastPromptVersion, '1.0.0+9');
  });
}
