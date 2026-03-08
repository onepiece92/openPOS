import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

class TaxSettingsScreen extends ConsumerWidget {
  const TaxSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxAsync = ref.watch(taxRatesStreamProvider);
    final defaultTaxId = ref.watch(defaultTaxIdProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(title: const Text('Tax Rates')),
      body: taxAsync.when(
        data: (rates) => rates.isEmpty
            ? _TaxEmptyState(onAdd: () => _showForm(context, ref, null))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: rates.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                itemBuilder: (_, i) {
                  final t = rates[i];
                  final isDefault = t.id == defaultTaxId;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isDefault ? cs.primary : cs.surfaceContainerHighest,
                      child: Text(
                        '${(t.rate * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDefault ? cs.onPrimary : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(t.name),
                        if (isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Default',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: cs.onPrimaryContainer),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '${t.inclusionType == 'inclusive' ? 'Inclusive' : 'Exclusive'}'
                      ' · ${t.roundingMode.replaceAll('_', ' ')}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _showForm(context, ref, t);
                        if (v == 'default') _setDefault(ref, t.id);
                        if (v == 'deactivate') _toggleActive(ref, t);
                      },
                      itemBuilder: (_) => [
                        if (!isDefault)
                          const PopupMenuItem(
                            value: 'default',
                            child: ListTile(
                              leading: Icon(Icons.star_rounded),
                              title: Text('Set as default'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'deactivate',
                          child: ListTile(
                            leading: const Icon(Icons.toggle_off_outlined),
                            title: Text(t.isActive ? 'Deactivate' : 'Activate'),
                            contentPadding: EdgeInsets.zero,
                          ),
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

  void _setDefault(WidgetRef ref, int taxId) async {
    final box = ref.read(settingsBoxProvider);
    await saveDefaultTaxId(box, taxId);
  }

  void _toggleActive(WidgetRef ref, TaxRate t) async {
    await ref.read(databaseProvider).taxDao.upsertRate(
          TaxRatesCompanion(
            id: Value(t.id),
            isActive: Value(!t.isActive),
          ),
        );
  }

  void _showForm(BuildContext context, WidgetRef ref, TaxRate? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TaxForm(existing: existing),
    );
  }
}

class _TaxForm extends ConsumerStatefulWidget {
  const _TaxForm({this.existing});
  final TaxRate? existing;

  @override
  ConsumerState<_TaxForm> createState() => _TaxFormState();
}

class _TaxFormState extends ConsumerState<_TaxForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
  late final _rateCtrl = TextEditingController(
    text: widget.existing != null
        ? (widget.existing!.rate * 100).toStringAsFixed(2)
        : '',
  );
  late String _inclusionType =
      widget.existing?.inclusionType ?? 'exclusive';
  late String _roundingMode =
      widget.existing?.roundingMode ?? 'half_up';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final rate = double.parse(_rateCtrl.text) / 100.0;
    final db = ref.read(databaseProvider);
    await db.taxDao.upsertRate(
      TaxRatesCompanion.insert(
        name: _nameCtrl.text.trim(),
        rate: rate,
        inclusionType: Value(_inclusionType),
        roundingMode: Value(_roundingMode),
        id: widget.existing != null
            ? Value(widget.existing!.id)
            : const Value.absent(),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              widget.existing == null ? 'New Tax Rate' : 'Edit Tax Rate',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Tax name (e.g. VAT, GST)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _rateCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Rate (%)',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _inclusionType,
              decoration: const InputDecoration(
                labelText: 'Inclusion type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'exclusive', child: Text('Exclusive (added on top)')),
                DropdownMenuItem(
                    value: 'inclusive',
                    child: Text('Inclusive (embedded in price)')),
              ],
              onChanged: (v) => setState(() => _inclusionType = v!),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _roundingMode,
              decoration: const InputDecoration(
                labelText: 'Rounding mode',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'half_up', child: Text('Half up')),
                DropdownMenuItem(value: 'half_even', child: Text('Half even (banker\'s)')),
                DropdownMenuItem(value: 'truncate', child: Text('Truncate')),
              ],
              onChanged: (v) => setState(() => _roundingMode = v!),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Text(widget.existing == null ? 'Add Rate' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaxEmptyState extends StatelessWidget {
  const _TaxEmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.percent_rounded, size: 64,
              color: cs.onSurfaceVariant.withAlpha(80)),
          const SizedBox(height: 16),
          Text('No tax rates yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Tax Rate'),
          ),
        ],
      ),
    );
  }
}
