import 'package:flutter/material.dart';

class InventoryFilterBar extends StatelessWidget {
  const InventoryFilterBar({super.key, 
    required this.total,
    required this.outCount,
    required this.lowCount,
    required this.selected,
    required this.onSelect,
  });

  final int total;
  final int outCount;
  final int lowCount;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        spacing: 8,
        children: [
          _Chip(
            label: 'All ($total)',
            selected: selected == null,
            color: cs.primary,
            onTap: () => onSelect(null),
          ),
          _Chip(
            label: 'Low ($lowCount)',
            selected: selected == 'low',
            color: const Color(0xFFD97706),
            onTap: () => onSelect(selected == 'low' ? null : 'low'),
          ),
          _Chip(
            label: 'Out ($outCount)',
            selected: selected == 'out',
            color: cs.error,
            onTap: () => onSelect(selected == 'out' ? null : 'out'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? color
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─── Inventory card ───────────────────────────────────────────────────────────
