import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/utils/async_feedback.dart';
import 'package:pos_app/features/cart/domain/cart_notifier.dart';
import 'package:pos_app/features/cart/domain/held_orders_notifier.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';
import 'package:pos_app/features/tables/domain/tables_provider.dart';

class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesStreamProvider);
    final occupied = ref.watch(occupiedTableIdsProvider);
    final cartTableId = ref.watch(cartSessionProvider).tableId;
    final heldByTable = <int, String>{
      for (final t in ref.watch(activeHeldOrdersProvider))
        if (t.tableId != null) t.tableId!: t.customerName ?? t.label,
    };

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(title: const Text('Tables')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add table'),
      ),
      body: tablesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tables) {
          if (tables.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.table_restaurant_outlined,
                        size: 72,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text('No tables yet',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text(
                      'Add tables to track who is seated where during service.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _openForm(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add your first table'),
                    ),
                  ],
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: tables.length,
            itemBuilder: (_, i) {
              final t = tables[i];
              final isOccupied = occupied.contains(t.id);
              final occupant = heldByTable[t.id];
              return _TableCard(
                table: t,
                isOccupied: isOccupied,
                occupantLabel: occupant,
                isCurrentCartTable: t.id == cartTableId,
                onTap: () => _assignToCart(
                  context,
                  ref,
                  table: t,
                  isCurrentCart: t.id == cartTableId,
                  occupant: occupant,
                ),
                onEdit: () => _openForm(context, ref, existing: t),
                onDelete: () => _confirmDelete(context, ref, t),
              );
            },
          );
        },
      ),
    );
  }

  // ── Tap → assign + redirect to POS ───────────────────────────────────────

  void _assignToCart(
    BuildContext context,
    WidgetRef ref, {
    required PosTable table,
    required bool isCurrentCart,
    required String? occupant,
  }) {
    if (isCurrentCart) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${table.name} is already on this ticket')),
      );
      return;
    }
    ref.read(cartSessionProvider.notifier).setTable(table.id);
    final msg = occupant == null
        ? '${table.name} assigned'
        : '${table.name} reassigned (was on ticket for $occupant)';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
    context.go('/pos');
  }

  // ── Add / Edit form ──────────────────────────────────────────────────────

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    PosTable? existing,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _TableForm(existing: existing),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, PosTable table) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${table.name}?'),
        content: const Text(
          'This removes the table from the floor list. Past orders that '
          'referenced it keep their record.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
                foregroundColor: Theme.of(ctx).colorScheme.onError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final db = ref.read(databaseProvider);
    await withErrorSnackbar(
      context,
      () async {
        await db.tablesDao.deleteById(table.id);
        return true;
      },
      failurePrefix: 'Delete failed',
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.table,
    required this.isOccupied,
    required this.occupantLabel,
    required this.isCurrentCartTable,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final PosTable table;
  final bool isOccupied;
  final String? occupantLabel;
  final bool isCurrentCartTable;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final accent = isOccupied ? cs.error : cs.primary;
    final borderColor =
        isCurrentCartTable ? cs.primary : accent.withValues(alpha: 0.30);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: borderColor,
            width: isCurrentCartTable ? 1.6 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: status chip + 3-dot menu
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(Icons.table_restaurant_rounded, color: accent),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isOccupied ? 'Occupied' : 'Free',
                        style: tt.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<_TableAction>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: cs.onSurfaceVariant),
                    tooltip: 'Table actions',
                    onSelected: (a) {
                      switch (a) {
                        case _TableAction.edit:
                          onEdit();
                        case _TableAction.delete:
                          onDelete();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: _TableAction.edit,
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: _TableAction.delete,
                        child: ListTile(
                          leading: Icon(Icons.delete_outline_rounded,
                              color: cs.error),
                          title: Text('Delete',
                              style: TextStyle(color: cs.error)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                table.name,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people_alt_outlined,
                      size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${table.capacity} seats',
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
              if (occupantLabel != null) ...[
                const SizedBox(height: 6),
                Text(
                  occupantLabel!,
                  style: tt.bodySmall?.copyWith(color: accent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _TableAction { edit, delete }

// ─── Form ─────────────────────────────────────────────────────────────────────

class _TableForm extends ConsumerStatefulWidget {
  const _TableForm({this.existing});
  final PosTable? existing;

  @override
  ConsumerState<_TableForm> createState() => _TableFormState();
}

class _TableFormState extends ConsumerState<_TableForm> {
  final _nameCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '4');
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _capacityCtrl.text = e.capacity.toString();
      _notesCtrl.text = e.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _capacityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    final capacity = int.tryParse(_capacityCtrl.text.trim()) ?? 4;
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final ok = await withErrorSnackbar(
      context,
      () async {
        await db.tablesDao.upsert(
          TablesCompanion(
            id: widget.existing?.id != null
                ? Value(widget.existing!.id)
                : const Value.absent(),
            name: Value(name),
            capacity: Value(capacity),
            notes: Value(_notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim()),
            updatedAt: Value(DateTime.now()),
          ),
        );
        return true;
      },
      failurePrefix: 'Save failed',
    );
    if (mounted) setState(() => _saving = false);
    if (ok == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isEdit ? 'Edit Table' : 'Add Table',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: !isEdit,
            decoration: const InputDecoration(
              labelText: 'Name / number',
              hintText: 'T1, Window 4, Patio 2…',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _capacityCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Seats',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Save changes' : 'Add table'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
