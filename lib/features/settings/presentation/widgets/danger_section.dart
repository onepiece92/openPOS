import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/app_root.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/features/settings/data/factory_reset.dart';

// ── Danger Zone ───────────────────────────────────────────────────────────────

class DangerSection extends ConsumerWidget {
  const DangerSection({super.key, this.onErase});

  /// Runs the erase once confirmed; defaults to `AppRoot.factoryReset`.
  @visibleForTesting
  final Future<void> Function(BuildContext context)? onErase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: cs.errorContainer.withValues(alpha: 0.2),
      child: ListTile(
        leading: Icon(Icons.delete_forever_rounded, color: cs.error),
        title: Text(
          'Factory Reset',
          style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Erase all data and restart onboarding'),
        trailing: Icon(Icons.chevron_right_rounded, color: cs.error),
        onTap: () => _confirmReset(context, ref),
      ),
    );
  }

  /// Step one is the tap on the tile, step two this dialog (as in 1.1.0).
  /// The automatic backups are listed as it opens (one listing of
  /// `backups/auto`). Once confirmed, one backup is taken first when the
  /// shop has data; if that fails the user is asked again.
  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    DateTime? latest;
    try {
      final files =
          await const SnapshotService().listLocal(await autoBackupDir());
      if (files.isNotEmpty) latest = await files.first.lastModified();
    } catch (_) {/* unreadable: say there are none, the safe side */}
    if (!context.mounted) return;
    final confirmed = await _ask(
      context,
      title: kFactoryResetTitle,
      text: factoryResetConfirmText(latestBackup: latest),
    );
    if (!confirmed || !context.mounted) return;

    final backupFailed = await _backupFirst(context, ref);
    if (!context.mounted) return;
    if (backupFailed &&
        !(await _ask(context, text: kBackupFirstFailed) && context.mounted)) {
      return;
    }
    await (onErase ?? _doReset)(context);
  }

  /// Runs the pre-reset backup behind a text-only, undismissable dialog.
  /// True when it failed.
  Future<bool> _backupFirst(BuildContext context, WidgetRef ref) async {
    final run = ref.read(preResetBackupProvider)();
    var failed = false;
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(content: Text(kSavingBackupFirst)),
      ),
    ));
    try {
      await run;
    } catch (e) {
      debugPrint('Backup before factory reset failed: $e');
      failed = true;
    }
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    return failed;
  }

  Future<bool> _ask(BuildContext context,
      {String? title, required String text}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: title == null ? null : Text(title),
        content: SingleChildScrollView(child: Text(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(kFactoryResetConfirmButton),
          ),
        ],
      ),
    );
    return ok == true;
  }

  /// Runs as an app restart (see `AppRootState.factoryReset`), so the app
  /// comes back like a first run with no state carried over.
  static Future<void> _doReset(BuildContext context) =>
      AppRoot.of(context).factoryReset();
}
