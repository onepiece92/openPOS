import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/help/presentation/learn_screen.dart';

void main() {
  testWidgets('Stock tracking article says untracked products are not restocked',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 3000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: LearnScreen()));
    await tester.tap(find.text('Stock tracking'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('switched off isn\'t restocked by a void or refund'),
        findsOneWidget);
    expect(find.textContaining('corrected in Inventory'), findsOneWidget);
  });
}
