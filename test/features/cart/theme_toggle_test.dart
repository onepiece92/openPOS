import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/cart/presentation/home.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

/// The day/night button on the POS app bar.
void main() {
  late Directory tmp;
  late Box<dynamic> heldBox;
  late Box<dynamic> settingsBox;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_theme_');
    Hive.init(tmp.path);
    heldBox = await Hive.openBox<dynamic>('held_orders', bytes: Uint8List(0));
    settingsBox = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    String? mode,
    bool? switchOn,
    Brightness platform = Brightness.light,
  }) async {
    if (mode != null) await settingsBox.put('theme_mode', mode);
    if (switchOn != null) {
      await settingsBox.put(kFeaturesKey, {Feature.themeToggle.name: switchOn});
    }
    tester.platformDispatcher.platformBrightnessTestValue = platform;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final c = ProviderContainer(overrides: [
      settingsBoxProvider.overrideWithValue(settingsBox),
      heldOrdersBoxProvider.overrideWithValue(heldBox),
      productsStreamProvider.overrideWith((ref) => Stream.value([])),
      categoriesStreamProvider.overrideWith((ref) => Stream.value([])),
      productSalesCountProvider.overrideWith((ref) async => <int, int>{}),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: CartScreen()),
    ));
    await tester.pumpAndSettle();
    return c;
  }

  final moon = find.byIcon(Icons.dark_mode_outlined);
  final sun = find.byIcon(Icons.light_mode_outlined);

  testWidgets('switch on (default): the button is there', (tester) async {
    await pump(tester, mode: 'light');
    expect(moon, findsOneWidget);
  });

  testWidgets('switch off: the button is not built', (tester) async {
    await pump(tester, mode: 'light', switchOn: false);
    expect(moon, findsNothing);
    expect(sun, findsNothing);
  });

  testWidgets('light: moon, tooltip, 48 dp; a tap stores dark', (tester) async {
    final c = await pump(tester, mode: 'light');
    expect(find.byTooltip('Switch to dark mode'), findsOneWidget);
    expect(
        tester
            .getSize(find.widgetWithIcon(IconButton, Icons.dark_mode_outlined))
            .shortestSide,
        greaterThanOrEqualTo(48));
    await tester.tap(moon);
    await tester.pumpAndSettle();
    expect(c.read(settingsProvider).themeMode, ThemeMode.dark);
    expect(settingsBox.get('theme_mode'), 'dark');
    expect(sun, findsOneWidget);
  });

  testWidgets('dark: sun, tooltip; a tap stores light', (tester) async {
    final c = await pump(tester, mode: 'dark');
    expect(find.byTooltip('Switch to light mode'), findsOneWidget);
    await tester.tap(sun);
    await tester.pumpAndSettle();
    expect(c.read(settingsProvider).themeMode, ThemeMode.light);
    expect(settingsBox.get('theme_mode'), 'light');
    expect(moon, findsOneWidget);
  });

  testWidgets('system on a light device: moon; a tap stores dark',
      (tester) async {
    final c = await pump(tester);
    expect(moon, findsOneWidget);
    await tester.tap(moon);
    await tester.pumpAndSettle();
    expect(c.read(settingsProvider).themeMode, ThemeMode.dark);
  });

  testWidgets('system on a dark device: sun; a tap stores light',
      (tester) async {
    final c = await pump(tester, platform: Brightness.dark);
    expect(sun, findsOneWidget);
    await tester.tap(sun);
    await tester.pumpAndSettle();
    expect(c.read(settingsProvider).themeMode, ThemeMode.light);
  });
}
