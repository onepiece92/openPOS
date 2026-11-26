import 'dart:convert';

import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/onboarding/domain/business_type.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/domain/usage_summary.dart';
import 'package:pos_app/features/usage/usage_constants.dart';

import '_grammar.dart';

const env = UsageEnvironment(
  appVersion: '1.1.0+10',
  platform: 'android',
  osMajorVersion: null,
  locale: 'en-US',
  currencyCode: 'USD',
);
const shop = ShopSizeCounts(products: 120, ordersLast7Days: 37, customers: 4);
final counts = {
  UsageEvent.saleCompleted:
      const UsageCount(412, firstMonth: '2026-09', lastMonth: '2026-11'),
  UsageEvent.discountApplied:
      const UsageCount(9, firstMonth: '2026-11', lastMonth: '2026-11'),
  UsageEvent.reportViewed:
      const UsageCount(23, firstMonth: '2026-10', lastMonth: '2026-11'),
};

String build(UsageSelection s, {String message = ''}) => buildUsageSummary(
    selection: s, message: message, counts: counts, env: env, shop: shop);

void main() {
  group('FeatureArea / UsageEvent', () {
    test('every event has exactly one area, and every area has events', () {
      for (final e in UsageEvent.values) {
        expect(FeatureArea.values, contains(e.area), reason: e.name);
        expect(FeatureArea.values.where((a) => UsageEvent.of(a).contains(e)),
            hasLength(1));
      }
      for (final a in FeatureArea.values) {
        expect(UsageEvent.of(a), isNotEmpty, reason: a.name);
      }
    });

    test('UI labels', () {
      expect(FeatureArea.values.map((a) => a.label), [
        'Selling',
        'Receipts & printing',
        'Products & stock',
        'Customers & loyalty',
        'Reports',
        'Expenses',
        'Backup',
        'Import/export',
        'Other',
      ]);
    });

    test('routes map to screen events; uncounted routes give null', () {
      expect(usageEventForRoute('/pos'), UsageEvent.screenSell);
      expect(usageEventForRoute('/reports'), UsageEvent.reportViewed);
      expect(usageEventForRoute('/products/:id'), UsageEvent.screenProductForm);
      expect(usageEventForRoute('/onboarding'), isNull);
      expect(usageEventForRoute('/help/feedback'), isNull);
      expect(usageEventForRoute(null), isNull);
    });
  });

  group('buckets and OS version', () {
    test('shop-size ranges', () {
      expect([0, 1, 10, 11, 50, 51, 200, 201, 99999].map(sizeBucket), [
        '0',
        '1-10',
        '1-10',
        '11-50',
        '11-50',
        '51-200',
        '51-200',
        '200+',
        '200+'
      ]);
    });

    test('OS major version is parsed conservatively', () {
      expect(parseOsMajorVersion('Version 17.2 (Build 21C62)'), 17);
      expect(parseOsMajorVersion('Version 14.1.1 (Build 23B81)'), 14);
      // Android reports the Linux kernel here, not the Android version.
      expect(parseOsMajorVersion('Linux 5.10.157-android13-4-00001 #1 SMP'),
          isNull);
      expect(
          parseOsMajorVersion('"Windows 10 Pro" 10.0 (Build 19045)'), isNull);
      expect(parseOsMajorVersion(''), isNull);
    });
  });

  group('selection', () {
    test('picking an area pre-ticks its counters; un-picking unticks', () {
      var s = const UsageSelection();
      expect(s.hasData, isFalse);
      s = s.togglePicked(FeatureArea.reports);
      expect(s.picked, {FeatureArea.reports});
      expect(s.tickedAreas, {FeatureArea.reports});
      expect(s.appInfo, isFalse);
      expect(s.shopSize, isFalse);
      s = s.toggleArea(FeatureArea.reports); // user unticks the group
      expect(s.picked, {FeatureArea.reports});
      expect(s.tickedAreas, isEmpty);
      expect(s.hasData, isFalse);
      s = s.toggleArea(FeatureArea.selling).withAppInfo(true);
      expect(s.tickedAreas, {FeatureArea.selling});
      expect(s.hasData, isTrue);
      s = s.togglePicked(FeatureArea.selling).togglePicked(FeatureArea.selling);
      expect(s.picked, {FeatureArea.reports});
      expect(s.tickedAreas, isEmpty);
    });

    test('nothing that is not ticked is sent', () {
      final s = const UsageSelection().togglePicked(FeatureArea.reports);
      final out = build(s);
      expect(out, contains('reportViewed: 23'));
      expect(out, isNot(contains('saleCompleted')));
      expect(out, isNot(contains('App:')));
      expect(out, isNot(contains('Shop size:')));
    });

    test('Send needs a message or ticked data', () {
      const none = UsageSelection();
      expect(canSendUsageSummary(none, ''), isFalse);
      expect(canSendUsageSummary(none, '   \n '), isFalse);
      expect(canSendUsageSummary(none, 'Need tips'), isTrue);
      expect(canSendUsageSummary(none.withShopSize(true), ''), isTrue);
      // Picked but every group unticked, no message: nothing to send.
      final picked =
          none.togglePicked(FeatureArea.backup).toggleArea(FeatureArea.backup);
      expect(canSendUsageSummary(picked, ''), isFalse);
    });
  });

  group('buildUsageSummary', () {
    test('the full sample (also the documented example)', () {
      final s = const UsageSelection()
          .togglePicked(FeatureArea.selling)
          .togglePicked(FeatureArea.reports)
          .withAppInfo(true)
          .withShopSize(true);
      final out = build(s, message: 'Please add split payments.');
      expect(out, '''
Open POS feedback and usage summary
Improve: Selling, Reports
Selling usage:
- screenSell: 0
- screenPayment: 0
- screenOrders: 0
- screenOrderDetail: 0
- screenTables: 0
- saleCompleted: 412 (2026-09 to 2026-11)
- refundIssued: 0
- orderVoided: 0
- ticketHeld: 0
- discountApplied: 9 (2026-11)
- productSearched: 0
Reports usage:
- reportViewed: 23 (2026-10 to 2026-11)
App: Open POS 1.1.0+10, android, OS unknown, locale en-US, currency USD
Shop size: products 51-200, orders in last 7 days 11-50, customers 1-10
Message:
Please add split payments.''');
      expectGrammar(out);
    });

    test('pure feedback: a message and no data', () {
      final out = build(const UsageSelection(), message: '  Love it  ');
      expect(out, '$kUsageSummaryHeader\nMessage:\nLove it');
      expectGrammar(out);
    });

    test('data and no message: no message section', () {
      final out = build(const UsageSelection().withShopSize(true));
      expect(out, isNot(contains(kUsageMessageMarker)));
      expect(splitSummary(out).message, isNull);
      expectGrammar(out);
    });

    test('every group ticked: every line is in the grammar', () {
      var s = const UsageSelection().withAppInfo(true).withShopSize(true);
      for (final a in FeatureArea.values) {
        s = s.togglePicked(a);
      }
      expectGrammar(build(s));
    });

    test('the message is capped at $kFeedbackMessageMaxLength characters', () {
      final long = 'x' * (kFeedbackMessageMaxLength + 50);
      final msg =
          splitSummary(build(const UsageSelection(), message: long)).message!;
      expect(msg.length, kFeedbackMessageMaxLength);
      expect(normalizeFeedbackMessage(long).length, kFeedbackMessageMaxLength);
    });

    for (final (label, unit) in [
      ('an emoji', '\u{1F600}'),
      ('a ZWJ family', '\u{1F468}\u200D\u{1F469}\u200D\u{1F467}'),
      ('a flag', '\u{1F1FA}\u{1F1F8}'),
      ('a skin-tone emoji', '\u{1F44D}\u{1F3FD}'),
    ]) {
      test('the cap never splits $label at the boundary', () {
        // 499 letters, then the cluster as character 500 and 501.
        final msg = '${'a' * 499}$unit$unit';
        final cut = normalizeFeedbackMessage(msg);
        expect(cut.characters.length, kFeedbackMessageMaxLength);
        expect(cut, '${'a' * 499}$unit');
        // Well-formed UTF-16 (no lone surrogate): round-trips through UTF-8.
        expect(utf8.decode(utf8.encode(cut)), cut);
        expect(cut, isNot(contains('\uFFFD')));
        // And all clusters: 500 of them, each kept whole.
        final all = normalizeFeedbackMessage(unit * 600);
        expect(all.characters.length, kFeedbackMessageMaxLength);
        expect(all, unit * kFeedbackMessageMaxLength);
        final out = build(const UsageSelection(), message: all);
        expect(splitSummary(out).message, all);
      });
    }

    test('unexpected environment values are replaced, never passed on', () {
      final out = buildUsageSummary(
        selection: const UsageSelection().withAppInfo(true),
        message: '',
        counts: const {},
        env: const UsageEnvironment(
          appVersion: '1.1.0 My Shop',
          platform: 'Android Pixel of Jane',
          osMajorVersion: 123456,
          locale: 'en-US-x-jane-smith-home',
          currencyCode: r'Rs$',
        ),
        shop: null,
      );
      expect(out.split('\n').last,
          'App: Open POS unknown, other, OS unknown, locale unknown, currency other');
      expectGrammar(out);
    });

    test('malformed stored months are dropped', () {
      final out = buildUsageSummary(
        selection: const UsageSelection().toggleArea(FeatureArea.expenses),
        message: '',
        counts: {
          UsageEvent.expenseAdded:
              const UsageCount(3, firstMonth: 'Jane', lastMonth: '2026-11'),
        },
        env: env,
        shop: null,
      );
      expect(out, endsWith('\n- expenseAdded: 3'));
      expectGrammar(out);
    });

    test('typed sentinels appear only inside the message section', () {
      const sentinel = 'ZQX-SENTINEL-Jane-Smith-+1-555-0100';
      final s = const UsageSelection()
          .togglePicked(FeatureArea.selling)
          .withAppInfo(true)
          .withShopSize(true);
      final without = build(s);
      expect(without, isNot(contains('ZQX')));
      final withMsg = build(s, message: 'Call me: $sentinel\nMessage:\nApp: x');
      final parts = splitSummary(withMsg);
      expect(parts.fixed.join('\n'), isNot(contains('ZQX')));
      expect(parts.message, contains(sentinel));
      // A typed "Message:" line cannot move the boundary: the fixed part is
      // exactly the no-message text.
      expect(parts.fixed.join('\n'), without);
      expectGrammar(withMsg);
    });
  });

  group('business type line', () {
    String withType(UsageSelection s, BusinessType? t) => buildUsageSummary(
        selection: s,
        message: '',
        counts: counts,
        env: env,
        shop: shop,
        businessType: t);

    test('absent unless ticked', () {
      final s = const UsageSelection().withShopSize(true);
      expect(withType(s, BusinessType.cafe), isNot(contains('Business type')));
      expect(withType(s.withBusinessType(true), BusinessType.cafe),
          endsWith('Shop size: products 51-200, orders in last 7 days 11-50, '
              'customers 1-10\nBusiness type: cafe or counter'));
    });

    test('absent when no type is stored', () {
      final s = const UsageSelection().withBusinessType(true);
      expect(withType(s, null), isNot(contains('Business type')));
      expect(s.hasData, isTrue);
    });

    test('every label passes the grammar', () {
      final s = const UsageSelection().withBusinessType(true);
      for (final t in BusinessType.values) {
        final text = withType(s, t);
        expect(text, contains('Business type: ${t.usageLabel}'));
        expectGrammar(text);
      }
    });

    test('the fixed lowercase labels', () {
      expect([for (final t in BusinessType.values) t.usageLabel], [
        'food truck or stand',
        'cafe or counter',
        'restaurant with tables',
        'retail shop',
        'market stall or craft seller',
        'services',
        'something else',
      ]);
    });

    test('a corrupted stored value gives no type, so no line', () {
      for (final raw in ['', 'Cafe', 'cafe ', 'bar', 42, null, ['cafe']]) {
        expect(parseBusinessType(raw), isNull, reason: '$raw');
      }
      expect(parseBusinessType('cafe'), BusinessType.cafe);
    });
  });
}
