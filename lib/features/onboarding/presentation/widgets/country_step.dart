import 'package:flutter/material.dart';

import 'package:pos_app/features/onboarding/domain/country_default.dart';

class CountryStep extends StatelessWidget {
  const CountryStep({
    super.key,
    required this.countries,
    required this.loading,
    required this.selected,
    required this.searchController,
    required this.onSearch,
    required this.onSelect,
  });

  final List<CountryDefault> countries;
  final bool loading;
  final CountryDefault? selected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<CountryDefault> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where are you located?',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Sets your currency, timezone, and default tax.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            searchController.clear();
                            onSearch('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: countries.length,
                  itemBuilder: (context, i) {
                    final c = countries[i];
                    final isSelected = selected?.code == c.code;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: cs.primaryContainer.withAlpha(80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? cs.primary
                            : cs.surfaceContainerHighest,
                        child: Text(
                          c.code,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? cs.onPrimary
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      title: Text(
                        c.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${c.currency} (${c.symbol})  •  ${c.taxName} ${c.taxRate}%',
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: cs.primary)
                          : null,
                      onTap: () => onSelect(c),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Step 2: Tax ──────────────────────────────────────────────────────────────
