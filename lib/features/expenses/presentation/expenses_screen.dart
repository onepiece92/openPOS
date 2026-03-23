import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(databaseProvider).expensesDao.watchAll();
});

final _expenseCategoriesStreamProvider =
    StreamProvider<List<ExpenseCategory>>((ref) {
  return ref.watch(databaseProvider).expensesDao.watchCategories();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  int? _selectedCategoryId; // null = All

  void _openForm({Expense? expense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ExpenseForm(expense: expense),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(_expensesStreamProvider);
    final categoriesAsync = ref.watch(_expenseCategoriesStreamProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(title: const Text('Expenses')),
      body: Column(
        children: [
          // Category filter chips
          categoriesAsync.when(
            data: (cats) => _CategoryChips(
              categories: cats,
              selected: _selectedCategoryId,
              onSelect: (id) => setState(() => _selectedCategoryId = id),
            ),
            loading: () => const SizedBox(height: 48),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // List
          Expanded(
            child: expensesAsync.when(
              data: (all) {
                final cats = categoriesAsync.valueOrNull ?? [];
                final catMap = {for (final c in cats) c.id: c};

                final filtered = _selectedCategoryId == null
                    ? all
                    : all
                        .where((e) => e.categoryId == _selectedCategoryId)
                        .toList();

                final total =
                    filtered.fold(0.0, (sum, e) => sum + e.amount);

                if (all.isEmpty) {
                  return _EmptyState(onAdd: () => _openForm());
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No expenses in this category.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  );
                }

                return Column(
                  children: [
                    _TotalBar(total: total, symbol: symbol, cs: cs),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (_, i) => _ExpenseTile(
                          expense: filtered[i],
                          category: catMap[filtered[i].categoryId],
                          symbol: symbol,
                          onTap: () => _openForm(expense: filtered[i]),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
    );
  }
}

// ── Category filter chips ──────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<ExpenseCategory> categories;
  final int? selected;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _Chip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          ...categories.map(
            (c) => _Chip(
              label: c.name,
              selected: selected == c.id,
              color: _parseColor(c.color),
              onTap: () => onSelect(c.id),
            ),
          ),
        ],
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final v = hex.replaceFirst('#', '');
      return Color(int.parse('FF$v', radix: 16));
    } catch (_) {
      return null;
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: color?.withValues(alpha: 0.2),
        side: selected && color != null
            ? BorderSide(color: color!)
            : null,
      ),
    );
  }
}

// ── Total bar ─────────────────────────────────────────────────────────────────

class _TotalBar extends StatelessWidget {
  const _TotalBar({
    required this.total,
    required this.symbol,
    required this.cs,
  });
  final double total;
  final String symbol;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: cs.surfaceContainerLow,
      child: Row(
        children: [
          Text(
            'Total',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const Spacer(),
          Text(
            '$symbol ${total.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: cs.error,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Expense tile ───────────────────────────────────────────────────────────────

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.symbol,
    required this.onTap,
    this.category,
  });

  final Expense expense;
  final ExpenseCategory? category;
  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateLabel =
        DateFormat('d MMM y').format(expense.date.toLocal());
    final catColor = _parseColor(category?.color) ?? cs.primary;
    final hasReceipt = expense.receiptImagePath != null &&
        File(expense.receiptImagePath!).existsSync();

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: catColor.withValues(alpha: 0.15),
        child: Icon(Icons.receipt_long_rounded, color: catColor, size: 20),
      ),
      title: Text(
        category?.name ?? 'Uncategorised',
        style: tt.bodyLarge,
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              [dateLabel, if (expense.notes != null) expense.notes!].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          if (hasReceipt) ...[
            const SizedBox(width: 4),
            Icon(Icons.photo_camera_rounded,
                size: 12, color: cs.onSurfaceVariant),
          ],
        ],
      ),
      trailing: Text(
        '$symbol ${expense.amount.toStringAsFixed(2)}',
        style: tt.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: cs.error,
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final v = hex.replaceFirst('#', '');
      return Color(int.parse('FF$v', radix: 16));
    } catch (_) {
      return null;
    }
  }
}

// ── Expense form ───────────────────────────────────────────────────────────────

class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm({this.expense});
  final Expense? expense;

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final _amountCtrl =
      TextEditingController(text: widget.expense?.amount.toStringAsFixed(2) ?? '');
  late final _notesCtrl =
      TextEditingController(text: widget.expense?.notes ?? '');
  late DateTime _date;
  late int? _categoryId;
  String? _imagePath;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _date = widget.expense?.date ?? DateTime.now();
    _categoryId = widget.expense?.categoryId;
    _imagePath = widget.expense?.receiptImagePath;
  }

  bool get _isEdit => widget.expense != null;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // ── Image helpers ─────────────────────────────────────────────────────────

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!kIsWeb) {
      final permission =
          source == ImageSource.camera ? Permission.camera : Permission.photos;
      final status = await permission.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${source == ImageSource.camera ? 'Camera' : 'Photo library'} permission denied'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: openAppSettings,
              ),
            ),
          );
        }
        return;
      }
    }
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 70, // ~70% JPEG quality — good balance for receipts
    );
    if (xFile == null || !mounted) return;

    // Copy to app documents so it persists if the picker temp file is cleared
    final dir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${dir.path}/receipts');
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    final destPath = '${receiptsDir.path}/${const Uuid().v4()}.jpg';
    await File(xFile.path).copy(destPath);

    // Delete previous image file if replacing
    if (_imagePath != null) {
      final old = File(_imagePath!);
      if (await old.exists()) await old.delete();
    }

    if (mounted) setState(() => _imagePath = destPath);
  }

  Future<void> _removeImage() async {
    if (_imagePath == null) return;
    final file = File(_imagePath!);
    if (await file.exists()) await file.delete();
    setState(() => _imagePath = null);
  }

  // ── Add category dialog ──────────────────────────────────────────────────

  Future<void> _showAddCategoryDialog() async {
    final nameCtrl = TextEditingController();
    final newId = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final db = ref.read(databaseProvider);
              final id = await db.expensesDao.insertCategory(
                ExpenseCategoriesCompanion(
                  name: Value(name),
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx, id);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    if (newId != null && mounted) {
      setState(() => _categoryId = newId);
    }
  }

  // ── Save / delete ─────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    setState(() => _loading = true);

    final db = ref.read(databaseProvider);
    final entry = ExpensesCompanion(
      id: _isEdit ? Value(widget.expense!.id) : const Value.absent(),
      amount: Value(double.parse(_amountCtrl.text)),
      date: Value(_date),
      categoryId: Value(_categoryId!),
      notes: Value(_notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim()),
      receiptImagePath: Value(_imagePath),
    );

    if (_isEdit) {
      await db.expensesDao.updateExpense(entry);
    } else {
      await db.expensesDao.insert(entry);
    }

    if (mounted) {
      setState(() => _loading = false);
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text('This will permanently remove this expense record.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            // foregroundColor inherited from filledButtonTheme via onPrimary
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      // Also delete the receipt image file
      if (_imagePath != null) {
        final file = File(_imagePath!);
        if (await file.exists()) await file.delete();
      }
      final db = ref.read(databaseProvider);
      await (db.delete(db.expenses)
            ..where((e) => e.id.equals(widget.expense!.id)))
          .go();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(_expenseCategoriesStreamProvider);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit Expense' : 'New Expense',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_isEdit)
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                    onPressed: _delete,
                    tooltip: 'Delete',
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Amount ───────────────────────────────────────────────────
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              autofocus: !_isEdit,
              decoration: const InputDecoration(
                labelText: 'Amount *',
                prefixIcon: Icon(Icons.attach_money_rounded),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Amount is required';
                if (double.tryParse(v) == null) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Category ─────────────────────────────────────────────────
            categoriesAsync.when(
              data: (cats) => DropdownButtonFormField<int>(
                key: ValueKey(_categoryId),
                initialValue: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                  border: OutlineInputBorder(),
                ),
                items: [
                  ...cats.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      )),
                  DropdownMenuItem(
                    value: -1,
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                        Text('Add new category',
                            style: TextStyle(color: cs.primary)),
                      ],
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v == -1) {
                    _showAddCategoryDialog();
                    return;
                  }
                  setState(() => _categoryId = v);
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),

            // ── Date ─────────────────────────────────────────────────────
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Date'),
              subtitle: Text(DateFormat('d MMM y').format(_date)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _pickDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: cs.outline),
              ),
            ),
            const SizedBox(height: 14),

            // ── Notes ────────────────────────────────────────────────────
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            // ── Receipt photo ────────────────────────────────────────────
            if (_imagePath != null && File(_imagePath!).existsSync())
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_imagePath!),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: cs.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 14, color: cs.onError),
                      ),
                    ),
                  ),
                ],
              )
            else
              // shape/textStyle/side inherited from outlinedButtonTheme
              OutlinedButton.icon(
                onPressed: _showImageSourceSheet,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add Receipt Photo'),
              ),
            const SizedBox(height: 24),

            // ── Save ─────────────────────────────────────────────────────
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _loading ? null : _save,
                style: AppTheme.ctaButtonStyle(cs),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Save Changes' : 'Add Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses yet',
            style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your business expenses here.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }
}
