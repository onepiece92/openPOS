import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/shared/widgets/app_sheet.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/tables/domain/tables_provider.dart';

// ─── Table selector + picker ─────────────────────────────────────────────────

class TableSelectorRow extends ConsumerWidget {
  const TableSelectorRow({super.key, required this.session});
  final CartSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tablesAsync = ref.watch(tablesStreamProvider);
    final tables = tablesAsync.valueOrNull ?? const <PosTable>[];
    final selectedTable = ref.watch(cartTableProvider);
    final occupied = ref.watch(occupiedTableIdsProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: tables.isEmpty
          ? null
          : () => _pickTable(context, ref, tables, occupied, session.tableId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.table_restaurant_rounded,
              size: 18,
              color: selectedTable != null ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedTable == null
                    ? (tables.isEmpty
                        ? 'No tables defined'
                        : 'Select table (optional)')
                    : '${selectedTable.name} · ${selectedTable.capacity} seats',
                style: tt.bodyMedium?.copyWith(
                  color: selectedTable != null
                      ? cs.onSurface
                      : cs.onSurfaceVariant,
                ),
              ),
            ),
            if (selectedTable != null)
              GestureDetector(
                onTap: () =>
                    ref.read(cartSessionProvider.notifier).setTable(null),
                child: Icon(Icons.close_rounded,
                    size: 16, color: cs.onSurfaceVariant),
              )
            else
              Icon(Icons.expand_more_rounded,
                  size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _pickTable(
    BuildContext context,
    WidgetRef ref,
    List<PosTable> tables,
    Set<int> occupied,
    int? currentId,
  ) {
    showAppSheet(
      context: context,
      draggable: true,
      initialSize: 0.55,
      minSize: 0.3,
      builder: (_) => _TablePickerSheet(
        tables: tables,
        occupied: occupied,
        selectedId: currentId,
        onSelect: (t) =>
            ref.read(cartSessionProvider.notifier).setTable(t.id),
      ),
    );
  }
}

class _TablePickerSheet extends StatelessWidget {
  const _TablePickerSheet({
    required this.tables,
    required this.occupied,
    required this.selectedId,
    required this.onSelect,
  });

  final List<PosTable> tables;
  final Set<int> occupied;
  final int? selectedId;
  final ValueChanged<PosTable> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: cs.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Select table', style: tt.titleMedium),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: tables.length,
                itemBuilder: (_, i) {
                  final t = tables[i];
                  final isOccupied =
                      occupied.contains(t.id) && t.id != selectedId;
                  return ListTile(
                    leading: Icon(
                      Icons.table_restaurant_rounded,
                      color: isOccupied ? cs.error : cs.primary,
                    ),
                    title: Text(t.name),
                    subtitle: Text(
                      isOccupied
                          ? '${t.capacity} seats · already on another ticket'
                          : '${t.capacity} seats',
                      style: TextStyle(
                        color: isOccupied
                            ? cs.error
                            : cs.onSurfaceVariant,
                      ),
                    ),
                    trailing: t.id == selectedId
                        ? Icon(Icons.check_circle_rounded, color: cs.primary)
                        : null,
                    onTap: () {
                      onSelect(t);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
      ],
    );
  }
}
