import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/gestures.dart' show HitTestResult;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/app_version.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/restart_notice.dart';
import 'package:pos_app/features/help/presentation/support_screen.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/presentation/usage_host.dart';
import 'package:pos_app/features/usage/presentation/usage_screen.dart';
import 'package:pos_app/features/usage/usage_constants.dart';
import 'package:pos_app/features/usage/usage_providers.dart';

import '../../_support/test_db.dart';

void main() {
  late AppDatabase db;
  late Box<dynamic> settings;
  late Box<dynamic> usageBox;
  late int sells;
  late Directory tmp;

  setUp(() async {
    Hive.init('.');
    settings = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
    // A fresh memory box = an install that never had a usage box (a new
    // install, or an existing one upgrading to this version).
    usageBox = await Hive.openBox<dynamic>(kUsageBoxName, bytes: Uint8List(0));
    db = openInMemoryDatabase();
    sells = 0;
    tmp = Directory.systemTemp.createTempSync('pos_usage_host_');
  });
  tearDown(() async {
    tmp.deleteSync(recursive: true);
    await db.close();
    await Hive.close();
  });

  Future<ProviderContainer> pump(WidgetTester tester,
      {bool onboarded = true, String initial = '/'}) async {
    await settings.put('onboarding_complete', onboarded);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1600);
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      settingsBoxProvider.overrideWithValue(settings),
      usageTempDirProvider.overrideWithValue(() async => tmp),
      usageCounterProvider.overrideWith((ref) {
        final c = UsageCounter(openBox: () async => usageBox);
        ref.onDispose(c.dispose);
        return c;
      }),
    ]);
    addTearDown(container.dispose);
    final router = GoRouter(initialLocation: initial, routes: [
      GoRoute(
        path: '/',
        // Like the sell screen: Charge lives in the bottom bar.
        builder: (_, __) => Scaffold(
          body: const Center(child: Text('Products')),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FilledButton(
                  key: const ValueKey('charge'),
                  onPressed: () => sells++,
                  child: const Text('Charge')),
            ),
          ),
        ),
      ),
      GoRoute(path: '/help/support', builder: (_, __) => const SupportScreen()),
      GoRoute(path: kUsageRoute, builder: (_, __) => const UsageScreen()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        // Same wiring as POSApp.
        builder: (context, child) =>
            UsageHost(openUsage: () => router.push(kUsageRoute), child: child!),
      ),
    ));
    await tester.pump(); // post-frame: the box opens
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800)); // snackbar in
    return container;
  }

  /// The Charge button's centre still hits the button itself, not the
  /// SnackBar over it.
  void expectChargeUncovered(WidgetTester tester) {
    final charge = find.byKey(const ValueKey('charge'));
    final centre = tester.getCenter(charge);
    final result = HitTestResult();
    tester.binding.hitTestInView(result, centre, tester.view.viewId);
    final button = tester.renderObject(charge);
    expect(result.path.any((e) => e.target == button), isTrue,
        reason: 'Charge is covered');
    expect(
        tester.getRect(find.byType(SnackBar)).overlaps(tester.getRect(charge)),
        isFalse);
  }

  group('first-run disclosure', () {
    test('wording', () {
      expect(
          kUsageDisclosureText,
          'Open POS counts which features you use. The counts stay on this '
          'device unless you choose to send them. See them or turn counting '
          'off in Usage summary.');
    });

    testWidgets('shown once, on an upgrade with no usage box; not modal',
        (tester) async {
      await pump(tester);
      expect(find.text(kUsageDisclosureText), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expectChargeUncovered(tester);
      // The sell screen underneath still works with the line showing.
      await tester.tap(find.byKey(const ValueKey('charge')));
      expect(sells, 1);
      expect(find.text(kUsageDisclosureText), findsOneWidget);
      // Marked shown once it has been on screen and gone.
      expect(usageBox.get(kUsageDisclosureShownKey), isNull);
      await tester.tap(find.byIcon(Icons.close)); // dismissible
      await tester.pumpAndSettle();
      expect(find.text(kUsageDisclosureText), findsNothing);
      expect(usageBox.get(kUsageDisclosureShownKey), isTrue);
    });

    testWidgets('goes by itself after its duration (persist: false)',
        (tester) async {
      await pump(tester);
      expect(find.text(kUsageDisclosureText), findsOneWidget);
      await tester.pump(kUsageDisclosureDuration);
      await tester.pumpAndSettle();
      expect(find.text(kUsageDisclosureText), findsNothing);
      expect(usageBox.get(kUsageDisclosureShownKey), isTrue);
    });

    testWidgets('waits for a restart notice to end', (tester) async {
      restartNoticeShowing.value = true;
      addTearDown(() => restartNoticeShowing.value = false);
      await pump(tester);
      expect(find.text(kUsageDisclosureText), findsNothing);
      restartNoticeShowing.value = false;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text(kUsageDisclosureText), findsOneWidget);
    });

    testWidgets('torn down by a restart before it was seen: not marked',
        (tester) async {
      await pump(tester);
      expect(find.text(kUsageDisclosureText), findsOneWidget);
      await tester.pumpWidget(const SizedBox()); // the app is rebuilt
      await tester.pump();
      expect(usageBox.get(kUsageDisclosureShownKey), isNull);
    });

    testWidgets('not shown again once it was shown', (tester) async {
      await usageBox.put(kUsageDisclosureShownKey, true);
      await pump(tester);
      expect(find.text(kUsageDisclosureText), findsNothing);
    });

    testWidgets('not over onboarding; shown once it is done', (tester) async {
      final c = await pump(tester, onboarded: false);
      expect(find.text(kUsageDisclosureText), findsNothing);
      expect(usageBox.get(kUsageDisclosureShownKey), isNull);
      await c.read(settingsProvider.notifier).setOnboardingComplete(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text(kUsageDisclosureText), findsOneWidget);
    });

    testWidgets('tapping it opens Usage summary', (tester) async {
      await pump(tester);
      await tester.tap(find.text(kUsageDisclosureAction));
      await tester.pumpAndSettle();
      expect(find.byType(UsageScreen), findsOneWidget);
      expect(find.text(kUsageScreenTitle), findsOneWidget);
      expect(find.text('Usage summary'), findsOneWidget); // its section
    });
  });

  testWidgets('a summary .txt left from an earlier share is removed',
      (tester) async {
    final old = File(p.join(tmp.path, kUsageSummaryFileName))
      ..writeAsStringSync('old summary');
    await usageBox.put(kUsageDisclosureShownKey, true);
    await pump(tester);
    await tester.pump();
    expect(old.existsSync(), isFalse);
  });

  group('timed feedback ask', () {
    testWidgets('shows the one question, marks the version, opens the flow',
        (tester) async {
      await usageBox.put(kUsageDisclosureShownKey, true);
      final c = await pump(tester);
      c.read(usageAskControllerProvider).pending.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text(kFeedbackAskText), findsOneWidget);
      expect(find.text(kOfflineFirstShortLine), findsOneWidget);
      expectChargeUncovered(tester);
      expect(kFeedbackAskText,
          "What's the one thing you'd change about Open POS?");
      expect(usageBox.get(kUsageAskedVersionKey), kAppVersionFull);
      expect(settings.get(kPromptLastShownAt), isNotNull);
      await tester.tap(find.text(kFeedbackAskAction));
      await tester.pumpAndSettle();
      expect(find.byType(UsageScreen), findsOneWidget);
    });

    testWidgets('the ask goes by itself after its duration', (tester) async {
      await usageBox.put(kUsageDisclosureShownKey, true);
      final c = await pump(tester);
      c.read(usageAskControllerProvider).pending.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text(kFeedbackAskText), findsOneWidget);
      await tester.pump(kFeedbackAskDuration);
      await tester.pumpAndSettle();
      expect(find.text(kFeedbackAskText), findsNothing);
    });
  });

  group('Support', () {
    testWidgets('a permanent "Send feedback & usage" row opens the flow',
        (tester) async {
      await usageBox.put(kUsageDisclosureShownKey, true);
      await pump(tester, initial: '/help/support');
      expect(find.text(kFeedbackSupportRowTitle), findsOneWidget);
      await tester.tap(find.text(kFeedbackSupportRowTitle));
      await tester.pumpAndSettle();
      expect(find.byType(UsageScreen), findsOneWidget);
      expect(find.text(kOfflineFirstLine), findsOneWidget);
    });
  });
}
