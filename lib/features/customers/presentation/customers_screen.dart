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

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _search = '';
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Customer> _filter(List<Customer> all) {
    if (_search.isEmpty) return all;
    final q = _search.toLowerCase();
    return all
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              (c.phone?.toLowerCase().contains(q) ?? false) ||
              (c.email?.toLowerCase().contains(q) ?? false),
        )
        .toList();
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
                  hintText: 'Search customers...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _search = v),
              )
            : const Text('Customers'),
        actions: [
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
          final filtered = _filter(all);

          if (all.isEmpty) {
            return _EmptyState(onAdd: () => _openForm());
          }

          if (filtered.isEmpty) {
            return Center(
              child: Text(
                'No customers match your search.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (_, i) => _CustomerTile(
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

// ── Customer tile ─────────────────────────────────────────────────────────────

class _CustomerTile extends ConsumerWidget {
  const _CustomerTile({required this.customer, required this.onEdit});
  final Customer customer;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final selectedId = ref.watch(cartSessionProvider).customerId;
    final isSelected = selectedId == customer.id;

    void select() {
      ref
          .read(cartSessionProvider.notifier)
          .setCustomer(isSelected ? null : customer.id);
      if (!isSelected) context.go('/pos');
    }

    return ListTile(
      onTap: select,
      leading: RadioGroup<int?>(
        groupValue: selectedId,
        onChanged: (_) => select(),
        child: Radio<int?>(
          value: customer.id,
          toggleable: true,
        ),
      ),
      title: Text(customer.name, style: tt.bodyLarge),
      subtitle: Text(
        [
          if (customer.phone != null) customer.phone!,
          if (customer.email != null) customer.email!,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (customer.defaultDiscount > 0)
            _DiscountBadge(customer: customer, cs: cs, tt: tt),
          if (customer.defaultDiscount > 0 && customer.loyaltyPoints > 0)
            const SizedBox(width: 6),
          if (customer.loyaltyPoints > 0)
            _LoyaltyBadge(points: customer.loyaltyPoints, cs: cs, tt: tt),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18, color: cs.onSurfaceVariant),
            onPressed: onEdit,
            tooltip: 'Edit',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({
    required this.customer,
    required this.cs,
    required this.tt,
  });
  final Customer customer;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final label = customer.defaultDiscountIsPercent
        ? '${customer.defaultDiscount.toStringAsFixed(customer.defaultDiscount % 1 == 0 ? 0 : 1)}% off'
        : '${customer.defaultDiscount.toStringAsFixed(0)} off';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_rounded, size: 13, color: cs.onErrorContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoyaltyBadge extends StatelessWidget {
  const _LoyaltyBadge({
    required this.points,
    required this.cs,
    required this.tt,
  });
  final int points;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, size: 14, color: cs.onTertiaryContainer),
          const SizedBox(width: 4),
          Text(
            '$points pts',
            style: tt.labelSmall?.copyWith(
              color: cs.onTertiaryContainer,
              fontWeight: FontWeight.bold,
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
  late final _nameCtrl = TextEditingController(text: widget.customer?.name ?? '');
  late final _phoneCtrl = TextEditingController(text: widget.customer?.phone ?? '');
  late final _emailCtrl = TextEditingController(text: widget.customer?.email ?? '');
  late final _addressCtrl = TextEditingController(text: widget.customer?.address ?? '');
  late bool _discountIsPercent = widget.customer?.defaultDiscountIsPercent ?? false;
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
    final entry = CustomersCompanion(
      id: _isEdit ? Value(widget.customer!.id) : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      phone: Value(_phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim()),
      email: Value(_emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim()),
      address: Value(_addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim()),
      defaultDiscount: Value(discountVal),
      defaultDiscountIsPercent: Value(_discountIsPercent),
    );
    await db.customersDao.upsert(entry);
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
        content: const Text('This will permanently remove the customer profile.'),
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
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit Customer' : 'New Customer',
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

            // Name
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

            // Phone
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))],
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            // Email
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
                final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim());
                return ok ? null : 'Enter a valid email';
              },
            ),
            const SizedBox(height: 14),

            // Address
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

            // Default discount
            Text(
              'Default Discount',
              style: Theme.of(context).textTheme.labelLarge,
            ),
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
          Icon(
            Icons.people_outline_rounded,
            size: 72,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text('No customers yet', style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(
            'Add your first customer to get started.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
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
