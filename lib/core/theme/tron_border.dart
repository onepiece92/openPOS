import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

// ─── Tron light-trail border ─────────────────────────────────────────────────
//
// A "neon comet" animation that races around a rounded-rect border.
// Use [TronBorderPainter] inside a [CustomPaint] driven by an
// [AnimationController] that repeats (0 → 1 → 0 → …).
//
// Typical usage:
//
//   Positioned.fill(
//     child: AnimatedBuilder(
//       animation: _ctrl,
//       builder: (_, __) => CustomPaint(
//         painter: TronBorderPainter(_ctrl.value, radius: 12),
//       ),
//     ),
//   )
//
// where [_ctrl] is an AnimationController with `.repeat()`.

/// Extracts a [Path] segment from [metric] between [from] and [to], handling
/// wrap-around when the segment crosses the end of the perimeter.
Path extractWrappedPath(PathMetric metric, double from, double to) {
  final len = metric.length;
  final f = from % len;
  final e = to % len;
  if (f <= e) return metric.extractPath(f, e);
  // Segment wraps around the end of the perimeter.
  final p = metric.extractPath(f, len);
  p.addPath(metric.extractPath(0, e), Offset.zero);
  return p;
}

/// Paints a glowing cyan comet chasing around a rounded-rect border.
///
/// [t] is the animation progress (0.0 → 1.0), typically from
/// [AnimationController.value] driven with [AnimationController.repeat].
/// [radius] should match the border-radius of the widget being decorated.
/// [color] defaults to the classic Tron cyan (`#00E5FF`).
class TronBorderPainter extends CustomPainter {
  const TronBorderPainter(
    this.t, {
    this.radius = 12.0,
    this.color = const Color(0xFF00E5FF),
  });

  /// Animation progress, 0.0 → 1.0.
  final double t;

  /// Corner radius — should match the decorated widget's border-radius.
  final double radius;

  /// Comet colour. Defaults to Tron cyan.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      Radius.circular(radius),
    );

    // 1 ── Faint static base border
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = color.withValues(alpha: 0.18),
    );

    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;
    final len = metric.length;
    final head = t * len;
    final trail = len * 0.30; // 30 % of perimeter

    // 2 ── Trail: 8 steps ramping from dim → bright
    const steps = 8;
    for (var i = 0; i < steps; i++) {
      final alpha = ((i + 1) / steps) * 0.65;
      final from = head - trail * (steps - i) / steps;
      final to = head - trail * (steps - i - 1) / steps;
      canvas.drawPath(
        extractWrappedPath(metric, from, to),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: alpha),
      );
    }

    // 3 ── Soft glow bloom on the front half of the trail
    canvas.drawPath(
      extractWrappedPath(metric, head - trail * 0.5, head),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 4 ── Bright white tip with halo
    final tipLen = math.min(16.0, trail * 0.12);
    canvas.drawPath(
      extractWrappedPath(metric, head - tipLen, head),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.90)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(TronBorderPainter old) => old.t != t;
}
