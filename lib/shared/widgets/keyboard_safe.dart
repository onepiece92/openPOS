import 'package:flutter/material.dart';

/// Pads its child by the on-screen keyboard's height (viewInsets.bottom),
/// animating in sync with the keyboard so focused content is never blocked.
///
/// Use inside bottom sheets, dialogs, or any popover that contains TextFields.
/// `showAppSheet` already wraps its builder in this widget — only use directly
/// for non-sheet popovers (custom overlays, AlertDialog content, etc.).
class KeyboardSafe extends StatelessWidget {
  const KeyboardSafe({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: child,
    );
  }
}
