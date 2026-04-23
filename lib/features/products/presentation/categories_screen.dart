import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/widgets/app_empty_state.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

// ── Palette cycled by category id ─────────────────────────────────────────────
const _palette = [
  Color(0xFF6750A4), // purple
  Color(0xFF0077B6), // blue
  Color(0xFF2D9CDB), // sky
  Color(0xFF00897B), // teal
  Color(0xFF388E3C), // green
  Color(0xFFD4860B), // amber
  Color(0xFFE64A19), // deep orange
  Color(0xFFAD1457), // pink
];

Color _colorFor(int id) => _palette[id % _palette.length];

// ─────────────────────────────────────────────────────────────────────────────

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          categoriesAsync.maybeWhen(
            data: (cats) => cats.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton.icon(
                      onPressed: () => _showForm(context, ref, null),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add'),
                    ),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (cats) => cats.isEmpty
            ? AppEmptyState(
                icon: Icons.category_rounded,
                title: 'No categories yet',
                subtitle: 'Group your products for faster searching.',
                action: FilledButton.icon(
                  onPressed: () => _showForm(context, ref, null),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Category'),
                ),
              )
            : ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: cats.length,
                proxyDecorator: (child, index, animation) => Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(14),
                  child: child,
                ),
                onReorder: (oldIndex, newIndex) =>
                    _reorder(ref, cats, oldIndex, newIndex),
                itemBuilder: (_, i) => _CategoryCard(
                  key: ValueKey(cats[i].id),
                  category: cats[i],
                  onEdit: () => _showForm(context, ref, cats[i]),
                  onDelete: () => _confirmDelete(context, ref, cats[i]),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: categoriesAsync.maybeWhen(
        data: (cats) => cats.isEmpty
            ? null
            : FloatingActionButton(
                onPressed: () => _showForm(context, ref, null),
                child: const Icon(Icons.add_rounded),
              ),
        orElse: () => null,
      ),
    );
  }

  Future<void> _reorder(
    WidgetRef ref,
    List<Category> cats,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex--;
    final db = ref.read(databaseProvider);
    final reordered = [...cats];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    for (var i = 0; i < reordered.length; i++) {
      await db.productsDao.upsertCategory(
        CategoriesCompanion(
          id: Value(reordered[i].id),
          sortOrder: Value(i),
        ),
      );
    }
  }

  void _showForm(BuildContext context, WidgetRef ref, Category? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              existing == null ? 'New Category' : 'Edit Category',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Category name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(ctx, ref, existing, nameCtrl.text),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => _save(ctx, ref, existing, nameCtrl.text),
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    Category? existing,
    String name,
  ) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final db = ref.read(databaseProvider);
    await db.productsDao.upsertCategory(
      CategoriesCompanion.insert(
        name: trimmed,
        id: existing != null ? Value(existing.id) : const Value.absent(),
      ),
    );
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category cat,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          '"${cat.name}" will be removed. Products in this category will become uncategorised.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(databaseProvider).productsDao.deleteCategory(cat.id);
    }
  }
}

// ─── Category card ─────────────────────────────────────────────────────────────

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final productsAsync = ref.watch(productsByCategoryProvider(category.id));
    final count = productsAsync.valueOrNull?.length ?? 0;
    final color = _colorFor(category.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              category.name.isNotEmpty
                  ? category.name[0].toUpperCase()
                  : '?',
              style: tt.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        title: Text(
          category.name,
          style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          count == 1 ? '1 product' : '$count products',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: cs.onSurfaceVariant, size: 20),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline_rounded,
                        color: Theme.of(context).colorScheme.error),
                    title: Text('Delete',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const Icon(Icons.drag_handle_rounded, size: 20),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

