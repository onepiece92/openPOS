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
        onTap: () => _confirmReset(context),
      ),
    );
  }

  /// Step one is the tap on the tile, step two this dialog (as in 1.1.0).
  /// Whether automatic backups exist is checked as it opens: one listing of
  /// `backups/auto`.
  Future<void> _confirmReset(BuildContext context) async {
    var hasBackups = false;
    try {
      hasBackups =
          (await const SnapshotService().listLocal(await autoBackupDir()))
              .isNotEmpty;
    } catch (_) {/* unreadable: say there are none, the safe side */}
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(kFactoryResetTitle),
        content: SingleChildScrollView(
          child: Text(factoryResetConfirmText(hasAutoBackups: hasBackups)),
        ),
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
    if (confirmed != true || !context.mounted) return;
    await (onErase ?? _doReset)(context);
  }

  /// Runs as an app restart (see `AppRootState.factoryReset`), so the app
  /// comes back like a first run with no state carried over.
  static Future<void> _doReset(BuildContext context) =>
      AppRoot.of(context).factoryReset();
}
