import 'package:flutter/material.dart';

import 'package:pos_app/shared/widgets/keyboard_safe.dart';

/// Project-wide modal bottom sheet helper.
///
/// Sets `isScrollControlled: true` and `useSafeArea: true`, then wraps the
/// builder's output in [KeyboardSafe] so on-screen keyboards never cover
/// focused content. Prefer this over calling [showModalBottomSheet] directly.
///
/// For sheets with long scrollable content (list pickers, customer search),
/// pass `draggable: true` to opt into a [DraggableScrollableSheet] capped at
/// the full screen height so it can grow above the keyboard.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool draggable = false,
  double initialSize = 0.5,
  double minSize = 0.25,
  Color? backgroundColor,
  ShapeBorder? shape,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: backgroundColor,
    shape: shape,
    builder: (ctx) {
      if (draggable) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialSize,
          minChildSize: minSize,
          maxChildSize: 1.0,
          builder: (innerCtx, scrollCtrl) => PrimaryScrollController(
            controller: scrollCtrl,
            child: KeyboardSafe(child: Builder(builder: builder)),
          ),
        );
      }
      return KeyboardSafe(child: Builder(builder: builder));
    },
  );
}
