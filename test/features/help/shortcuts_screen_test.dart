import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/help/presentation/shortcuts_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester, FeatureFlags flags) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [featureFlagsProvider.overrideWithValue(flags)],
      child: const MaterialApp(home: ShortcutsScreen()),
    ));
  }

  const offDestinations = ['Customers', 'Tables', 'Expenses', 'Inventory'];

  testWidgets('switched-off destinations are not listed', (tester) async {
    await pump(tester, FeatureFlags.only({}));
    for (final label in offDestinations) {
      expect(find.text(label), findsNothing, reason: label);
    }
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('everything on: all are listed', (tester) async {
    await pump(tester, FeatureFlags.only(Feature.values.toSet()));
    for (final label in offDestinations) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });
}
