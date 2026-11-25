import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/app.dart' show appRedirect;
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/onboarding/domain/business_type.dart';
import 'package:pos_app/features/onboarding/domain/onboarding_state.dart';
import 'package:pos_app/features/onboarding/presentation/onboarding_notifier.dart';
import 'package:pos_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pos_app/features/onboarding/presentation/widgets/features_step.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

import '../../_support/temp_hive.dart';
import '../../_support/test_db.dart';

void main() {
  late Box<dynamic> box;
  late AppDatabase db;

  setUp(() async {
    box = await openTempSettingsBox();
    db = openInMemoryDatabase();
    addTearDown(db.close);
  });

  ProviderContainer container() {
    final c = ProviderContainer(overrides: [
      settingsBoxProvider.overrideWithValue(box),
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Map<String, Object?> stored() =>
      Map<String, Object?>.from(box.get(kFeaturesKey) as Map);

  group('steps', () {
    test('Business type → Suggested features → Name → Country → Tax → '
        'Confirm; the count comes from the list', () {
      expect(kOnboardingSteps, [
        OnboardingStep.businessType,
        OnboardingStep.features,
        OnboardingStep.name,
        OnboardingStep.country,
        OnboardingStep.tax,
        OnboardingStep.confirm,
      ]);
      expect(OnboardingState(step: kOnboardingSteps.length - 1).isLast, isTrue);
      expect(const OnboardingState(step: 4).isLast, isFalse);
    });
  });

  group('presets', () {
    const app = {
      Feature.autoPrint,
      Feature.reviewReminder,
      Feature.usageCounting
    };
    final expected = <BusinessType, Set<Feature>>{
      BusinessType.foodTruck: {
        ...app,
        Feature.heldTickets,
        Feature.discounts,
        Feature.taxes,
        Feature.dashboardExtras,
      },
      BusinessType.cafe: {
        ...app,
        Feature.heldTickets,
        Feature.discounts,
        Feature.taxes,
        Feature.customers,
        Feature.loyalty,
        Feature.dashboardExtras,
      },
      BusinessType.restaurant: {
        ...app,
        Feature.tables,
        Feature.heldTickets,
        Feature.discounts,
        Feature.taxes,
        Feature.dashboardExtras,
      },
      BusinessType.retail: {
        ...app,
        Feature.stockTracking,
        Feature.customers,
        Feature.discounts,
        Feature.taxes,
        Feature.units,
        Feature.bundles,
        Feature.costProfit,
        Feature.expenses,
        Feature.csvImportExport,
        Feature.dashboardExtras,
      },
      BusinessType.marketStall: {},
      BusinessType.services: {
        ...app,
        Feature.customers,
        Feature.discounts,
        Feature.taxes,
        Feature.expenses,
      },
      BusinessType.other: {},
    };

    for (final t in BusinessType.values) {
      test('${t.name}: exactly its features on, everything else off', () {
        expect(kPresets[t], expected[t]);
        final c = container();
        c.read(onboardingNotifierProvider.notifier).setBusinessType(t);
        final s = c.read(onboardingNotifierProvider).switches!;
        for (final f in Feature.values) {
          expect(s[f], expected[t]!.contains(f), reason: '${t.name} ${f.name}');
        }
      });
    }

    test('a preset changes switches only, never data', () async {
      await db.into(db.customers).insert(
          CustomersCompanion.insert(name: 'Kept'));
      final c = container();
      final n = c.read(onboardingNotifierProvider.notifier)
        ..setBusinessType(BusinessType.other);
      await n.skip();
      expect(await db.select(db.customers).get(), hasLength(1));
      expect(stored()['customers'], isFalse);
    });
  });

  group('writing features_v1', () {
    test('Start minimal turns every optional feature off', () async {
      await box.put(kLoyaltyEnabled, true);
      final c = container();
      final n = c.read(onboardingNotifierProvider.notifier)
        ..setBusinessType(BusinessType.retail)
        ..startMinimal();
      expect(n.shownSwitches.values, everyElement(isFalse));
      await n.skip();
      final flags = c.read(featureFlagsProvider);
      for (final f in Feature.values) {
        expect(flags.isOn(f), isFalse, reason: f.name);
      }
      expect(box.get(kLoyaltyEnabled), isFalse);
    });

    test('skip with no choice writes the defaults (every feature on) and '
        'leaves loyalty alone', () async {
      final c = container();
      await c.read(onboardingNotifierProvider.notifier).skip();
      expect(box.get(kOnboardingCompleteKeyForTest), isTrue);
      expect(stored().values, everyElement(isTrue));
      expect(stored().containsKey('loyalty'), isFalse);
      expect(box.containsKey(kLoyaltyEnabled), isFalse);
      expect(box.containsKey(kBusinessType), isFalse);
      expect(c.read(featuresIntroSeenProvider), isFalse,
          reason: 'skipped before the suggestions: the drawer line explains');
    });

    test('finish writes the edited switches, the business type, and the tax '
        'step sets Taxes (rate > 0 = on)', () async {
      final c = container();
      final n = c.read(onboardingNotifierProvider.notifier)
        ..setBusinessType(BusinessType.cafe)
        ..setSwitch(Feature.discounts, false)
        ..setTaxRate(0);
      for (var i = 0; i < kOnboardingSteps.length - 1; i++) {
        n.next();
      }
      await n.finish();
      expect(stored()['discounts'], isFalse);
      expect(stored()['customers'], isTrue);
      expect(stored()['taxes'], isFalse, reason: 'rate 0 → Taxes off');
      expect(box.get(kLoyaltyEnabled), isTrue);
      expect(box.get(kBusinessType), 'cafe');
      expect(c.read(featuresIntroSeenProvider), isTrue);
      expect(c.read(settingsProvider).businessNameOrDefault, 'My Store');

      final c2 = container();
      final n2 = c2.read(onboardingNotifierProvider.notifier)
        ..setBusinessType(BusinessType.marketStall)
        ..setTaxRate(8.5);
      await n2.finish();
      expect(c2.read(featureFlagsProvider).taxes, isTrue);
    });

    test('skip before the tax step does not touch Taxes from the rate',
        () async {
      final c = container();
      final n = c.read(onboardingNotifierProvider.notifier)
        ..setBusinessType(BusinessType.foodTruck)
        ..setTaxRate(0)
        ..next();
      await n.skip();
      expect(stored()['taxes'], isTrue, reason: "the preset's choice");
    });
  });

  group('screen', () {
    Future<GoRouter> pump(WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1800);
      addTearDown(tester.view.reset);
      final c = container();
      final router = GoRouter(initialLocation: '/onboarding', routes: [
        GoRoute(
            path: '/onboarding',
            builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/pos', builder: (_, __) => const Text('POS home')),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: c, child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('the header counts every step', (tester) async {
      await pump(tester);
      expect(find.text('1 of ${kOnboardingSteps.length}'), findsOneWidget);
      expect(find.text('What kind of business?'), findsOneWidget);
      for (final t in BusinessType.values) {
        expect(find.text(t.label), findsOneWidget);
      }
      await tester.tap(find.text('Retail shop'));
      await tester.pumpAndSettle();
      expect(find.text('2 of ${kOnboardingSteps.length}'), findsOneWidget);
      expect(find.text(kSuggestTitle), findsOneWidget);
      await tester.scrollUntilVisible(find.text(kSuggestFooter), 200,
          scrollable: find.byType(Scrollable).last);
      expect(find.text(kSuggestFooter), findsOneWidget);
    });

    for (var at = 0; at < kOnboardingSteps.length; at++) {
      testWidgets('Skip on step ${at + 1} (${kOnboardingSteps[at].name}) '
          'completes setup and writes features_v1', (tester) async {
        final router = await pump(tester);
        for (var i = 0; i < at; i++) {
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
        }
        expect(find.text('${at + 1} of ${kOnboardingSteps.length}'),
            findsOneWidget);
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, '/pos');
        expect(box.get(kOnboardingCompleteKeyForTest), isTrue);
        expect(box.get(kFeaturesKey), isA<Map>());
      });
    }
  });

  group('upgrades', () {
    test('onboarding never replays once complete', () {
      final flags = FeatureFlags.defaults();
      expect(appRedirect(onboarded: true, flags: flags, location: '/pos'),
          isNull);
      expect(appRedirect(onboarded: false, flags: flags, location: '/pos'),
          '/onboarding');
    });

    testWidgets('the drawer intro line shows once, until dismissed',
        (tester) async {
      await box.put(kOnboardingCompleteKeyForTest, true); // an upgrade
      Future<void> open() async {
        final router = GoRouter(routes: [
          GoRoute(
            path: '/',
            builder: (_, __) =>
                const Scaffold(drawer: PosDrawer(), body: Text('home')),
          ),
          GoRoute(path: '/features', builder: (_, __) => const Text('F')),
        ]);
        addTearDown(router.dispose);
        await tester.pumpWidget(UncontrolledProviderScope(
            container: container(),
            child: MaterialApp.router(routerConfig: router)));
        tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
        await tester.pumpAndSettle();
      }

      await open();
      expect(find.text(kFeaturesIntroText), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('features-intro-dismiss')));
      await tester.pumpAndSettle();
      expect(find.text(kFeaturesIntroText), findsNothing);
      expect(box.get(kFeaturesIntroSeen), isTrue);

      await open(); // a later launch
      expect(find.text(kFeaturesIntroText), findsNothing);
    });
  });
}

/// The settings key `onboarding_complete` (private in hive_provider.dart).
const kOnboardingCompleteKeyForTest = 'onboarding_complete';
