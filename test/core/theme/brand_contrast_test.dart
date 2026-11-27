import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/theme/app_theme.dart';

/// Every text/background pair the brand theme defines must pass WCAG AA:
/// 4.5:1 for text, 3:1 for icons, borders and other UI parts.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void _expectAA(String name, Color fg, Color bg, {double min = 4.5}) {
  final r = _contrast(fg, bg);
  expect(r, greaterThanOrEqualTo(min),
      reason: '$name is ${r.toStringAsFixed(2)}:1, needs $min:1');
}

void main() {
  for (final (mode, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    group('$mode theme', () {
      final cs = theme.colorScheme;
      // Page, card and tint: where text sits.
      final surfaces = {
        'surface': cs.surface,
        'card':
            mode == 'light' ? cs.surfaceContainerLowest : cs.surfaceContainer,
        'tint':
            mode == 'light' ? cs.surfaceContainer : cs.surfaceContainerHighest,
      };
      final textInks = {
        'onSurface': cs.onSurface,
        'onSurfaceVariant': cs.onSurfaceVariant,
        'primary': cs.primary,
        'secondary': cs.secondary,
        'tertiary': cs.tertiary,
        'error': cs.error,
        'success': StatusColors.success(cs),
        'warning': StatusColors.warning(cs),
      };

      test('text inks pass 4.5:1 on page, card and tint', () {
        for (final s in surfaces.entries) {
          for (final t in textInks.entries) {
            _expectAA('${t.key} on ${s.key}', t.value, s.value);
          }
        }
      });

      test('inks pass 3:1 as icons/UI on the deepest tint', () {
        for (final t in textInks.entries) {
          _expectAA('${t.key} on surfaceContainerHighest', t.value,
              cs.surfaceContainerHighest,
              min: 3);
        }
        _expectAA('outline on surface', cs.outline, cs.surface, min: 3);
      });

      test('section headers (muted grey, not orange) pass 4.5:1 on the page',
          () {
        expect(cs.onSurfaceVariant, isNot(cs.primary));
        _expectAA('section header', cs.onSurfaceVariant, cs.surface);
        _expectAA('section header on card', cs.onSurfaceVariant,
            mode == 'light' ? cs.surfaceContainerLowest : cs.surfaceContainer);
      });

      test('on-colours pass 4.5:1 on their fills', () {
        _expectAA('onPrimary', cs.onPrimary, cs.primary);
        _expectAA(
            'onPrimaryContainer', cs.onPrimaryContainer, cs.primaryContainer);
        _expectAA('onSecondaryContainer', cs.onSecondaryContainer,
            cs.secondaryContainer);
        _expectAA('onTertiaryContainer', cs.onTertiaryContainer,
            cs.tertiaryContainer);
        _expectAA('onError', cs.onError, cs.error);
        _expectAA('onErrorContainer', cs.onErrorContainer, cs.errorContainer);
        _expectAA('onInverseSurface', cs.onInverseSurface, cs.inverseSurface);
        _expectAA('snackbar text', theme.snackBarTheme.contentTextStyle!.color!,
            theme.snackBarTheme.backgroundColor!);
        _expectAA('snackbar action', theme.snackBarTheme.actionTextColor!,
            theme.snackBarTheme.backgroundColor!);
      });
    });
  }

  test('matte black on safety orange passes 4.5:1', () {
    _expectAA('onBrandOrange', AppTheme.onBrandOrange, AppTheme.brandOrange);
  });

  test('side nav (matte black) text and selected item pass', () {
    final nav = AppTheme.dark().colorScheme;
    _expectAA('nav label', nav.onSurface, AppTheme.matteBlack);
    _expectAA('nav group label', nav.onSurfaceVariant, AppTheme.matteBlack);
    _expectAA(
        'selected nav item', AppTheme.onBrandOrange, AppTheme.brandOrange);
  });

  group('stock states can be told apart', () {
    double hueGap(Color a, Color b) {
      final d = (HSLColor.fromColor(a).hue - HSLColor.fromColor(b).hue).abs();
      return d > 180 ? 360 - d : d;
    }

    for (final (mode, theme) in [
      ('light', AppTheme.light()),
      ('dark', AppTheme.dark()),
    ]) {
      test('$mode: in, low and out of stock differ by 1.5:1 or 60 degrees', () {
        final cs = theme.colorScheme;
        final states = {
          'in stock': cs.onSurfaceVariant,
          'low stock': StatusColors.warning(cs),
          'out of stock': cs.error,
        }.entries.toList();
        for (var i = 0; i < states.length; i++) {
          for (var j = i + 1; j < states.length; j++) {
            final a = states[i], b = states[j];
            final ok = _contrast(a.value, b.value) >= 1.5 ||
                hueGap(a.value, b.value) >= 60;
            expect(ok, isTrue, reason: '${a.key} vs ${b.key}');
          }
        }
      });

      test('$mode: low stock is not the accent and not the refund violet', () {
        final cs = theme.colorScheme;
        expect(StatusColors.warning(cs), isNot(cs.primary));
        expect(StatusColors.warning(cs), isNot(AppTheme.brandOrange));
        expect(StatusColors.warning(cs), isNot(cs.tertiary));
      });
    }
  });
}
