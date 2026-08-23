import 'package:flutter/material.dart';

/// Drops text-field focus — and with it the software keyboard — when the user
/// taps a part of the screen nothing else claimed.
///
/// Mounted once around the app's builder, so it covers every route, bottom
/// sheet and dialog rather than needing a wrapper per screen.
///
/// Taps are resolved by the gesture arena: text fields, buttons, list tiles and
/// scrollables are deeper in the tree and win against this detector, so it only
/// fires on genuinely blank space. [HitTestBehavior.translucent] is what lets
/// those blank areas register a hit at all.
class DismissKeyboardOnTap extends StatelessWidget {
  const DismissKeyboardOnTap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onTap: () {
        final context = FocusManager.instance.primaryFocus?.context;
        if (context == null) return;
        // Only text inputs open a keyboard, so leave any other focus alone —
        // that keeps desktop focus traversal and the Cmd-shortcuts working.
        // The focused node's own widget is a `Focus` for text fields and
        // buttons alike; the EditableText it belongs to sits above it.
        if (context.findAncestorWidgetOfExactType<EditableText>() == null) {
          return;
        }
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: child,
    );
  }
}
