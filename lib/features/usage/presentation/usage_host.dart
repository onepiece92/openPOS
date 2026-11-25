import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/usage/application/usage_ask_controller.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/usage_constants.dart';
import 'package:pos_app/features/usage/usage_providers.dart';

/// Route of the feedback & usage screen.
const kUsageRoute = '/help/feedback';

/// App-wide glue for the usage counter, wrapped around the router's subtree
/// (inside MaterialApp, so the app's ScaffoldMessenger is above it):
/// * opens the usage box AFTER the first frame (never delaying it);
/// * flushes the counter when the app is paused or detached;
/// * shows the one-time disclosure ([kUsageDisclosureText]) once the box is
///   loaded and onboarding is done — keyed on "disclosure shown" being
///   absent, so upgrading installs see it too;
/// * shows the timed feedback ask when [UsageAskController.pending] fires.
///
/// Both lines are SnackBars: non-modal, dismissible, never in the way of a
/// sale.
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _counter.ensureLoaded();
      if (mounted) _maybeDisclose();
    });
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _ask.pending.removeListener(_onAsk);
    super.dispose();
  }

  void _maybeDisclose() {
    if (!kUsageFirstRunDisclosure || _disclosing) return;
    if (!_counter.isLoaded || _counter.disclosureShown) return;
    if (!ref.read(onboardingCompleteProvider)) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    _disclosing = true;
    messenger.showSnackBar(SnackBar(
      key: const ValueKey('usage-disclosure'),
      content: const Text(kUsageDisclosureText),
      duration: const Duration(seconds: 12),
      showCloseIcon: true,
      action: SnackBarAction(
          label: kUsageDisclosureAction, onPressed: widget.openUsage),
    ));
    _counter.markDisclosureShown();
  }

  void _onAsk() {
    if (!_ask.pending.value || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    _ask.markShown();
    messenger.showSnackBar(SnackBar(
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
      duration: const Duration(seconds: 10),
      showCloseIcon: true,
      action: SnackBarAction(
          label: kFeedbackAskAction, onPressed: widget.openUsage),
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
