import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/shared/widgets/dismiss_keyboard.dart';

/// Tapping blank space drops text focus (and the software keyboard with it),
/// without stealing taps from anything that handles its own.
void main() {
  Widget harness({VoidCallback? onButton}) => MaterialApp(
        home: DismissKeyboardOnTap(
          child: Scaffold(
            body: Column(
              children: [
                const TextField(),
                ElevatedButton(
                  onPressed: onButton ?? () {},
                  child: const Text('Press me'),
                ),
                const Expanded(child: SizedBox.expand(key: Key('blank'))),
              ],
            ),
          ),
        ),
      );

  testWidgets('tapping blank space unfocuses a focused text field',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.hasPrimaryFocus, isTrue);

    await tester.tapAt(tester.getCenter(find.byKey(const Key('blank'))));
    await tester.pump();

    final focused = FocusManager.instance.primaryFocus;
    expect(focused?.context?.findAncestorWidgetOfExactType<EditableText>(),
        isNull,
        reason: 'the text field should no longer hold focus');
  });

  testWidgets('taps still reach buttons underneath', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(harness(onButton: () => pressed++));
    await tester.tap(find.byType(TextField));
    await tester.pump();

    await tester.tap(find.text('Press me'));
    await tester.pump();

    expect(pressed, 1, reason: 'the wrapper must not swallow the tap');
  });

  testWidgets('tapping the text field itself keeps focus', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>(),
      isNotNull,
    );
  });

  testWidgets('non-text focus is left alone', (tester) async {
    await tester.pumpWidget(harness());
    final button = Focus.of(tester.element(find.text('Press me')),
        scopeOk: true);
    button.requestFocus();
    await tester.pump();
    expect(button.hasPrimaryFocus, isTrue);

    await tester.tapAt(tester.getCenter(find.byKey(const Key('blank'))));
    await tester.pump();

    expect(button.hasPrimaryFocus, isTrue,
        reason: 'only text inputs open a keyboard; other focus should survive '
            'so desktop traversal and Cmd-shortcuts keep working');
  });
}
