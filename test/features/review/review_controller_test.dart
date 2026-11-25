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
  const version = '1.0.0+9';

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_review_');
    Hive.init(tmp.path);
    box = await Hive.openBox<dynamic>('settings');
    store = ReviewStateStore(box);
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  Future<void> eligible() async {
    await store.ensureFirstLaunch(now.subtract(const Duration(days: 10)));
    await box.put(kReviewCompletedSales, kReviewMinCompletedSales);
  }

  ReviewController controller(_FakePrompter p) => ReviewController(
        store: store,
        prompter: p,
        appVersion: version,
        clock: () => now,
        settleDelay: Duration.zero,
        timeout: const Duration(milliseconds: 50),
      );

  test('store: first launch kept, sales counted', () async {
    await store.ensureFirstLaunch(now);
    await store.ensureFirstLaunch(now.add(const Duration(days: 5)));
    expect(store.read().firstLaunchAt, now);
    await store.incrementCompletedSales();
    await store.incrementCompletedSales();
    expect(store.read().completedSales, 2);
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

  test('receipt hooks return synchronously even if the prompter hangs',
      () async {
    await eligible();
    final c = controller(_FakePrompter(_Mode.hangs));
    final sw = Stopwatch()..start();
    c.recordCompletedSale();
    c.onReceiptDismissed();
    expect(sw.elapsedMilliseconds, lessThan(20));
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });

  test('restore merge keeps earliest install, latest prompt, higher count',
      () async {
    final before = ReviewState(
      firstLaunchAt: DateTime(2026, 1, 1),
      completedSales: 40,
      lastPromptAt: DateTime(2026, 5, 1),
      lastPromptVersion: '1.0.0+9',
    );
    // Box now holds an older backup's values.
    await box.put(kReviewFirstLaunchAt, DateTime(2026, 2, 1).toIso8601String());
    await box.put(kReviewCompletedSales, 10);
    await store.markPrompted(DateTime(2026, 3, 1), '1.0.0+8');
    await store.mergeAfterRestore(before);
    final s = store.read();
    expect(s.firstLaunchAt, DateTime(2026, 1, 1));
    expect(s.completedSales, 40);
    expect(s.lastPromptAt, DateTime(2026, 5, 1));
    expect(s.lastPromptVersion, '1.0.0+9');
  });
}
