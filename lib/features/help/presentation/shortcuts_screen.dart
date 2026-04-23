import 'package:flutter/material.dart';

import 'package:pos_app/core/theme/tokens.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

class ShortcutsScreen extends StatelessWidget {
  const ShortcutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(title: const Text('Shortcuts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Navigation', tt, cs),
          _ShortcutRow(keys: const ['⌘', 'H'], label: 'Home', tt: tt, cs: cs),
          _ShortcutRow(
              keys: const ['⌘', 'P'],
              label: 'Open product page',
              tt: tt,
              cs: cs),
          _ShortcutRow(keys: const ['⌘', 'O'], label: 'Orders', tt: tt, cs: cs),
          _ShortcutRow(
              keys: const ['⌘', 'U'], label: 'Customers', tt: tt, cs: cs),
          _ShortcutRow(
              keys: const ['⌘', 'E'], label: 'Expenses', tt: tt, cs: cs),
          _ShortcutRow(
              keys: const ['⌘', 'I'], label: 'Inventory', tt: tt, cs: cs),
          _ShortcutRow(
              keys: const ['⌘', ','], label: 'Settings', tt: tt, cs: cs),
          const SizedBox(height: 20),
          _SectionHeader('POS / Cart', tt, cs),
          _ShortcutRow(
              keys: const ['⌘', 'F'], label: 'Focus search', tt: tt, cs: cs),
          _ShortcutRow(
              keys: const ['Esc'], label: 'Clear search', tt: tt, cs: cs),
          _ShortcutRow(
              keys: const ['⌘', 'Enter'], label: 'Checkout', tt: tt, cs: cs),
          _ShortcutRow(
              keys: const ['⌘', 'K'], label: 'Clear cart', tt: tt, cs: cs),
          _ShortcutRow(
              keys: const ['⌘', 'G'],
              label: 'Toggle grid / list',
              tt: tt,
              cs: cs),
          const SizedBox(height: 20),
          _SectionHeader('Products', tt, cs),
          _ShortcutRow(
              keys: const ['⌘', 'N'], label: 'New product', tt: tt, cs: cs),
          const SizedBox(height: 20),
          _SectionHeader('General', tt, cs),
          _ShortcutRow(
              keys: const ['⌘', 'W'], label: 'Close / Back', tt: tt, cs: cs),
          _ShortcutRow(
              keys: const ['⌘', 'S'], label: 'Keyboard Shortcuts', tt: tt, cs: cs),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Keyboard shortcuts are available on desktop and web builds.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, this.tt, this.cs);
  final String text;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          text.toUpperCase(),
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      );
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.keys,
    required this.label,
    required this.tt,
    required this.cs,
  });
  final List<String> keys;
  final String label;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: tt.bodyMedium),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: keys.map((k) => _KeyChip(k, cs, tt)).toList(),
            ),
          ],
        ),
      );
}

class _KeyChip extends StatelessWidget {
  const _KeyChip(this.key_, this.cs, this.tt);
  final String key_;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Text(
          key_,
          style: tt.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontFamily: AppFonts.mono,
          ),
        ),
      );
}
