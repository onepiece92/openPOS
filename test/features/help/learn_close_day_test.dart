import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/providers/feature_flags.dart';
import 'package:pos_app/features/help/presentation/learn_screen.dart';

void main() {
  testWidgets('Closing the day article names its Features switch',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 3000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: LearnScreen()));
    await tester.tap(find.text('Closing the day'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('(turn on ${Feature.endOfDay.label} in Features)'),
        findsOneWidget);
    expect(find.textContaining('"Not counted"'), findsOneWidget);
  });
}
