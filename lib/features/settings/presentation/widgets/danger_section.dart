import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/app_root.dart';
import 'package:pos_app/features/settings/data/factory_reset.dart';

// ── Danger Zone ───────────────────────────────────────────────────────────────

class DangerSection extends ConsumerWidget {
  const DangerSection({super.key});

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

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Factory Reset?'),
        content: const Text(kFactoryResetConfirmText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _doReset(context, ref);
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  /// Runs as an app restart (see `AppRootState.factoryReset`), so the app
  /// comes back like a first run with no state carried over.
  Future<void> _doReset(BuildContext context, WidgetRef ref) =>
      AppRoot.of(context).factoryReset();
}
