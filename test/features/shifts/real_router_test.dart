import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/src/information_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/app.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/shifts/shift_settings.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

/// The app's REAL router (app.dart), driven without building any screen.
void main() {
  late BuildContext context;
  late Box<dynamic> box;
  late ProviderContainer container;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.init('.');
    box = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
    await box.put('onboarding_complete', true);
    container = ProviderContainer(
        overrides: [settingsBoxProvider.overrideWithValue(box)]);
    addTearDown(container.dispose);
    addTearDown(Hive.close);
  });

  Future<void> pumpCtx(WidgetTester tester) async {
    await tester.pumpWidget(Builder(builder: (c) {
      context = c;
      return const SizedBox();
    }));
  }

  /// Where the real router lands for [path], redirects applied. Parsing
  /// runs the app's redirect without building any screen.
  Future<String> go(String path) async {
    final r = container.read(routerProvider);
    final list = await r.routeInformationParser
        .parseRouteInformationWithDependencies(
            RouteInformation(
                uri: Uri.parse(path),
                state: RouteInformationState<void>(type: NavigatingType.go)),
            context);
    return list.uri.path;
  }

  testWidgets('every drawer route is a real route (feature on)',
      (tester) async {
    await pumpCtx(tester);
    await container
        .read(settingsProvider.notifier)
        .setFeature(Feature.endOfDay, true);
    final router = container.read(routerProvider);
    for (final route in [for (final e in kNavEntries) e.route]) {
      expect(router.configuration.findMatch(Uri.parse(route)).isError, isFalse,
          reason: route);
      expect(await go(route), route);
    }
    expect(await go('/close-day/history'), '/close-day/history');
    expect(await go('/close-day/history/7'), '/close-day/history/7');
    expect(await go('/close-day/history/abc'), '/close-day/history/abc');
  });

  testWidgets('feature off: the real redirect sends close-day routes to /pos',
      (tester) async {
    await pumpCtx(tester);
    for (final p in [
      '/close-day',
      '/close-day/history',
      '/close-day/history/7'
    ]) {
      expect(await go(p), '/pos', reason: p);
    }
  });

  testWidgets('flipping the switch works without a restart', (tester) async {
    await pumpCtx(tester);
    expect(await go('/close-day'), '/pos');
    await tester.runAsync(() => container
        .read(settingsProvider.notifier)
        .setFeature(Feature.endOfDay, true));
    await tester.pump();
    expect(container.read(endOfDayEnabledProvider), isTrue);
    expect(await go('/close-day'), '/close-day');
    await tester.runAsync(() => container
        .read(settingsProvider.notifier)
        .setFeature(Feature.endOfDay, false));
    await tester.pump();
    expect(container.read(endOfDayEnabledProvider), isFalse);
    expect(await go('/close-day'), '/pos');
  });
}
