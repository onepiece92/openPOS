import 'dart:io';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/domain/usage_summary.dart';
import 'package:pos_app/features/usage/usage_constants.dart';

void main() {
  late Directory tmp;
  late Box<dynamic> box;
  var now = DateTime(2026, 11, 20);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_usage_');
    Hive.init(tmp.path);
    box = await Hive.openBox<dynamic>(kUsageBoxName);
    now = DateTime(2026, 11, 20);
  });
  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  UsageCounter counter({Duration delay = const Duration(milliseconds: 80)}) =>
      UsageCounter(
          openBox: () async => box, clock: () => now, flushDelay: delay);

  Map<UsageEvent, UsageCount> stored() => readUsageCounts(box);

  test('defaults: 30 s flush, counting on (kUsageCountingDefaultOn)', () {
    expect(UsageCounter().flushDelay, const Duration(seconds: 30));
    expect(kUsageCountingDefaultOn, isTrue);
    expect(kUsageFirstRunDisclosure, isTrue);
    expect(UsageCounter().countingEnabled, kUsageCountingDefaultOn);
  });

  test('record is in memory; one debounced write after the delay', () async {
    final c = counter();
    await c.ensureLoaded();
    c.record(UsageEvent.saleCompleted);
    c.record(UsageEvent.saleCompleted);
    c.record(UsageEvent.ticketHeld);
    expect(c.counts[UsageEvent.saleCompleted]!.count, 2);
    expect(stored(), isEmpty, reason: 'nothing written synchronously');
    expect(c.flushScheduled, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    c.record(UsageEvent.saleCompleted); // same window: no second timer
    expect(stored(), isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(stored()[UsageEvent.saleCompleted]!.count, 3);
    expect(stored()[UsageEvent.ticketHeld]!.count, 1);
    expect(c.flushScheduled, isFalse);
  });

  test('paused and detached flush at once; other states do not', () async {
    final c = counter(delay: const Duration(hours: 1));
    await c.ensureLoaded();
    c.record(UsageEvent.refundIssued);
    c.onLifecycle(AppLifecycleState.inactive);
    await pumpEventQueue();
    expect(stored(), isEmpty);
    c.onLifecycle(AppLifecycleState.paused);
    await pumpEventQueue();
    expect(stored()[UsageEvent.refundIssued]!.count, 1);
    expect(c.flushScheduled, isFalse);
    c.record(UsageEvent.refundIssued);
    c.onLifecycle(AppLifecycleState.detached);
    await pumpEventQueue();
    expect(stored()[UsageEvent.refundIssued]!.count, 2);
  });

  test('counts before the box opens are buffered and added on load', () async {
    await box.put('e.saleCompleted', {'c': 5, 'f': '2026-08', 'l': '2026-10'});
    final c = counter();
    c.record(UsageEvent.saleCompleted);
    c.record(UsageEvent.csvExported);
    expect(c.isLoaded, isFalse);
    expect(c.flushScheduled, isFalse, reason: 'no timer before load');
    await c.ensureLoaded();
    expect(c.counts[UsageEvent.saleCompleted],
        const UsageCount(6, firstMonth: '2026-08', lastMonth: '2026-11'));
    await c.flush();
    expect(stored()[UsageEvent.csvExported]!.count, 1);
  });

  test('"Stop counting" is honoured by the very next record', () async {
    final c = counter();
    await c.ensureLoaded();
    c.record(UsageEvent.expenseAdded);
    c.countingEnabled = false; // the Usage counting switch, via the provider
    expect(box.containsKey(kUsageCountingOnKey), isFalse,
        reason: 'the switch lives in the settings box, not here');
    c.record(UsageEvent.expenseAdded);
    c.record(UsageEvent.backupCreated);
    expect(c.counts[UsageEvent.expenseAdded]!.count, 1);
    expect(c.counts[UsageEvent.backupCreated], isNull);
    c.countingEnabled = true;
    c.record(UsageEvent.backupCreated);
    expect(c.counts[UsageEvent.backupCreated]!.count, 1);
  });

  test('a carried "off" (older install, restore merge) turns the switch '
      'off, drops counts buffered before the load, and is deleted', () async {
    await box.put(kUsageCountingOnKey, false);
    final applied = <bool>[];
    final c = UsageCounter(
        openBox: () async => box,
        clock: () => now,
        onCarriedCountingChoice: (v) async => applied.add(v));
    c.record(UsageEvent.saleCompleted);
    await c.ensureLoaded();
    expect(applied, [false]);
    expect(c.countingEnabled, isFalse);
    expect(c.counts, isEmpty);
    expect(box.containsKey(kUsageCountingOnKey), isFalse);
    await c.flush();
    expect(stored(), isEmpty);
  });

  test('a carried "on" turns the switch back on', () async {
    await box.put(kUsageCountingOnKey, true);
    final applied = <bool>[];
    final c = UsageCounter(
        openBox: () async => box,
        countingOn: false,
        onCarriedCountingChoice: (v) async => applied.add(v));
    await c.ensureLoaded();
    expect(applied, [true]);
    expect(c.countingEnabled, isTrue);
    expect(box.containsKey(kUsageCountingOnKey), isFalse);
  });

  test('switch off from the start: nothing is counted', () async {
    final c = UsageCounter(openBox: () async => box, countingOn: false);
    c.record(UsageEvent.saleCompleted);
    await c.ensureLoaded();
    c.record(UsageEvent.saleCompleted);
    expect(c.counts, isEmpty);
  });

  test('months: first and last month are tracked, even if the clock goes back',
      () async {
    final c = counter();
    await c.ensureLoaded();
    now = DateTime(2026, 9, 3);
    c.record(UsageEvent.reportViewed);
    now = DateTime(2026, 11, 30);
    c.record(UsageEvent.reportViewed);
    now = DateTime(2026, 7, 1); // clock set back
    c.record(UsageEvent.reportViewed);
    now = DateTime(2026, 10, 1);
    c.record(UsageEvent.reportViewed);
    expect(c.counts[UsageEvent.reportViewed],
        const UsageCount(4, firstMonth: '2026-07', lastMonth: '2026-11'));
    await c.flush();
    expect(box.get('e.reportViewed'), {'c': 4, 'f': '2026-07', 'l': '2026-11'});
  });

  test('reset deletes every counter and keeps the flags', () async {
    final c = counter();
    await c.ensureLoaded();
    await c.markDisclosureShown();
    c.record(UsageEvent.saleCompleted);
    await c.flush();
    await c.reset();
    expect(c.counts, isEmpty);
    expect(stored(), isEmpty);
    expect(c.disclosureShown, isTrue);
  });

  test('only enum keys can be stored', () async {
    final c = counter();
    await c.ensureLoaded();
    for (final e in UsageEvent.values) {
      c.record(e);
    }
    await c.markDisclosureShown();
    await c.markAsked('1.1.0+10');
    await c.flush();
    final allowed = {
      for (final e in UsageEvent.values) 'e.${e.name}',
      kUsageCountingOnKey,
      kUsageDisclosureShownKey,
      kUsageAskedVersionKey,
      kUsageReviewUnavailableSinceKey,
    };
    expect(box.keys.toSet().difference(allowed), isEmpty);
  });

  test('route notifications: one count per screen change', () async {
    final c = counter();
    await c.ensureLoaded();
    c.recordRoute('/orders/:id', location: '/orders/1');
    c.recordRoute('/orders/:id', location: '/orders/2'); // another order
    c.recordRoute('/orders/:id', location: '/orders/2'); // same, again
    expect(c.counts[UsageEvent.screenOrderDetail]!.count, 2);
    c.recordRoute('/pos');
    c.recordRoute('/pos'); // the same location notifying again
    c.recordRoute('/payment');
    c.recordRoute('/receipt/:orderId');
    c.recordRoute('/pos');
    c.recordRoute('/onboarding'); // not counted
    expect(c.counts[UsageEvent.screenSell]!.count, 2);
    expect(c.counts[UsageEvent.screenPayment]!.count, 1);
    expect(c.counts[UsageEvent.screenReceipt]!.count, 1);
  });

  test('no box: the saved flag is unknown, so nothing is counted', () async {
    await Hive.close();
    final c = UsageCounter();
    c.record(UsageEvent.saleCompleted); // buffered while the box opens
    await c.ensureLoaded(); // …which fails
    expect(c.isLoaded, isFalse);
    expect(c.counts, isEmpty, reason: 'the buffer is dropped');
    c.record(UsageEvent.saleCompleted);
    expect(c.counts, isEmpty, reason: 'not counting until the flag is known');
    await c.flush();
    expect(c.flushScheduled, isFalse);
    c.dispose();
    c.record(UsageEvent.saleCompleted); // after dispose: ignored
  });

  test('a later successful load counts again', () async {
    var fail = true;
    final c = UsageCounter(
        openBox: () async => fail ? throw StateError('locked') : box);
    await c.ensureLoaded();
    c.record(UsageEvent.ticketHeld);
    expect(c.counts, isEmpty);
    fail = false;
    await c.ensureLoaded();
    c.record(UsageEvent.ticketHeld);
    expect(c.counts[UsageEvent.ticketHeld]!.count, 1);
    c.dispose();
  });

  test('perf: per-record cost', () async {
    final c = counter(delay: const Duration(hours: 1));
    await c.ensureLoaded();
    final sw = Stopwatch()..start();
    const n = 100000;
    for (var i = 0; i < n; i++) {
      c.record(UsageEvent.values[i % UsageEvent.values.length]);
    }
    sw.stop();
    final perCallUs = sw.elapsedMicroseconds / n;
    // ignore: avoid_print
    print('usage perf: ${perCallUs.toStringAsFixed(3)} us per record, '
        '${c.counts.length} counters in memory');
    expect(perCallUs, lessThan(50));
    expect(c.counts.length, lessThanOrEqualTo(UsageEvent.values.length));
    await c.flush();
    await box.close();
    final open = Stopwatch()..start();
    box = await Hive.openBox<dynamic>(kUsageBoxName);
    open.stop();
    // ignore: avoid_print
    print('usage perf: full box (${box.length} keys, '
        '${File(box.path!).lengthSync()} bytes) opened in '
        '${open.elapsedMicroseconds} us');
    expect(readUsageCounts(box).length, UsageEvent.values.length);
  });
}
