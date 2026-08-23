import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/app.dart';

/// Dragging any scroll view dismisses the software keyboard, inherited from
/// the app-wide ScrollBehavior rather than set per list.
void main() {
  bool textFieldHasFocus() =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>() !=
      null;

  testWidgets('a list inherits onDrag dismissal from the app ScrollBehavior',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      scrollBehavior: appScrollBehavior,
      home: Scaffold(
        body: ListView(
          children: [
            const TextField(),
            for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text('$i')),
          ],
        ),
      ),
    ));

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(textFieldHasFocus(), isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(textFieldHasFocus(), isFalse,
        reason: 'dragging the list should drop the keyboard');
  });

  testWidgets('without the behavior the keyboard survives a drag',
      (tester) async {
    // Guards the assertion above against passing for the wrong reason.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            const TextField(),
            for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text('$i')),
          ],
        ),
      ),
    ));

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(textFieldHasFocus(), isTrue);
  });
}
