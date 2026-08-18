import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/shared/widgets/app_sheet.dart';

// ── Appearance ────────────────────────────────────────────────────────────────

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final label = switch (themeMode) {
      ThemeMode.dark => 'Dark',
      ThemeMode.light => 'Light',
      _ => 'System default',
    };

    final icon = switch (themeMode) {
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      _ => Icons.brightness_auto_rounded,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: const Text('Theme'),
        subtitle: Text(label),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _showThemePicker(context, ref, themeMode),
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    showAppSheet(
      context: context,
      builder: (_) => _ThemePickerSheet(current: current),
    );
  }
}

// ── Theme picker sheet ────────────────────────────────────────────────────────

class _ThemePickerSheet extends ConsumerWidget {
  const _ThemePickerSheet({required this.current});
  final ThemeMode current;

  static const _options = [
    (ThemeMode.system, 'System default', Icons.brightness_auto_rounded),
    (ThemeMode.light, 'Light', Icons.light_mode_rounded),
    (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text('Theme', style: Theme.of(context).textTheme.titleLarge),
        ),
        ..._options.map((item) {
          final (mode, label, icon) = item;
          return ListTile(
            leading: Icon(icon),
            title: Text(label),
            trailing: current == mode
                ? Icon(Icons.check_rounded, color: cs.primary)
                : null,
            onTap: () async {
              await ref.read(settingsProvider.notifier).setThemeMode(mode);
              if (context.mounted) Navigator.pop(context);
            },
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
