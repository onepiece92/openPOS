import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/utils/async_feedback.dart';

class CustomerForm extends ConsumerStatefulWidget {
  const CustomerForm({super.key, this.customer});
  final Customer? customer;

  @override
  ConsumerState<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<CustomerForm> {
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
    final saved = await withErrorSnackbar(
      context,
      () => db.customersDao.upsert(CustomersCompanion(
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
      )),
      failurePrefix: 'Save failed',
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (saved != null) Navigator.pop(context);
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
