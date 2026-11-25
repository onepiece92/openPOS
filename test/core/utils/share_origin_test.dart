import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/utils/share_origin.dart';

/// share_plus 10.1.4 on iPad (FPPSharePlusPlugin.m) fails a share unless the
/// origin rectangle is non-empty and inside the app's view. These tests pin
/// those two properties; they cannot show the popover itself.
void main() {
  const ipad = Size(1024, 1366);
  final screen = Offset.zero & ipad;

  void expectUsable(Rect r, Size size) {
    expect(r.isEmpty, isFalse, reason: '$r is empty');
    expect(r.width, greaterThanOrEqualTo(1));
    expect(r.height, greaterThanOrEqualTo(1));
    final bounds = Offset.zero & size;
    expect(bounds.contains(r.topLeft), isTrue, reason: '$r outside $bounds');
    expect(r.right <= bounds.right && r.bottom <= bounds.bottom, isTrue,
        reason: '$r outside $bounds');
  }

  group('resolveShareOrigin', () {
    test('a widget on screen is used as it is', () {
      const tile = Rect.fromLTWH(16, 200, 992, 80);
      expect(resolveShareOrigin(tile, ipad), tile);
    });

    test('a widget partly off screen is cut to the visible part', () {
      final r =
          resolveShareOrigin(const Rect.fromLTWH(16, 1330, 992, 80), ipad);
      expect(r, const Rect.fromLTRB(16, 1330, 1008, 1366));
      expectUsable(r, ipad);
    });

    test('no widget, an empty one, or one off screen: the screen centre', () {
      for (final rect in [
        null,
        Rect.zero,
        const Rect.fromLTWH(100, 100, 0, 40),
        const Rect.fromLTWH(16, 2000, 992, 80),
        const Rect.fromLTWH(-500, -500, 100, 100),
        const Rect.fromLTWH(double.nan, 0, 10, 10),
        const Rect.fromLTWH(0, 0, double.infinity, 10),
      ]) {
        final r = resolveShareOrigin(rect, ipad);
        expectUsable(r, ipad);
        expect(r.center, screen.center, reason: 'for $rect');
      }
    });

    test('never empty, even with no screen size', () {
      expect(resolveShareOrigin(null, Size.zero).isEmpty, isFalse);
    });
  });

  group('shareOriginFor', () {
    testWidgets('is the tapped widget\'s rectangle in logical pixels',
        (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = ipad * 2;
      addTearDown(tester.view.reset);

      Rect? origin;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: Builder(
              builder: (context) => FilledButton(
                onPressed: () => origin = shareOriginFor(context),
                child: const Text('Share'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Share'));

      expect(origin, tester.getRect(find.byType(FilledButton)));
      expectUsable(origin!, ipad);
    });

    testWidgets('falls back to the screen centre for a widget with no size',
        (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = ipad * 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SizedBox.shrink(key: Key('nothing'))),
      ));
      final origin =
          shareOriginFor(tester.element(find.byKey(const Key('nothing'))));
      expectUsable(origin, ipad);
      expect(origin.center, screen.center);
    });
  });
}
