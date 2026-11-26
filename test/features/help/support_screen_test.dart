import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/help/presentation/support_screen.dart';

void main() {
  testWidgets('no Documentation row, no duplicate Ordering App card',
      (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: SupportScreen()),
    ));
    expect(find.text('WhatsApp Chat'), findsOneWidget);
    expect(find.text('RebuzzPOS'), findsOneWidget);
    expect(find.text('Documentation'), findsNothing);
    expect(find.text('Ordering App'), findsNothing);
  });

  testWidgets('Open-source licences row opens the licence page',
      (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: SupportScreen()),
    ));
    await tester.tap(find.text('Open-source licences'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
