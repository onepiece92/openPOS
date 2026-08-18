import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/providers/hive_provider.dart';

// ── Printer ───────────────────────────────────────────────────────────────────

class PrinterSection extends ConsumerWidget {
  const PrinterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(printerDeviceNameProvider);
    final paper = ref.watch(printerPaperWidthProvider);
    final subtitle = name == null
        ? 'No printer paired · ${paper}mm'
        : '$name · ${paper}mm';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.print_outlined),
        title: const Text('Thermal Printer'),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push('/settings/printer'),
      ),
    );
  }
}
