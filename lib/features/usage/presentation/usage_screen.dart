import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/theme/tokens.dart';
import 'package:pos_app/core/utils/share_origin.dart';
import 'package:pos_app/features/backup/data/share_files.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/data/usage_inputs.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/domain/usage_summary.dart';
import 'package:pos_app/features/usage/usage_constants.dart';
import 'package:pos_app/features/usage/usage_providers.dart';

/// Feedback & usage summary: pick what to improve, type a message, tick the
/// usage details to include, and send exactly the previewed text through
/// WhatsApp or email. Below that, everything counted, with "Stop counting"
/// and Reset. Text only — no images, charts or animations.
///
/// The shop-size COUNT queries run here, once, when the screen opens.
class UsageScreen extends ConsumerStatefulWidget {
  const UsageScreen({super.key});

  @override
  ConsumerState<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends ConsumerState<UsageScreen> {
  late final UsageCounter _counter = ref.read(usageCounterProvider);
  final _message = TextEditingController();
  UsageSelection _selection = const UsageSelection();
  ShopSizeCounts? _shop;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _message.addListener(_rebuild);
    _counter.ensureLoaded().then((_) => _rebuild());
    readShopSizeCounts(ref.read(databaseProvider)).then((s) {
      if (mounted) setState(() => _shop = s);
    }, onError: (Object _) {});
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  /// The one string shown in the preview and handed to WhatsApp / email.
  String _payload() => buildUsageSummary(
        selection: _selection,
        message: _message.text,
        counts: _counter.counts,
        env: currentUsageEnvironment(
            currencyCode: ref.read(currencyCodeProvider)),
        shop: _shop,
      );

  Future<void> _send(String text, Future<UsageSendResult> Function() send,
      ScaffoldMessengerState messenger,
      {required String unavailable}) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      var r = UsageSendResult.noApp;
      try {
        r = await send();
      } catch (_) {/* e.g. the share sheet failed: same as nothing opened */}
      if (r == UsageSendResult.sharedAsFile) {
        messenger.showSnackBar(const SnackBar(
          content: Text(kUsageSharedAsFileHint),
          duration: Duration(seconds: 8),
        ));
      }
      if (r == UsageSendResult.noApp) {
        try {
          await Clipboard.setData(ClipboardData(text: text));
        } catch (_) {/* still say where to send it */}
        messenger.showSnackBar(SnackBar(
          content: Text(unavailable),
          duration: const Duration(seconds: 8),
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset usage counts?'),
        content: const Text(
            'This deletes every count on this device. It cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true) {
      await _counter.reset();
      _rebuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    ref.watch(currencyCodeProvider);
    final text = _payload();
    final canSend = canSendUsageSummary(_selection, _message.text) && !_sending;
    final counts = _counter.counts;

    Widget header(String s) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(s,
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text(kUsageScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(kFeedbackInstruction, style: tt.bodyLarge),
          const SizedBox(height: 8),
          Text(kOfflineFirstLine,
              key: const ValueKey('offline-first-line'),
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          header(kFeedbackAreaQuestion),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final a in FeatureArea.values)
                FilterChip(
                  key: ValueKey('pick-${a.name}'),
                  label: Text(a.label),
                  selected: _selection.picked.contains(a),
                  onSelected: (_) =>
                      setState(() => _selection = _selection.togglePicked(a)),
                ),
            ],
          ),
          header('Your message'),
          TextField(
            key: const ValueKey('feedback-message'),
            controller: _message,
            maxLength: kFeedbackMessageMaxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: "What's missing, or what would you change?",
              border: OutlineInputBorder(),
            ),
          ),
          header('Usage details to include'),
          for (final a in FeatureArea.values)
            CheckboxListTile(
              key: ValueKey('tick-${a.name}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _selection.tickedAreas.contains(a),
              onChanged: (_) =>
                  setState(() => _selection = _selection.toggleArea(a)),
              title: Text('${a.label} usage counts'),
            ),
          CheckboxListTile(
            key: const ValueKey('tick-app-info'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: _selection.appInfo,
            onChanged: (v) =>
                setState(() => _selection = _selection.withAppInfo(v ?? false)),
            title: const Text('App version, platform, OS, locale, currency'),
          ),
          CheckboxListTile(
            key: const ValueKey('tick-shop-size'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: _selection.shopSize,
            onChanged: (v) => setState(
                () => _selection = _selection.withShopSize(v ?? false)),
            title: const Text(
                'Shop size ranges (products, orders in last 7 days, customers)'),
          ),
          header(kUsagePreviewHeading),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(text,
                key: const ValueKey('usage-preview'),
                style: const TextStyle(
                    fontFamily: AppFonts.mono,
                    fontFamilyFallback: AppFonts.monoFallback)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (bctx) => FilledButton.icon(
                    key: const ValueKey('send-whatsapp'),
                    icon: const Icon(Icons.chat_rounded),
                    label: const Text('Send via WhatsApp'),
                    onPressed: !canSend
                        ? null
                        : () {
                            final origin = shareOriginFor(bctx);
                            final messenger = ScaffoldMessenger.of(context);
                            _send(
                                text,
                                () => sendUsageViaWhatsApp(text,
                                    launch: ref.read(linkLauncherProvider),
                                    share: ref.read(shareFilesProvider),
                                    shareOrigin: origin,
                                    tempDir: ref.read(usageTempDirProvider)),
                                messenger,
                                unavailable: kUsageWhatsAppUnavailable);
                          },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('send-email'),
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Send via email'),
                  onPressed: !canSend
                      ? null
                      : () => _send(
                          text,
                          () => sendUsageViaEmail(text,
                              launch: ref.read(linkLauncherProvider)),
                          ScaffoldMessenger.of(context),
                          unavailable: kUsageEmailUnavailable),
                ),
              ),
            ],
          ),
          header('Usage summary'),
          Text(
            'Counts stay on this device unless you choose to send them.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          Text(
            kUsageScreenCountsNote,
            key: const ValueKey('screen-counts-note'),
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          SwitchListTile(
            key: const ValueKey('stop-counting'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Stop counting'),
            value: !_counter.countingEnabled,
            onChanged: !_counter.isLoaded
                ? null
                : (stop) async {
                    await _counter.setCountingEnabled(!stop);
                    _rebuild();
                  },
          ),
          for (final a in FeatureArea.values) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: Text(a.label,
                  style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
            for (final e in UsageEvent.of(a))
              Text('${e.name}: ${counts[e]?.count ?? 0}', style: tt.bodySmall),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('reset-usage'),
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset counts'),
              onPressed: _counter.isLoaded ? _confirmReset : null,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
