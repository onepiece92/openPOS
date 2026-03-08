import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(title: const Text('Categories')),
      body: categoriesAsync.when(
        data: (cats) => cats.isEmpty
            ? _EmptyState(onAdd: () => _showForm(context, ref, null))
            : ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: cats.length,
                onReorder: (oldIndex, newIndex) =>
                    _reorder(ref, cats, oldIndex, newIndex),
                itemBuilder: (_, i) {
                  final c = cats[i];
                  return ListTile(
                    key: ValueKey(c.id),
                    leading: const Icon(Icons.drag_handle_rounded),
                    title: Text(c.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showForm(context, ref, c),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => _confirmDelete(context, ref, c),
                        ),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref, null),
        child: const Icon(Icons.add_rounded),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined, size: 64,
              color: cs.onSurfaceVariant.withAlpha(80)),
          const SizedBox(height: 16),
          Text('No categories yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Category'),
          ),
        ],
      ),
    );
  }
}
