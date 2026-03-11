import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

/// Pass [productId] for edit mode; omit (null) for add mode.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});
  final int? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

// Simple holder for a component being edited in-memory before save.
class _ComponentEntry {
  _ComponentEntry({required this.product, required this.quantity});
  final Product product;
  int quantity;
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(); // empty = unlimited (saves as 0)

  int? _categoryId;
  bool _isTaxable = true;
  bool _isComposite = false;
  bool _isHiddenInPos = false;
  bool _loading = false;
  bool _initialised = false;

  final List<_ComponentEntry> _components = [];

  bool get _isEdit => widget.productId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isEdit && !_initialised) _loadProduct();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    _initialised = true;
    final db = ref.read(databaseProvider);
    final p = await db.productsDao.getById(widget.productId!);
    if (p != null && mounted) {
      setState(() {
        _nameCtrl.text = p.name;
        _skuCtrl.text = p.sku;
        _priceCtrl.text = p.price.toStringAsFixed(2);
        // Show empty when 0 (= unlimited); show actual value when > 0
        _stockCtrl.text =
            p.stockQuantity > 0 ? p.stockQuantity.toString() : '';
        _categoryId = p.categoryId;
        _isTaxable = p.isTaxable;
        _isComposite = p.isComposite;
        _isHiddenInPos = p.isHiddenInPos;
      });
      if (p.isComposite) await _loadComponents(db);
    }
  }

  Future<void> _loadComponents(AppDatabase db) async {
    final rows = await db.productsDao.getComponents(widget.productId!);
    final entries = <_ComponentEntry>[];
    for (final row in rows) {
      final prod = await db.productsDao.getById(row.componentProductId);
      if (prod != null) {
        entries.add(_ComponentEntry(product: prod, quantity: row.quantity));
      }
    }
    if (mounted) {
      setState(() => _components
        ..clear()
        ..addAll(entries));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isComposite && _components.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one component')),
      );
      return;
    }
    setState(() => _loading = true);

    try {
      final db = ref.read(databaseProvider);
      final sku = _skuCtrl.text.trim().isEmpty
          ? const Uuid().v4().substring(0, 8).toUpperCase()
          : _skuCtrl.text.trim();
      final stockQty =
          _isComposite ? 0 : (int.tryParse(_stockCtrl.text) ?? 0);

      int compositeId;
      if (_isEdit) {
        // Targeted update — doesn't touch isActive, imagePath, createdAt
        await db.productsDao.updateProduct(
          widget.productId!,
          ProductsCompanion(
            name: Value(_nameCtrl.text.trim()),
            sku: Value(sku),
            price: Value(double.parse(_priceCtrl.text)),
            categoryId: Value(_categoryId),
            isTaxable: Value(_isTaxable),
            isComposite: Value(_isComposite),
            isHiddenInPos: Value(_isHiddenInPos),
          ),
        );
        // Set stock via direct SQL to guarantee it's written
        if (!_isComposite) {
          await db.productsDao.setStock(widget.productId!, stockQty);
        }
        compositeId = widget.productId!;
      } else {
        final savedId = await db.productsDao.upsert(
          ProductsCompanion.insert(
            name: _nameCtrl.text.trim(),
            sku: sku,
            price: double.parse(_priceCtrl.text),
            stockQuantity: Value(stockQty),
            categoryId: Value(_categoryId),
            isTaxable: Value(_isTaxable),
            isComposite: Value(_isComposite),
            isHiddenInPos: Value(_isHiddenInPos),
          ),
        );
        compositeId = savedId;
      }

      if (_isComposite) {
        await db.productsDao.replaceComponents(
          compositeId,
          _components
              .map((c) => ProductComponentsCompanion.insert(
                    compositeProductId: compositeId,
                    componentProductId: c.product.id,
                    quantity: Value(c.quantity),
                  ))
              .toList(),
        );
      } else {
        await db.productsDao.replaceComponents(compositeId, []);
      }

      if (mounted) {
        setState(() => _loading = false);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete product?'),
        content: const Text(
          'This product will be hidden from the catalog. Past order history is preserved.',
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
    if (confirm == true && mounted) {
      await ref.read(databaseProvider).productsDao.softDelete(widget.productId!);
      if (mounted) context.pop();
    }
  }

  Future<void> _pickComponent() async {
    final allProducts = await ref.read(databaseProvider).productsDao.watchAll().first;
    // Exclude composites and already-added products (and self)
    final eligible = allProducts.where((p) =>
        !p.isComposite &&
        p.id != widget.productId &&
        !_components.any((c) => c.product.id == p.id)).toList();

    if (!mounted) return;
    final picked = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ComponentPickerSheet(products: eligible),
    );
    if (picked == null) return;

    // Ask for quantity
    final qtyCtrl = TextEditingController(text: '1');
    final qty = await showDialog<int>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Qty of "${picked.name}"'),
        content: TextField(
          controller: qtyCtrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Quantity per bundle',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(qtyCtrl.text) ?? 1),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (qty != null && qty > 0) {
      setState(() => _components.add(
            _ComponentEntry(product: picked, quantity: qty),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'New Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // ── Basic info ────────────────────────────────────────────────
            _sectionLabel('Basic Info', tt, cs),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Product name *',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _skuCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'SKU / Barcode',
                        hintText: 'Auto-generated if blank',
                        prefixIcon: Icon(Icons.qr_code_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    categoriesAsync.when(
                      data: (cats) => DropdownButtonFormField<int?>(
                        initialValue: _categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_rounded),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('No category')),
                          ...cats.map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Pricing ───────────────────────────────────────────────────
            _sectionLabel('Pricing', tt, cs),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Selling price *',
                        prefixIcon: Icon(Icons.sell_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Price is required';
                        if (double.tryParse(v) == null) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      title: const Text('Apply tax'),
                      subtitle: const Text(
                          'Include this product in tax calculations'),
                      value: _isTaxable,
                      onChanged: (v) => setState(() => _isTaxable = v),
                      contentPadding: const EdgeInsets.only(left: 4),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Inventory ────────────────────────────────────────────────
            _sectionLabel('Inventory', tt, cs),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _stockCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: _isEdit ? 'Stock quantity' : 'Opening stock',
                    hintText: 'Leave blank for unlimited',
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Visibility ───────────────────────────────────────────────
            _sectionLabel('Visibility', tt, cs),
            Card(
              child: SwitchListTile(
                title: const Text('Hide in POS'),
                subtitle: const Text(
                    'Product won\'t appear on the POS screen (still usable as a bundle component)'),
                value: _isHiddenInPos,
                onChanged: (v) => setState(() => _isHiddenInPos = v),
                secondary: const Icon(Icons.visibility_off_outlined),
              ),
            ),

            const SizedBox(height: 20),

            // ── Composite / Bundle ────────────────────────────────────────
            _sectionLabel('Bundle', tt, cs),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Composite / Bundle'),
                    subtitle: const Text(
                        'Made up of other products — stock tracked via components'),
                    value: _isComposite,
                    onChanged: (v) => setState(() => _isComposite = v),
                  ),
                  if (_isComposite) ...[
                    const Divider(height: 1, indent: 16),
                    if (_components.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No components added yet.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ..._components.asMap().entries.map((entry) {
                      final i = entry.key;
                      final c = entry.value;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          child: Text(
                            c.product.name[0].toUpperCase(),
                            style: TextStyle(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(c.product.name),
                        subtitle: Text('SKU: ${c.product.sku}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_rounded, size: 18),
                              onPressed: c.quantity > 1
                                  ? () => setState(() => c.quantity--)
                                  : null,
                            ),
                            Text('${c.quantity}', style: tt.titleSmall),
                            IconButton(
                              icon: const Icon(Icons.add_rounded, size: 18),
                              onPressed: () => setState(() => c.quantity++),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded,
                                  color: cs.error, size: 20),
                              onPressed: () =>
                                  setState(() => _components.removeAt(i)),
                            ),
                          ],
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: OutlinedButton.icon(
                        onPressed: _pickComponent,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add component'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Danger zone ───────────────────────────────────────────────
            if (_isEdit) ...[
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete Product'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _save,
              style: AppTheme.ctaButtonStyle(cs),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Save Changes' : 'Add Product'),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Component picker sheet ───────────────────────────────────────────────────

class _ComponentPickerSheet extends StatefulWidget {
  const _ComponentPickerSheet({required this.products});
  final List<Product> products;

  @override
  State<_ComponentPickerSheet> createState() => _ComponentPickerSheetState();
}

class _ComponentPickerSheetState extends State<_ComponentPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _search.isEmpty
        ? widget.products
        : widget.products
            .where((p) =>
                p.name.toLowerCase().contains(_search.toLowerCase()) ||
                p.sku.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('No products',
                        style: TextStyle(color: cs.onSurfaceVariant)))
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text('SKU: ${p.sku}'),
                        trailing: Text(
                          'Qty: ${p.stockQuantity}',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

Widget _sectionLabel(String text, TextTheme tt, ColorScheme cs) => Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: tt.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
