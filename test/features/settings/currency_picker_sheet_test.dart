import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/settings/presentation/widgets/currency_section.dart';

import '../../_support/temp_hive.dart';

/// The theme already draws a drag handle on every bottom sheet, and
/// showAppSheet(draggable: true) already supplies the draggable wrapper.
/// The picker must add neither a second handle nor a second draggable.
void main() {
  testWidgets('currency picker: one handle, one draggable, title at the top',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final settings = await tester.runAsync(openTempSettingsBox);
    final container = ProviderContainer(
        overrides: [settingsBoxProvider.overrideWithValue(settings!)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: CurrencySection()),
      ),
    ));
    await tester.tap(find.text('Currency'));
    await tester.pumpAndSettle();

    expect(find.text('Select Currency'), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w.runtimeType.toString() == '_DragHandle'),
      findsOneWidget,
    );
    // No hand-drawn 36x4 handle.
    expect(
      find.byWidgetPredicate((w) =>
          w is Container &&
          w.constraints?.maxWidth == 36 &&
          w.constraints?.maxHeight == 4),
      findsNothing,
    );
    // Title sits right under the handle, not below an empty gap.
    final sheetTop = tester.getTopLeft(find.byType(BottomSheet)).dy;
    final titleTop = tester.getTopLeft(find.text('Select Currency')).dy;
    expect(titleTop - sheetTop, lessThan(80));

    // The list still scrolls with the outer sheet's controller.
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Select Currency'), findsOneWidget);
  });
}
