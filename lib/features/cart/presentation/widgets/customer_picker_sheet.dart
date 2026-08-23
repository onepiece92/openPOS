import 'package:flutter/material.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/shared/widgets/customer_avatar.dart';

// ─── Customer picker sheet ────────────────────────────────────────────────────

class CustomerPickerSheet extends StatefulWidget {
  const CustomerPickerSheet({super.key, 
    required this.customers,
    required this.selectedId,
    required this.onSelect,
  });
  final List<Customer> customers;
  final int? selectedId;
  final ValueChanged<Customer> onSelect;

  @override
  State<CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<CustomerPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _search.isEmpty
        ? widget.customers
        : widget.customers
            .where((c) =>
                c.name.toLowerCase().contains(_search.toLowerCase()) ||
                (c.phone?.toLowerCase().contains(_search.toLowerCase()) ??
                    false))
            .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search customers...',
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
        Flexible(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final c = filtered[i];
              final selected = c.id == widget.selectedId;
              return ListTile(
                leading: CustomerAvatar(name: c.name),
                title: Text(c.name),
                subtitle: c.phone != null ? Text(c.phone!) : null,
                trailing: selected
                    ? Icon(Icons.check_circle_rounded, color: cs.primary)
                    : null,
                onTap: () {
                  widget.onSelect(c);
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
