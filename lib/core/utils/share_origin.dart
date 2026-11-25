import 'package:flutter/widgets.dart';

/// Where the share sheet is anchored.
///
/// On iPad the share sheet is a popover and needs a rectangle to point at.
/// share_plus refuses to share at all there — "sharePositionOrigin: argument
/// must be set" — unless the rectangle is non-empty and lies inside the
/// app's view, so every share has to pass one. iPhone and Android ignore it.

/// The rectangle of the widget that owns [context] (the tapped tile or
/// button), in screen coordinates, made safe by [resolveShareOrigin]. Call
/// it before any `await`, while the widget is still on screen.
Rect shareOriginFor(BuildContext context) {
  final view = View.of(context);
  final screen = view.physicalSize / view.devicePixelRatio;
  Rect? widgetRect;
  final box = context.findRenderObject();
  if (box is RenderBox && box.attached && box.hasSize) {
    widgetRect = box.localToGlobal(Offset.zero) & box.size;
  }
  return resolveShareOrigin(widgetRect, screen);
}

/// [widgetRect] cut down to the part that is on a screen of size [screen];
/// the centre of the screen when there is no rectangle or none of it is
/// visible. The result is never empty and never reaches outside the screen,
/// which are the two things share_plus checks on iPad.
Rect resolveShareOrigin(Rect? widgetRect, Size screen) {
  final bounds = Offset.zero & screen;
  if (widgetRect != null && widgetRect.isFinite) {
    final visible = widgetRect.intersect(bounds);
    if (visible.width >= 1 && visible.height >= 1) return visible;
  }
  if (screen.width >= 1 && screen.height >= 1) {
    return Rect.fromCenter(center: bounds.center, width: 1, height: 1);
  }
  // No usable screen size (not laid out yet): still hand over a real
  // rectangle rather than an empty one.
  return const Rect.fromLTWH(0, 0, 1, 1);
}
