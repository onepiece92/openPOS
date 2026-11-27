import 'dart:async' show Completer, unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/app_version.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/restart_notice.dart';
import 'package:pos_app/core/whats_new/release_notes.dart';

const kWhatsNewGotIt = 'Got it';

/// Checks once whether to show the notes; call after the first frame, from
/// the first normal screen. One settings read, and one small write when the
/// stored version changes. Never throws.
Future<void> maybeShowWhatsNew(BuildContext context, WidgetRef ref) async {
  try {
    // A restart or refusal note from AppRoot (after a restore, a reset, a
    // recovery) is on screen: wait for it to go, never stack on top of it.
    if (restartNoticeShowing.value) {
      final gone = Completer<void>();
      void listener() {
        if (!restartNoticeShowing.value && !gone.isCompleted) gone.complete();
      }

      restartNoticeShowing.addListener(listener);
      try {
        await gone.future;
      } finally {
        restartNoticeShowing.removeListener(listener);
      }
      if (!context.mounted) return;
    }
    final box = ref.read(settingsBoxProvider);
    final stored = box.get(kWhatsNewSeenKey);
    final plan = planWhatsNew(
      current: kAppVersion,
      lastSeen: stored is String ? stored : null,
      onboarded: ref.read(onboardingCompleteProvider),
      switchOn: ref.read(featureOnProvider(Feature.whatsNew)),
    );
    final write = plan.writeSeen;
    if (write != null) await box.put(kWhatsNewSeenKey, write);
    if (plan.show.isEmpty || !context.mounted) return;
    // Not awaited: the dialog stays open until the user closes it.
    unawaited(showWhatsNewDialog(context,
        notes: plan.show, headline: 'Updated to $kAppVersion'));
  } catch (e) {
    debugPrint('What\'s new check skipped: $e');
  }
}

/// Opens the notes of [notes] (newest first) in a dialog.
Future<void> showWhatsNewDialog(
  BuildContext context, {
  required List<ReleaseNote> notes,
  required String headline,
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => WhatsNewDialog(notes: notes, headline: headline),
    );

/// Text-first dialog: headline, bullets, the offline line, one button. A
/// one-second burst of small shapes plays once, unless the system asks for
/// reduced motion.
class WhatsNewDialog extends StatefulWidget {
  const WhatsNewDialog(
      {super.key, required this.notes, required this.headline});
  final List<ReleaseNote> notes;
  final String headline;

  @override
  State<WhatsNewDialog> createState() => _WhatsNewDialogState();
}

class _WhatsNewDialogState extends State<WhatsNewDialog>
    with SingleTickerProviderStateMixin {
  /// Created only when motion is allowed: with reduced motion there is no
  /// controller at all.
  AnimationController? _ctrl;
  bool _started = false;
  bool _motion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final mq = MediaQuery.of(context);
    _motion = !(mq.disableAnimations || mq.accessibleNavigation);
    if (_motion) {
      _ctrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 1000))
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final many = widget.notes.length > 1;
    Widget card = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Semantics(
            header: true,
            child: Text(widget.headline, style: tt.titleLarge),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final n in widget.notes) ...[
                  Text(many ? '${n.version}: ${n.title}' : n.title,
                      style: tt.titleSmall),
                  const SizedBox(height: 8),
                  for (final b in n.bullets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ExcludeSemantics(child: Text('•  ')),
                          Expanded(child: Text(b, style: tt.bodyMedium)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                ],
                Text(kWhatsNewOfflineLine,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(kWhatsNewGotIt),
            ),
          ),
        ),
      ],
    );
    final ctrl = _ctrl;
    if (ctrl != null) {
      card = ScaleTransition(
        scale: CurvedAnimation(
                parent: ctrl,
                curve: const Interval(0, 0.35, curve: Curves.easeOut))
            .drive(Tween(begin: 0.94, end: 1.0)),
        child: card,
      );
    }
    return Dialog(
      clipBehavior: Clip.hardEdge,
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        namesRoute: true,
        label: "What's new. ${widget.headline}",
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Stack(
            children: [
              card,
              if (ctrl != null)
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          key: const ValueKey('whats-new-burst'),
                          painter: BurstPainter(
                            progress: ctrl,
                            colors: [
                              cs.primary,
                              cs.secondary,
                              cs.tertiary,
                              const Color(0xFFFFB300),
                              const Color(0xFF26A69A),
                              const Color(0xFFEF5350),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Number of shapes in the burst.
const kBurstParticles = 40;

/// A one-shot burst of small squares and circles from the top centre,
/// falling and fading. Fixed seed: same picture every time, no allocation
/// per frame beyond the paint itself.
class BurstPainter extends CustomPainter {
  BurstPainter({required this.progress, required this.colors})
      : super(repaint: progress) {
    final r = math.Random(7);
    _angle = List.generate(kBurstParticles, (_) => r.nextDouble() * math.pi);
    _speed = List.generate(kBurstParticles, (_) => 0.5 + r.nextDouble() * 0.7);
    _size = List.generate(kBurstParticles, (_) => 3.0 + r.nextDouble() * 4);
  }

  final Animation<double> progress;
  final List<Color> colors;
  late final List<double> _angle;
  late final List<double> _speed;
  late final List<double> _size;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final paint = Paint();
    final origin = Offset(size.width / 2, size.height * 0.12);
    for (var i = 0; i < kBurstParticles; i++) {
      final dx = math.cos(_angle[i]) * _speed[i] * size.width * 0.6 * t;
      // Up first, then gravity pulls it down.
      final dy = -math.sin(_angle[i]) * _speed[i] * size.height * 0.25 * t +
          size.height * 0.45 * t * t;
      paint.color = colors[i % colors.length].withValues(alpha: 1 - t);
      final p = origin + Offset(dx, dy);
      if (i.isEven) {
        canvas.drawCircle(p, _size[i] / 2, paint);
      } else {
        canvas.drawRect(
            Rect.fromCenter(center: p, width: _size[i], height: _size[i]),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(BurstPainter old) =>
      old.progress != progress || old.colors != colors;
}
