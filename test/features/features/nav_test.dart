import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

import '../../_support/temp_hive.dart';

void main() {
  late Box<dynamic> box;
  setUp(() async => box = await openTempSettingsBox());

  /// Every nav route as a stub page with the real drawer, behind the same
  /// feature redirect the app router uses.
  Future<(GoRouter, ProviderContainer)> pump(
      WidgetTester tester, FeatureFlags flags) async {
    await box.put(kFeaturesKey, flags.toStored());
    await box.put(kLoyaltyEnabled, flags.stored(Feature.loyalty));
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
              key: ValueKey('page-${e.route}'),
              drawer: const PosDrawer(),
              appBar: AppBar(title: Text('page ${e.route}')),
            ),
          ),
      ],
    );
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    return (router, container);
  }

  String location(GoRouter r) =>
      r.routerDelegate.currentConfiguration.uri.path;

  Future<void> openDrawer(WidgetTester tester) async {
    final scaffold =
        tester.firstState<ScaffoldState>(find.byType(Scaffold).last);
    scaffold.openDrawer();
    await tester.pumpAndSettle();
  }

  final cases = <String, FeatureFlags>{
    'everything on': FeatureFlags.only(Feature.values.toSet()),
    'everything off': FeatureFlags.only(const {}),
    'customers and tables off': FeatureFlags.only(Feature.values.toSet()
        .difference({Feature.customers, Feature.heldTickets})),
    'only stock and taxes off': FeatureFlags.only(Feature.values.toSet()
        .difference({Feature.stockTracking, Feature.taxes})),
  };

  for (final MapEntry(key: name, value: flags) in cases.entries) {
    testWidgets('$name: each visible item opens its own route',
        (tester) async {
      final (router, _) = await pump(tester, flags);
      final visible = visibleNavEntries(flags);
      for (final e in kNavEntries) {
        await openDrawer(tester);
        final item = find.byKey(ValueKey('nav-${e.route}'));
        if (!visible.contains(e)) {
          expect(item, findsNothing, reason: '${e.label} should be hidden');
          Navigator.of(tester.element(find.byType(NavigationDrawer))).pop();
          await tester.pumpAndSettle();
          continue;
        }
        await tester.ensureVisible(item);
        await tester.tap(item);
        await tester.pumpAndSettle();
        expect(location(router), e.route, reason: 'tapped ${e.label}');
      }
    });
  }

  testWidgets('Features is the first System item, above Settings',
      (tester) async {
    final system = [
      for (final e in kNavEntries)
        if (e.group == 'System') e.route
    ];
    expect(system.take(2), ['/features', '/settings']);
  });

  test('the redirect sends switched-off routes to /pos', () {
    final off = FeatureFlags.only(const {});
    for (final r in ['/customers', '/tables', '/inventory', '/expenses',
      '/tax']) {
      expect(featureRedirect(off, r), '/pos', reason: r);
    }
    for (final r in ['/pos', '/orders', '/orders/3', '/products', '/reports',
      '/settings', '/settings/backup', '/features', '/taxes-not-a-route']) {
      expect(featureRedirect(off, r), isNull, reason: r);
    }
    final on = FeatureFlags.only(Feature.values.toSet());
    expect(featureRedirect(on, '/customers'), isNull);
    // Tables needs Held tickets.
    expect(
        featureRedirect(
            on.withStored(Feature.heldTickets, false), '/tables'),
        '/pos');
  });

  testWidgets('switching a feature off on its screen sends you to /pos',
      (tester) async {
    final (router, container) =
        await pump(tester, FeatureFlags.only(Feature.values.toSet()));
    router.go('/customers');
    await tester.pumpAndSettle();
    expect(location(router), '/customers');
    await container
        .read(settingsProvider.notifier)
        .setFeature(Feature.customers, false);
    router.refresh(); // the app router pings this on every flag change
    await tester.pumpAndSettle();
    expect(location(router), '/pos');
  });

  testWidgets('the selected item follows sub-routes', (tester) async {
    expect(selectedNavIndex(kNavEntries, '/settings/backup'),
        kNavEntries.indexWhere((e) => e.route == '/settings'));
    expect(selectedNavIndex(kNavEntries, '/orders/12'),
        kNavEntries.indexWhere((e) => e.route == '/orders'));
    expect(selectedNavIndex(kNavEntries, '/receipt/1'), isNull);
  });
}
