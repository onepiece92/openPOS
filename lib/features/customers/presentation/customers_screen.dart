import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/cart/domain/cart_notifier.dart';
import 'package:pos_app/features/customers/domain/customers_provider.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';


class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

enum _SortBy { nameAsc, nameDesc, newest, oldest, loyaltyDesc }

extension _SortByLabel on _SortBy {
  String get label => switch (this) {
        _SortBy.nameAsc => 'Name A–Z',
        _SortBy.nameDesc => 'Name Z–A',
        _SortBy.newest => 'Newest first',
        _SortBy.oldest => 'Oldest first',
        _SortBy.loyaltyDesc => 'Most loyalty points',
      };
  IconData get icon => switch (this) {
        _SortBy.nameAsc => Icons.sort_by_alpha_rounded,
        _SortBy.nameDesc => Icons.sort_by_alpha_rounded,
        _SortBy.newest => Icons.arrow_downward_rounded,
        _SortBy.oldest => Icons.arrow_upward_rounded,
        _SortBy.loyaltyDesc => Icons.stars_rounded,
      };
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _search = '';
  bool _showSearch = false;
  _SortBy _sortBy = _SortBy.nameAsc;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Customer> _filterAndSort(List<Customer> all) {
    var list = _search.isEmpty
        ? [...all]
        : all
            .where((c) =>
                c.name.toLowerCase().contains(_search.toLowerCase()) ||
                (c.phone?.toLowerCase().contains(_search.toLowerCase()) ??
                    false) ||
                (c.email?.toLowerCase().contains(_search.toLowerCase()) ??
                    false))
            .toList();
    switch (_sortBy) {
      case _SortBy.nameAsc:
        list.sort((a, b) => a.name.compareTo(b.name));
      case _SortBy.nameDesc:
        list.sort((a, b) => b.name.compareTo(a.name));
      case _SortBy.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortBy.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _SortBy.loyaltyDesc:
        list.sort((a, b) => b.loyaltyPoints.compareTo(a.loyaltyPoints));
    }
    return list;
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sort by',
                    style: Theme.of(ctx).textTheme.titleMedium),
              ),
            ),
            for (final option in _SortBy.values)
              ListTile(
                leading: Icon(option.icon),
                title: Text(option.label),
                trailing: _sortBy == option
                    ? Icon(Icons.check_rounded,
                        color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() => _sortBy = option);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openForm({Customer? customer}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CustomerForm(customer: customer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search customers…',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _search = v),
              )
            : const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            onPressed: _showSortSheet,
          ),
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
            ),
            tooltip: _showSearch ? 'Close search' : 'Search',
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _search = '';
                _searchCtrl.clear();
              }
            }),
          ),
        ],
      ),
      body: customersAsync.when(
        data: (all) {
          if (all.isEmpty) return _EmptyState(onAdd: () => _openForm());

          final filtered = _filterAndSort(all);
          if (filtered.isEmpty) {
            return Center(
              child: Text(
                'No customers match your search.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _CustomerCard(
              customer: filtered[i],
              onEdit: () => _openForm(customer: filtered[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Customer'),
      ),
    );
  }
}

// ── Customer card ─────────────────────────────────────────────────────────────

class _CustomerCard extends ConsumerWidget {
  const _CustomerCard({required this.customer, required this.onEdit});
  final Customer customer;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final selectedId = ref.watch(cartSessionProvider).customerId;
    final isSelected = selectedId == customer.id;
    void toggle() {
      final notifier = ref.read(cartSessionProvider.notifier);
      if (isSelected) {
        notifier.setCustomer(null);
        notifier.setOrderDiscount(0, isPercent: false);
      } else {
        notifier.setCustomer(customer.id);
        if (customer.defaultDiscount > 0) {
          notifier.setOrderDiscount(
            customer.defaultDiscount,
            isPercent: customer.defaultDiscountIsPercent,
          );
        }
        context.go('/pos');
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isSelected ? cs.primaryContainer : null,
      child: InkWell(
        onTap: toggle,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              // ── Radio ───────────────────────────────────────────────────
              RadioGroup<int?>(
                groupValue: selectedId,
                onChanged: (_) => toggle(),
                child: Radio<int?>(
                  value: customer.id,
                  toggleable: true,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 14),

              // ── Info ────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? cs.onPrimaryContainer : null,
                      ),
                    ),
                    if (customer.phone != null || customer.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (customer.phone != null) customer.phone!,
                          if (customer.email != null) customer.email!,
                        ].join('  ·  '),
                        style: tt.bodySmall?.copyWith(
                          color: isSelected
                              ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                              : cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // ── Badges ──────────────────────────────────────────
                    if (customer.defaultDiscount > 0 ||
                        customer.loyaltyPoints > 0 ||
                        customer.isTaxExempt) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (customer.defaultDiscount > 0)
                            _Badge(
                              icon: Icons.local_offer_rounded,
                              label: customer.defaultDiscountIsPercent
                                  ? '${customer.defaultDiscount.toStringAsFixed(customer.defaultDiscount % 1 == 0 ? 0 : 1)}% off'
                                  : '${customer.defaultDiscount.toStringAsFixed(0)} off',
                              bg: cs.errorContainer,
                              fg: cs.onErrorContainer,
                            ),
                          if (customer.loyaltyPoints > 0)
                            _Badge(
                              icon: Icons.stars_rounded,
                              label: '${customer.loyaltyPoints} pts',
                              bg: cs.tertiaryContainer,
                              fg: cs.onTertiaryContainer,
                            ),
                          if (customer.isTaxExempt)
                            _Badge(
                              icon: Icons.receipt_long_outlined,
                              label: 'Tax exempt',
                              bg: cs.secondaryContainer,
                              fg: cs.onSecondaryContainer,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ── Edit ────────────────────────────────────────────────────
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 18,
                    color: isSelected
                        ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                        : cs.onSurfaceVariant),
                onPressed: onEdit,
                tooltip: 'Edit',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge chip ────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Customer form (bottom sheet) ──────────────────────────────────────────────

class _CustomerForm extends ConsumerStatefulWidget {
  const _CustomerForm({this.customer});
  final Customer? customer;

  @override
  ConsumerState<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<_CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl =
      TextEditingController(text: widget.customer?.name ?? '');
  late final _phoneCtrl =
      TextEditingController(text: widget.customer?.phone ?? '');
  late final _emailCtrl =
      TextEditingController(text: widget.customer?.email ?? '');
  late final _addressCtrl =
      TextEditingController(text: widget.customer?.address ?? '');
  late bool _discountIsPercent =
      widget.customer?.defaultDiscountIsPercent ?? false;
  late final _discountCtrl = TextEditingController(
    text: (widget.customer?.defaultDiscount ?? 0) > 0
        ? widget.customer!.defaultDiscount.toStringAsFixed(
            widget.customer!.defaultDiscountIsPercent ? 1 : 2)
        : '',
  );
  bool _loading = false;

  bool get _isEdit => widget.customer != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final db = ref.read(databaseProvider);
    final discountVal = double.tryParse(_discountCtrl.text) ?? 0.0;
    await db.customersDao.upsert(CustomersCompanion(
      id: _isEdit ? Value(widget.customer!.id) : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      phone: Value(
          _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim()),
      email: Value(
          _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim()),
      address: Value(
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim()),
      defaultDiscount: Value(discountVal),
      defaultDiscountIsPercent: Value(_discountIsPercent),
    ));
    if (mounted) {
      setState(() => _loading = false);
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete customer?'),
        content:
            const Text('This will permanently remove the customer profile.'),
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
      final db = ref.read(databaseProvider);
      await (db.delete(db.customers)
            ..where((c) => c.id.equals(widget.customer!.id)))
          .go();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit Customer' : 'New Customer',
                      style: tt.titleLarge,
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
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))
                ],
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())
                      ? null
                      : 'Enter a valid email';
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text('Default Discount', style: tt.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Flat amount')),
                  ButtonSegment(value: true, label: Text('Percentage (%)')),
                ],
                selected: {_discountIsPercent},
                onSelectionChanged: (s) => setState(() {
                  _discountIsPercent = s.first;
                  _discountCtrl.clear();
                }),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _discountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _discountIsPercent
                      ? 'Discount percentage'
                      : 'Discount amount',
                  hintText: '0',
                  suffixText: _discountIsPercent ? '%' : null,
                  prefixIcon: const Icon(Icons.local_offer_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v);
                  if (n == null || n < 0) return 'Enter a valid number';
                  if (_discountIsPercent && n > 100) return 'Max 100%';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Save Changes' : 'Add Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.people_rounded,
                size: 40, color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: 20),
          Text('No customers yet',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Add customers to track loyalty and apply discounts.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }
}
