import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/presentation/backup_screen.dart';

// ── Backup & Restore ──────────────────────────────────────────────────────────

/// "Daily · last backup <time> · keeps 7", "Daily · no backup yet" or "Off".
String autoBackupRowSubtitle({required bool enabled, DateTime? lastAt}) {
  if (!enabled) return 'Off';
  if (lastAt == null) return 'Daily · no backup yet';
  return 'Daily · last backup ${autoBackupTimeText(lastAt)} · '
      'keeps $kAutoBackupKeep';
}

class BackupSection extends StatelessWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup & Restore'),
            subtitle: const Text(
                'Back up everything, restore, or export and import CSV files'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/settings/backup'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const AutoBackupRow(),
        ],
      ),
    );
  }
}

/// "Automatic backups": the same switch as the Backup screen's device
/// backups tile (one setting, so the two always agree). Tapping the row
/// opens the list of device backups.
class AutoBackupRow extends ConsumerWidget {
  const AutoBackupRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final enabled = ref.watch(autoBackupEnabledProvider);
    final lastAt = ref.watch(autoBackupLastAtProvider);
    final subtitle = autoBackupRowSubtitle(enabled: enabled, lastAt: lastAt);
    return Semantics(
      button: true,
      label: 'Automatic backups. Opens the list of device backups',
      child: ListTile(
        key: const ValueKey('settings-auto-backups'),
        minTileHeight: 56,
        leading: const Icon(Icons.history_toggle_off_rounded),
        title: const Text('Automatic backups'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(subtitle),
            ValueListenableBuilder<String?>(
              valueListenable: autoBackupLastError,
              builder: (context, err, _) => err == null
                  ? const SizedBox.shrink()
                  : Text(
                      'Last auto-backup failed: $err',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(color: cs.error),
                    ),
            ),
          ],
        ),
        trailing: Semantics(
          label: 'Automatic backups switch',
          child: Switch(
            value: enabled,
            onChanged: (v) => setAutoBackups(ref, v),
          ),
        ),
        onTap: () => context.push(
            '/settings/backup?show=$kShowDeviceBackupsQuery'),
      ),
    );
  }
}
