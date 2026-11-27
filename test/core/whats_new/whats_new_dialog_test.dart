import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pos_app/core/app_version.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/restart_notice.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/core/whats_new/release_notes.dart';
import 'package:pos_app/core/whats_new/whats_new_dialog.dart';

final _note =
    ReleaseNote(version: '1.2.0', major: true, title: 'A title', bullets: [
  for (var i = 0; i < 6; i++)
    'Bullet number $i is a longer line that needs to wrap on a narrow screen'
]);

Widget _app(Widget body,
        {bool reduced = false,
        double scale = 1,
        Size? size,
        bool dark = false}) =>
    MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(
            disableAnimations: reduced,
            textScaler: TextScaler.linear(scale),
            size: size ?? const Size(400, 800)),
        child: child!,
      ),
      home: Builder(
          builder: (c) => Scaffold(
              body: Center(
                  child: TextButton(
                      onPressed: () => showWhatsNewDialog(c,
                          notes: [_note], headline: 'Updated to 1.2.0'),
                      child: const Text('open'))))),
    );

void main() {
  testWidgets('renders, and Got it closes it', (tester) async {
    await tester.pumpWidget(_app(const SizedBox()));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Updated to 1.2.0'), findsOneWidget);
    expect(find.textContaining('Bullet number 0'), findsOneWidget);
    expect(find.text(kWhatsNewOfflineLine), findsOneWidget);
    await tester.tap(find.text(kWhatsNewGotIt));
    await tester.pumpAndSettle();
    expect(find.text('Updated to 1.2.0'), findsNothing);
  });

  testWidgets('animates by default', (tester) async {
    await tester.pumpWidget(_app(const SizedBox()));
    await tester.tap(find.text('open'));
    await tester.pump();
    expect(find.byKey(const ValueKey('whats-new-burst')), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('(e) reduced motion: no painter, no controller running',
      (tester) async {
    await tester.pumpWidget(_app(const SizedBox(), reduced: true));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Updated to 1.2.0'), findsOneWidget);
    expect(find.byKey(const ValueKey('whats-new-burst')), findsNothing);
    // No scale-in either: the dialog's own controller was never created.
    expect(
        find.descendant(
            of: find.byType(WhatsNewDialog),
            matching: find.byType(ScaleTransition)),
        findsNothing);
  });

  for (final dark in [false, true]) {
    for (final size in [const Size(360, 640), const Size(1024, 768)]) {
      testWidgets('large text scrolls without overflow ($size dark=$dark)',
          (tester) async {
        await tester.pumpWidget(_app(const SizedBox(),
            scale: 2, size: size, dark: dark, reduced: true));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(kWhatsNewGotIt), findsOneWidget);
      });
    }
  }

  group('maybeShowWhatsNew', () {
    late Directory tmp;
    late Box<dynamic> box;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('pos_whatsnew_');
      Hive.init(tmp.path);
      box = await Hive.openBox<dynamic>('settings');
    });
    tearDown(() async {
      await Hive.close();
      await tmp.delete(recursive: true);
    });

    Future<void> launch(WidgetTester tester) async {
      late BuildContext ctx;
      late WidgetRef ref;
      await tester.pumpWidget(ProviderScope(
        overrides: [settingsBoxProvider.overrideWithValue(box)],
        child: MaterialApp(
          home: Consumer(builder: (c, r, _) {
            ctx = c;
            ref = r;
            return const Scaffold(body: SizedBox());
          }),
        ),
      ));
      await tester.runAsync(() => maybeShowWhatsNew(ctx, ref));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
    }

    Future<void> put(WidgetTester tester, String k, Object? v) =>
        tester.runAsync(() => box.put(k, v));

    testWidgets('fresh install shows nothing and stores the version',
        (tester) async {
      await launch(tester);
      expect(find.text(kWhatsNewGotIt), findsNothing);
      expect(box.get(kWhatsNewSeenKey), kAppVersion);
    });

    testWidgets('onboarded, no key: stores the version at once',
        (tester) async {
      await put(tester, kOnboardingCompleteKey, true);
      await launch(tester);
      expect(box.get(kWhatsNewSeenKey), kAppVersion);
      // The notes only show when a bundled major release <= current exists.
      final due = kReleaseNotes
          .any((r) => r.major && compareVersions(r.version, kAppVersion) <= 0);
      expect(find.text(kWhatsNewGotIt), due ? findsOneWidget : findsNothing);
    });

    testWidgets('switch off: nothing shown, version still advances',
        (tester) async {
      await put(tester, kOnboardingCompleteKey, true);
      await put(tester, kWhatsNewSeenKey, '0.9.0');
      await put(tester, kFeaturesKey, {Feature.whatsNew.name: false});
      await launch(tester);
      expect(find.text(kWhatsNewGotIt), findsNothing);
      expect(box.get(kWhatsNewSeenKey), kAppVersion);
    });

    testWidgets('waits while a restart note is showing, then checks',
        (tester) async {
      // Already current: the check then writes nothing (a Hive write cannot
      // finish inside the fake-async zone).
      await put(tester, kWhatsNewSeenKey, kAppVersion);
      restartNoticeShowing.value = true;
      addTearDown(() => restartNoticeShowing.value = false);
      late BuildContext ctx;
      late WidgetRef ref;
      await tester.pumpWidget(ProviderScope(
        overrides: [settingsBoxProvider.overrideWithValue(box)],
        child: MaterialApp(
          home: Consumer(builder: (c, r, _) {
            ctx = c;
            ref = r;
            return const Scaffold(body: SizedBox());
          }),
        ),
      ));
      var done = false;
      unawaited(maybeShowWhatsNew(ctx, ref).then((_) => done = true));
      await tester.pump();
      expect(done, isFalse);
      restartNoticeShowing.value = false;
      await tester.pump();
      expect(done, isTrue);
    });

    testWidgets('onboarding writes the version before the router can see it',
        (tester) async {
      final c = ProviderContainer(
          overrides: [settingsBoxProvider.overrideWithValue(box)]);
      addTearDown(c.dispose);
      Object? seenWhenOnboarded = 'unset';
      c.listen(settingsProvider, (_, next) {
        if (next.onboardingComplete) {
          seenWhenOnboarded = box.get(kWhatsNewSeenKey);
        }
      });
      await tester.runAsync(
          () => c.read(settingsProvider.notifier).setOnboardingComplete(true));
      expect(seenWhenOnboarded, kAppVersion,
          reason: 'the key is stored before onboarded flips');
      // So the check that follows the router change shows nothing.
      final plan = planWhatsNew(
          current: kAppVersion,
          lastSeen: seenWhenOnboarded as String?,
          onboarded: true,
          switchOn: true);
      expect(plan.show, isEmpty);
    });

    testWidgets('an upgrade shows the pop-up; the flag drops on Got it',
        (tester) async {
      await put(tester, kOnboardingCompleteKey, true);
      await put(tester, kWhatsNewSeenKey, '1.1.0');
      await launch(tester);
      expect(find.text(kWhatsNewGotIt), findsOneWidget);
      expect(whatsNewShowing.value, isTrue);
      expect(box.get(kWhatsNewSeenKey), kAppVersion);
      await tester.tap(find.text(kWhatsNewGotIt));
      await tester.pumpAndSettle();
      expect(whatsNewShowing.value, isFalse);
    });

    testWidgets('the flag also drops when the app is replaced under the pop-up',
        (tester) async {
      await put(tester, kOnboardingCompleteKey, true);
      await put(tester, kWhatsNewSeenKey, '1.1.0');
      await launch(tester);
      expect(whatsNewShowing.value, isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(whatsNewShowing.value, isFalse);
    });
  });
}
