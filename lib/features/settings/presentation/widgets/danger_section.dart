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
  /// [deleteBackups] is the answer to the backups question.
  @visibleForTesting
  final Future<void> Function(BuildContext context, bool deleteBackups)?
      onErase;

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

  /// Step one is the tap on the tile, step two this dialog (as in 1.1.0),
  /// which also asks whether the backups on the device are kept (the
  /// default) or deleted too; deleting them takes one more confirm. The
  /// automatic backups are listed as it opens (one listing of
  /// `backups/auto`). Keeping them: one backup is taken first when the
  /// shop has data; if that fails the user is asked again. Deleting them:
  /// no backup is taken (it would be deleted with the rest).
  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    DateTime? latest;
    var willBackUp = false;
    try {
      final files =
          await const SnapshotService().listLocal(await autoBackupDir());
      if (files.isNotEmpty) latest = await files.first.lastModified();
    } catch (_) {/* unreadable: say there are none, the safe side */}
    try {
      willBackUp = await ref.read(preResetBackupNeededProvider)();
    } catch (_) {/* then the text promises no backup */}
    if (!context.mounted) return;
    final deleteBackups = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _ResetDialog(latestBackup: latest, willBackUp: willBackUp),
    );
    if (deleteBackups == null || !context.mounted) return;

    if (deleteBackups) {
      final sure = await _ask(context,
          title: kResetDeleteBackupsConfirmTitle,
          text: kResetDeleteBackupsMeans,
          confirm: kResetDeleteBackupsConfirmButton);
      if (!sure || !context.mounted) return;
    } else {
      final backupFailed = await _backupFirst(context, ref);
      if (!context.mounted) return;
      if (backupFailed &&
          !(await _ask(context, text: kBackupFirstFailed) && context.mounted)) {
        return;
      }
    }
    await (onErase ?? _doReset)(context, deleteBackups);
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
      {String? title,
      required String text,
      String confirm = kFactoryResetConfirmButton}) async {
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
            child: Text(confirm),
          ),
        ],
      ),
    );
    return ok == true;
  }

  /// Runs as an app restart (see `AppRootState.factoryReset`), so the app
  /// comes back like a first run with no state carried over.
  static Future<void> _doReset(BuildContext context, bool deleteBackups) =>
      AppRoot.of(context).factoryReset(deleteBackups: deleteBackups);
}

/// The reset's confirm dialog: what goes, the backups question (keep is
/// preselected) and Erase everything. Pops `false` (keep), `true` (delete
/// the backups too) or null (Cancel).
class _ResetDialog extends StatefulWidget {
  const _ResetDialog({required this.latestBackup, required this.willBackUp});
  final DateTime? latestBackup;
  final bool willBackUp;

  @override
  State<_ResetDialog> createState() => _ResetDialogState();
}

class _ResetDialogState extends State<_ResetDialog> {
  bool _deleteBackups = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    // Keeping them: exactly the text as before. Deleting them: nothing is
    // kept or saved first, so only what goes and the latest backup.
    final text = _deleteBackups
        ? '$kFactoryResetBody\n\n${latestBackupLine(widget.latestBackup)}'
        : factoryResetConfirmText(
            latestBackup: widget.latestBackup, willBackUp: widget.willBackUp);
    return AlertDialog(
      title: const Text(kFactoryResetTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text),
            const SizedBox(height: 16),
            Text(kResetBackupsQuestion, style: tt.titleSmall),
            RadioGroup<bool>(
              groupValue: _deleteBackups,
              onChanged: (v) => setState(() => _deleteBackups = v ?? false),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<bool>(
                    key: ValueKey('reset-keep-backups'),
                    value: false,
                    contentPadding: EdgeInsets.zero,
                    title: Text(kResetKeepBackups),
                    subtitle: Text(kResetKeepBackupsMeans),
                  ),
                  RadioListTile<bool>(
                    key: ValueKey('reset-delete-backups'),
                    value: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(kResetDeleteBackups),
                    subtitle: Text(kResetDeleteBackupsMeans),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
          ),
          onPressed: () => Navigator.pop(context, _deleteBackups),
          child: const Text(kFactoryResetConfirmButton),
        ),
      ],
    );
  }
}
