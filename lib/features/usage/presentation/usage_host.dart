import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/restart_notice.dart';
import 'package:pos_app/features/usage/application/usage_ask_controller.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/usage_constants.dart';
import 'package:pos_app/features/usage/usage_providers.dart';

/// Route of the feedback & usage screen.
const kUsageRoute = '/help/feedback';

/// How long the disclosure and the ask stay up before they go by themselves.
const kUsageDisclosureDuration = Duration(seconds: 12);
const kFeedbackAskDuration = Duration(seconds: 10);

/// Floating, so the Scaffold lays it out ABOVE the sell screen's bottom
/// bars (held tickets + Charge) instead of over them.
SnackBar _usageSnackBar({
  required Key key,
  required Widget content,
  required Duration duration,
  required String actionLabel,
  required VoidCallback onAction,
}) =>
    SnackBar(
      key: key,
      content: content,
      duration: duration,
      // With an action, SnackBar.persist defaults to true (it would never
      // go by itself).
      persist: false,
      showCloseIcon: true,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      action: SnackBarAction(label: actionLabel, onPressed: onAction),
    );

/// App-wide glue for the usage counter, wrapped around the router's subtree
/// (inside MaterialApp, so the app's ScaffoldMessenger is above it):
/// * opens the usage box AFTER the first frame (never delaying it), then
///   removes a summary .txt left from an earlier share;
/// * flushes the counter when the app is paused or detached;
/// * shows the one-time disclosure ([kUsageDisclosureText]) once the box is
///   loaded, onboarding is done and no restart notice is covering the
///   bottom of the screen — keyed on "disclosure shown" being absent, so
///   upgrading installs see it too. It counts as shown only once it has
///   actually been on screen and gone (not when a restart tore it down);
/// * shows the timed feedback ask when [UsageAskController.pending] fires.
///
/// Both are floating SnackBars: non-modal, dismissible, auto-dismissing,
/// laid out above the sell screen's bottom bars.
class UsageHost extends ConsumerStatefulWidget {
  const UsageHost({super.key, required this.child, required this.openUsage});
  final Widget child;

  /// Navigates to the feedback & usage screen.
  final VoidCallback openUsage;

  @override
  ConsumerState<UsageHost> createState() => _UsageHostState();
}

class _UsageHostState extends ConsumerState<UsageHost> {
  late final UsageCounter _counter = ref.read(usageCounterProvider);
  late final UsageAskController _ask = ref.read(usageAskControllerProvider);
  AppLifecycleListener? _lifecycle;
  bool _disclosing = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: _counter.onLifecycle);
    _ask.pending.addListener(_onAsk);
    restartNoticeShowing.addListener(_maybeDisclose);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _counter.ensureLoaded();
      if (!mounted) return;
      _maybeDisclose();
      unawaited(_removeOldSummaryFile());
    });
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _ask.pending.removeListener(_onAsk);
    restartNoticeShowing.removeListener(_maybeDisclose);
    super.dispose();
  }

  Future<void> _removeOldSummaryFile() async {
    try {
      final dir = await ref.read(usageTempDirProvider)();
      final f = File(p.join(dir.path, kUsageSummaryFileName));
      if (f.existsSync()) f.deleteSync(); // one stat when there is none
    } catch (_) {/* no temp folder (tests, desktop quirks): nothing to do */}
  }

  void _maybeDisclose() {
    if (!kUsageFirstRunDisclosure || _disclosing || !mounted) return;
    if (restartNoticeShowing.value) return; // retried when it ends
    if (!_counter.isLoaded || _counter.disclosureShown) return;
    if (!ref.read(onboardingCompleteProvider)) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    _disclosing = true;
    final shown = messenger.showSnackBar(_usageSnackBar(
      key: const ValueKey('usage-disclosure'),
      content: const Text(kUsageDisclosureText),
      duration: kUsageDisclosureDuration,
      actionLabel: kUsageDisclosureAction,
      onAction: widget.openUsage,
    ));
    shown.closed.then((reason) {
      // `remove`: torn down with the app (a restore restart), never seen
      // through — show it again next time.
      if (reason == SnackBarClosedReason.remove) {
        _disclosing = false;
        return;
      }
      _counter.markDisclosureShown();
    });
  }

  void _onAsk() {
    if (!_ask.pending.value || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    _ask.markShown();
    messenger.showSnackBar(_usageSnackBar(
      key: const ValueKey('feedback-ask'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kFeedbackAskText),
          SizedBox(height: 2),
          Text(kOfflineFirstShortLine, style: TextStyle(fontSize: 12)),
        ],
      ),
      duration: kFeedbackAskDuration,
      actionLabel: kFeedbackAskAction,
      onAction: widget.openUsage,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Onboarding finishing is the other moment the disclosure may be due.
    ref.listen(onboardingCompleteProvider, (_, done) {
      if (done) _maybeDisclose();
    });
    return widget.child;
  }
}
