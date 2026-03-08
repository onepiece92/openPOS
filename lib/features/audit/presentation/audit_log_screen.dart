import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

final _auditLogsProvider = StreamProvider<List<AuditLogData>>((ref) {
  return ref.watch(databaseProvider).auditDao.watchRecent(limit: 200);
});

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(_auditLogsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateFmt = DateFormat('dd MMM yyyy  HH:mm');

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(title: const Text('Audit Log')),
      body: logsAsync.when(
        data: (logs) => logs.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 80 / 255)),
                    const SizedBox(height: 16),
                    Text('No audit events yet',
                        style: tt.titleMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: logs.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: cs.outlineVariant),
                itemBuilder: (_, i) {
                  final log = logs[i];
                  final actionColor = _actionColor(log.action, cs);
                  final meta = _parseMeta(log.metadata);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          actionColor.withValues(alpha: 0.12),
                      child: Icon(
                        _actionIcon(log.action),
                        size: 18,
                        color: actionColor,
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${_entityLabel(log.entityType)} '
                            '${log.entityId != null ? '#${log.entityId}' : ''}',
                            style: tt.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ActionChip(action: log.action, color: actionColor),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFmt.format(log.createdAt),
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        if (meta.isNotEmpty)
                          Text(
                            meta,
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    isThreeLine: meta.isNotEmpty,
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Color _actionColor(String action, ColorScheme cs) => switch (action) {
        'void' => cs.error,
        'refund' => cs.tertiary,
        'delete' => cs.error,
        'override' => cs.secondary,
        _ => cs.primary,
      };

  IconData _actionIcon(String action) => switch (action) {
        'void' => Icons.block_rounded,
        'refund' => Icons.undo_rounded,
        'delete' => Icons.delete_outline_rounded,
        'override' => Icons.edit_note_rounded,
        'create' => Icons.add_circle_outline_rounded,
        'update' => Icons.edit_outlined,
        _ => Icons.info_outline_rounded,
      };

  String _entityLabel(String entityType) => switch (entityType) {
        'order' => 'Order',
        'product' => 'Product',
        'setting' => 'Setting',
        'tax_rate' => 'Tax Rate',
        'tax_override' => 'Tax Override',
        'expense' => 'Expense',
        'stock' => 'Stock',
        'customer' => 'Customer',
        _ => entityType,
      };

  String _parseMeta(String? raw) {
    if (raw == null) return '';
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.entries.map((e) => '${e.key}: ${e.value}').join('  ·  ');
    } catch (_) {
      return raw;
    }
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.action, required this.color});
  final String action;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          action.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      );
}
