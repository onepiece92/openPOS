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
import 'package:pos_app/features/onboarding/domain/country_default.dart';
import 'package:pos_app/features/onboarding/domain/locale_country.dart';
import 'package:pos_app/features/onboarding/domain/onboarding_state.dart';
import 'package:pos_app/features/onboarding/presentation/onboarding_notifier.dart';
import 'package:pos_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pos_app/features/onboarding/presentation/widgets/confirm_step.dart';
import 'package:pos_app/features/onboarding/presentation/widgets/country_step.dart';
import 'package:pos_app/features/onboarding/presentation/widgets/features_step.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

import '../../_support/temp_hive.dart';
import '../../_support/test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // rootBundle: country data
  late Box<dynamic> box;
  late AppDatabase db;

  setUp(() async {
    box = await openTempSettingsBox();
    db = openInMemoryDatabase();
    addTearDown(db.close);
  });

  ProviderContainer container({String? region}) {
    final c = ProviderContainer(overrides: [
      settingsBoxProvider.overrideWithValue(box),
      databaseProvider.overrideWithValue(db),
      deviceRegionProvider.overrideWithValue(region),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Map<String, Object?> stored() =>
      Map<String, Object?>.from(box.get(kFeaturesKey) as Map);

  group('steps', () {
    test(
        'Business type → Suggested features → Name → Country → Tax → '
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

    test('Taxes off in the chosen switches: no Tax step, one step fewer', () {
      final off = OnboardingState(
          switches: {for (final f in Feature.values) f: f != Feature.taxes});
      expect(off.steps, isNot(contains(OnboardingStep.tax)));
      expect(off.steps, hasLength(kOnboardingSteps.length - 1));
      expect(
          OnboardingState(step: off.steps.length - 1, switches: off.switches)
              .isLast,
          isTrue);
      expect(const OnboardingState().steps, contains(OnboardingStep.tax));
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
      BusinessType.marketStall: {Feature.reviewReminder, Feature.usageCounting},
      BusinessType.services: {
        ...app,
        Feature.customers,
        Feature.discounts,
        Feature.taxes,
        Feature.expenses,
      },
      BusinessType.other: {Feature.reviewReminder, Feature.usageCounting},
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
      await db
          .into(db.customers)
          .insert(CustomersCompanion.insert(name: 'Kept'));
      final c = container();
      final n = c.read(onboardingNotifierProvider.notifier)
        ..setBusinessType(BusinessType.other);
      await n.skip();
      expect(await db.select(db.customers).get(), hasLength(1));
      expect(stored()['customers'], isFalse);
    });
  });

  group('writing features_v1', () {
    test(
        'Start minimal turns every optional feature off but Review reminder '
        'and Usage counting; Auto-print off', () async {
      await box.put(kLoyaltyEnabled, true);
      final c = container();
      final n = c.read(onboardingNotifierProvider.notifier)
        ..setBusinessType(BusinessType.retail)
        ..startMinimal();
      await n.skip();
      final flags = c.read(featureFlagsProvider);
      for (final f in Feature.values) {
        expect(flags.isOn(f),
            f == Feature.reviewReminder || f == Feature.usageCounting,
            reason: f.name);
      }
      expect(flags.autoPrint, isFalse);
      expect(box.get(kLoyaltyEnabled), isFalse);
    });

    test(
        'Review reminder and Usage counting are on in every preset; '
        'Auto-print off only in the minimal ones', () {
      for (final t in BusinessType.values) {
        expect(kPresets[t], containsAll(kAlwaysSuggested), reason: t.name);
        final minimal =
            t == BusinessType.marketStall || t == BusinessType.other;
        expect(kPresets[t]!.contains(Feature.autoPrint), !minimal,
            reason: t.name);
      }
    });

    test(
        'skip with no choice writes the defaults (every feature on) and '
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

    test(
        'finish writes the edited switches and the business type; a 0 rate '
        'leaves Taxes alone and adds no rate', () async {
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
      expect(stored()['taxes'], isTrue,
          reason: "one way only: a 0 rate keeps the preset's Taxes on");
      expect(await db.select(db.taxRates).get(), isEmpty,
          reason: 'no "Tax 0%" rate for a blank tax step');
      expect(c.read(defaultTaxIdProvider), isNull);
      expect(box.get(kLoyaltyEnabled), isTrue);
      expect(box.get(kBusinessType), 'cafe');
      expect(c.read(featuresIntroSeenProvider), isTrue);
      expect(c.read(settingsProvider).businessNameOrDefault, 'My Store');

      final c2 = container();
      final n2 = c2.read(onboardingNotifierProvider.notifier)
        ..setBusinessType(BusinessType.cafe) // Taxes on
        ..setTaxRate(8.5);
      await n2.finish();
      final rates = await db.select(db.taxRates).get();
      expect(rates.single.rate, closeTo(0.085, 1e-9));
      expect(c2.read(defaultTaxIdProvider), rates.single.id);
    });

    for (final (name, choose) in <(String, void Function(OnboardingNotifier))>[
      ('Market stall', (n) => n.setBusinessType(BusinessType.marketStall)),
      ('Something else', (n) => n.setBusinessType(BusinessType.other)),
      (
        'Start minimal',
        (n) => n
          ..setBusinessType(BusinessType.cafe)
          ..startMinimal()
      ),
    ]) {
      test('$name never ends with Taxes on from a country pre-fill', () async {
        final c = container(region: 'GB');
        final n = c.read(onboardingNotifierProvider.notifier);
        choose(n);
        n.setCountry(const CountryDefault(
            code: 'GB',
            name: 'United Kingdom',
            currency: 'GBP',
            symbol: '£',
            timezone: 'Europe/London',
            taxName: 'VAT',
            taxRate: 20)); // the pre-fill
        expect(c.read(onboardingNotifierProvider).steps,
            isNot(contains(OnboardingStep.tax)));
        await n.finish();
        expect(c.read(featureFlagsProvider).taxes, isFalse);
        expect(await db.select(db.taxRates).get(), isEmpty);
      });
    }

    test('Taxes on with the rate field cleared: Taxes on, no rate row',
        () async {
      final c = container();
      final n = c.read(onboardingNotifierProvider.notifier)
        ..setBusinessType(BusinessType.cafe)
        ..setTaxRate(0); // what the cleared field now sets
      await n.finish();
      expect(c.read(featureFlagsProvider).taxes, isTrue);
      expect(await db.select(db.taxRates).get(), isEmpty);
    });

    test("a 0 rate never turns off Taxes the user switched on", () async {
      final c = container();
      final n = c.read(onboardingNotifierProvider.notifier)
        ..setBusinessType(BusinessType.marketStall) // preset: Taxes off
        ..setSwitch(Feature.taxes, true)
        ..setTaxRate(0);
      await n.finish();
      expect(stored()['taxes'], isTrue);
    });

    test('skip keeps the name, country and currency already entered', () async {
      final c = container();
      final n = c.read(onboardingNotifierProvider.notifier)
        ..setBusinessName('Corner Cafe')
        ..setCountry(const CountryDefault(
            code: 'KE',
            name: 'Kenya',
            currency: 'KES',
            symbol: 'KSh',
            timezone: 'Africa/Nairobi',
            taxName: 'VAT',
            taxRate: 16));
      for (var i = 0; i <= OnboardingStep.country.index; i++) {
        n.next(); // now on the Tax step: name and country passed
      }
      await n.skip();
      final s = c.read(settingsProvider);
      expect(s.businessName, 'Corner Cafe');
      expect(s.currencyCode, 'KES');
      expect(s.currencySymbol, 'KSh');
      expect(s.countryCode, 'KE');
      expect(await db.select(db.taxRates).get(), isEmpty,
          reason: 'the tax step was not passed');
    });

    test('Skip on the Country step keeps the country just picked', () async {
      final c = container(region: 'US');
      final n = c.read(onboardingNotifierProvider.notifier)
        ..setCountry(const CountryDefault(
            code: 'KE',
            name: 'Kenya',
            currency: 'KES',
            symbol: 'KSh',
            timezone: 'Africa/Nairobi',
            taxName: 'VAT',
            taxRate: 16))
        ..next()
        ..next()
        ..next(); // on the Country step, not passed yet
      expect(
          c.read(onboardingNotifierProvider).current, OnboardingStep.country);
      await n.skip();
      expect(c.read(settingsProvider).currencyCode, 'KES');
      expect(c.read(settingsProvider).countryCode, 'KE');
    });

    group('device region defaults', () {
      for (final (region, code, currency, symbol) in [
        ('GB', 'GB', 'GBP', '£'),
        (null, 'US', 'USD', r'$'),
        ('ZZ', '', 'USD', r'$'), // not in the data: no country, no timezone
      ]) {
        test(
            'region $region: skip and a blank finish both give '
            '$currency/$code', () async {
          final skipped = container(region: region);
          await skipped.read(onboardingNotifierProvider.notifier).skip();
          final s1 = skipped.read(settingsProvider);
          expect((s1.currencyCode, s1.currencySymbol, s1.countryCode),
              (currency, symbol, code));

          await box.clear();
          final finished = container(region: region);
          await finished.read(onboardingNotifierProvider.notifier).finish();
          final s2 = finished.read(settingsProvider);
          expect((s2.currencyCode, s2.currencySymbol, s2.countryCode),
              (currency, symbol, code));
          if (region == 'ZZ') expect(s2.timezone, '');
        });
      }
    });

    test('a fresh install skipping at step 1 gets the neutral intro', () async {
      final c = container();
      await c.read(onboardingNotifierProvider.notifier).skip();
      expect(c.read(featuresIntroSeenProvider), isFalse);
      expect(c.read(featuresIntroFreshProvider), isTrue);
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

    test('skip after the Tax step with a rate adds it (Taxes on)', () async {
      final c = container();
      final n = c.read(onboardingNotifierProvider.notifier)
        ..setBusinessType(BusinessType.cafe)
        ..setTaxRate(5);
      for (var i = 0; i <= OnboardingStep.tax.index; i++) {
        n.next();
      }
      await n.skip();
      expect(stored()['taxes'], isTrue);
      expect(await db.select(db.taxRates).get(), hasLength(1));
    });
  });

  group('screen', () {
    late ProviderContainer c;
    Future<GoRouter> pump(WidgetTester tester, {String? region}) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1800);
      addTearDown(tester.view.reset);
      c = container(region: region);
      final router = GoRouter(initialLocation: '/onboarding', routes: [
        GoRoute(
            path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/pos', builder: (_, __) => const Text('POS home')),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: c, child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets(
        "the country step pre-selects the device region's country, "
        'not Nepal', (tester) async {
      await pump(tester, region: 'KE');
      expect(c.read(onboardingNotifierProvider).country?.code, 'KE');
    });

    testWidgets(
        "a region not in the data: the match line, nothing pre-selected",
        (tester) async {
      await pump(tester, region: 'ZZ');
      expect(c.read(onboardingNotifierProvider).country, isNull);
      for (var i = 0; i < OnboardingStep.country.index; i++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
      expect(find.text(kUnmatchedRegionText), findsOneWidget);
    });

    testWidgets(
        'Taxes off (Market stall): the Tax step is skipped and Confirm says '
        'Taxes is off', (tester) async {
      await pump(tester, region: 'GB');
      await tester.tap(find.text(BusinessType.marketStall.label));
      await tester.pumpAndSettle();
      final count = kOnboardingSteps.length - 1;
      expect(find.text('2 of $count'), findsOneWidget);
      while (find.text('Finish Setup').evaluate().isEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
      expect(find.text('$count of $count'), findsOneWidget);
      expect(find.text(kTaxesOffSummary), findsOneWidget);
    });

    testWidgets('the always-suggested switches say why', (tester) async {
      await pump(tester);
      await tester.tap(find.text(BusinessType.other.label));
      await tester.pumpAndSettle();
      for (final why in kSuggestWhy.values) {
        await tester.scrollUntilVisible(find.textContaining(why), 200,
            scrollable: find.byType(Scrollable).last);
        expect(find.textContaining(why), findsOneWidget);
      }
    });

    testWidgets('no usable region: the US is pre-selected', (tester) async {
      await pump(tester);
      expect(c.read(onboardingNotifierProvider).country?.code, 'US');
    });

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
      testWidgets(
          'Skip on step ${at + 1} (${kOnboardingSteps[at].name}) '
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
      expect(
          appRedirect(onboarded: true, flags: flags, location: '/pos'), isNull);
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

    testWidgets('a fresh install that skipped setup sees the neutral line',
        (tester) async {
      await box.put(kOnboardingCompleteKeyForTest, true);
      await box.put(kFeaturesIntroFresh, true);
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              const Scaffold(drawer: PosDrawer(), body: Text('home')),
        ),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container(),
          child: MaterialApp.router(routerConfig: router)));
      tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      expect(find.text(kFeaturesIntroFreshText), findsOneWidget);
      expect(find.text(kFeaturesIntroText), findsNothing);
    });
  });
}

/// The settings key `onboarding_complete` (private in hive_provider.dart).
const kOnboardingCompleteKeyForTest = 'onboarding_complete';
