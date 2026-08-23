import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/customers/presentation/widgets/customer_card.dart';
import 'package:pos_app/features/customers/presentation/widgets/customer_form.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/shared/widgets/app_empty_state.dart';
import 'package:pos_app/shared/widgets/app_sheet.dart';
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
    final list = _search.isEmpty
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
    showAppSheet(
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
    showAppSheet(
      context: context,
      builder: (_) => CustomerForm(customer: customer),
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
          if (all.isEmpty) {
            return AppEmptyState(
              icon: Icons.people_rounded,
              title: 'No customers yet',
              subtitle: 'Add customers to track loyalty and apply discounts.',
              action: FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Add Customer'),
              ),
            );
          }

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
            itemBuilder: (_, i) => CustomerCard(
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
