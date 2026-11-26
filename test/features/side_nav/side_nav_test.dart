import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/shifts/shift_settings.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

import '../../_support/temp_hive.dart';

/// The Close day item and its routes, on the feature-switch drawer.
void main() {
  late Box<dynamic> box;
  setUp(() async => box = await openTempSettingsBox());

  FeatureFlags flags({required bool eod}) =>
      FeatureFlags.defaults().withStored(Feature.endOfDay, eod);

  Future<(GoRouter, ProviderContainer)> pump(WidgetTester tester,
      {required bool eod}) async {
    await box.put(kFeaturesKey, flags(eod: eod).toStored());
    await box.put(kFeaturesIntroSeen, true);
    final container = ProviderContainer(
        overrides: [settingsBoxProvider.overrideWithValue(box)]);
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/pos',
      redirect: (_, state) => featureRedirect(
          container.read(featureFlagsProvider), state.matchedLocation),
      routes: [
        for (final e in kNavEntries)
          GoRoute(
            path: e.route,
            builder: (_, __) => Scaffold(
              drawer: const PosDrawer(),
              body: Text('page:${e.route}'),
            ),
            routes: e.route == kCloseDayRoute
                ? [
                    GoRoute(
                      path: 'history',
                      builder: (_, __) =>
                          const Scaffold(body: Text('page:history')),
                      routes: [
                        GoRoute(
                          path: ':id',
                          builder: (_, __) =>
                              const Scaffold(body: Text('page:detail')),
                        ),
                      ],
                    ),
                  ]
                : const [],
          ),
      ],
    );
    addTearDown(router.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    return (router, container);
  }

  Future<void> openDrawer(WidgetTester tester) async {
    tester.firstState<ScaffoldState>(find.byType(Scaffold).last).openDrawer();
    await tester.pumpAndSettle();
  }

  test('Close day sits in the Sell group, after Tables, gated by its feature',
      () {
    final sell = [
      for (final e in kNavEntries)
        if (e.group == 'Sell') e
    ];
    expect(sell.map((e) => e.label),
        ['POS', 'Orders', 'Customers', 'Tables', 'Close day']);
    expect(sell.last.route, kCloseDayRoute);
    expect(sell.last.feature, Feature.endOfDay);
    expect(visibleNavEntries(flags(eod: false)).map((e) => e.route),
        isNot(contains(kCloseDayRoute)));
    expect(visibleNavEntries(flags(eod: true)).map((e) => e.route),
        contains(kCloseDayRoute));
  });

  testWidgets('feature on: Close day opens /close-day', (tester) async {
    await pump(tester, eod: true);
    await openDrawer(tester);
    final item = find.byKey(const ValueKey('nav-$kCloseDayRoute'));
    await tester.ensureVisible(item);
    await tester.tap(item);
    await tester.pumpAndSettle();
    expect(find.text('page:$kCloseDayRoute'), findsOneWidget);
  });

  testWidgets('feature off: the item is hidden', (tester) async {
    await pump(tester, eod: false);
    await openDrawer(tester);
    expect(find.text('Close day'), findsNothing);
  });

  testWidgets('feature off: close-day routes redirect to /pos', (tester) async {
    final (router, _) = await pump(tester, eod: false);
    for (final path in [
      '/close-day',
      '/close-day/history',
      '/close-day/history/3'
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.text('page:/pos'), findsOneWidget, reason: path);
    }
  });

  testWidgets('feature on: close-day routes stay', (tester) async {
    final (router, _) = await pump(tester, eod: true);
    router.go('/close-day/history/3');
    await tester.pumpAndSettle();
    expect(find.text('page:detail'), findsOneWidget);
  });

  test('the redirect rule', () {
    final off = flags(eod: false);
    final on = flags(eod: true);
    expect(featureRedirect(off, '/close-day'), '/pos');
    expect(featureRedirect(off, '/close-day/history/2'), '/pos');
    expect(featureRedirect(on, '/close-day'), isNull);
    expect(featureRedirect(off, '/closed-form'), isNull);
    expect(featureRedirect(off, '/orders'), isNull);
  });

  test('the gate defaults to off and follows the Features switch live',
      () async {
    final c = ProviderContainer(
        overrides: [settingsBoxProvider.overrideWithValue(box)]);
    addTearDown(c.dispose);
    final seen = <bool>[];
    c.listen(endOfDayEnabledProvider, (_, v) => seen.add(v));
    expect(c.read(endOfDayEnabledProvider), isFalse);
    final n = c.read(settingsProvider.notifier);
    await n.setFeature(Feature.endOfDay, true);
    expect(c.read(endOfDayEnabledProvider), isTrue);
    await n.setFeature(Feature.endOfDay, false);
    expect(c.read(endOfDayEnabledProvider), isFalse);
    expect(seen, [true, false]);
  });

  test('the never-shipped end_of_day_enabled key does nothing', () async {
    await box.put('end_of_day_enabled', true);
    final c = ProviderContainer(
        overrides: [settingsBoxProvider.overrideWithValue(box)]);
    addTearDown(c.dispose);
    expect(c.read(endOfDayEnabledProvider), isFalse);
  });

  test('Features row text', () {
    expect(Feature.endOfDay.label, 'End-of-day close');
    expect(Feature.endOfDay.description,
        'Count the cash drawer and close the day with a printed summary.');
    expect(Feature.endOfDay.defaultOn, isFalse);
    expect(Feature.endOfDay.parent, isNull);
  });
}
