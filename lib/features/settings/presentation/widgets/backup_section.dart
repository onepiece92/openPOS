import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


// ── Backup & Restore ──────────────────────────────────────────────────────────

class BackupSection extends StatelessWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.backup_outlined),
        title: const Text('Backup & Restore'),
        subtitle: const Text('Export or import data via CSV'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push('/settings/backup'),
      ),
    );
  }
}
