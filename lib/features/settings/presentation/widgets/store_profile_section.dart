import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/providers/hive_provider.dart';

// ── Store Profile ─────────────────────────────────────────────────────────────

class StoreProfileSection extends ConsumerWidget {
  const StoreProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(businessNameProvider);
    final tagline = ref.watch(businessTaglineProvider);
    final phone = ref.watch(businessPhoneProvider);
    final address = ref.watch(businessAddressProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/settings/profile'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Business name not set' : name,
                      style: tt.titleMedium?.copyWith(
                        color: name.isEmpty ? cs.onSurfaceVariant : null,
                        fontStyle: name.isEmpty ? FontStyle.italic : null,
                      ),
                    ),
                    if (tagline.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(tagline,
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (phone.isNotEmpty)
                          _ProfileTag(
                              icon: Icons.phone_outlined,
                              text: phone,
                              cs: cs,
                              tt: tt),
                        if (address.isNotEmpty)
                          _ProfileTag(
                              icon: Icons.location_on_outlined,
                              text: address,
                              cs: cs,
                              tt: tt),
                        if (phone.isEmpty && address.isEmpty)
                          Text(
                            'Phone & address not set',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.55),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.edit_outlined,
                  size: 18, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTag extends StatelessWidget {
  const _ProfileTag(
      {required this.icon,
      required this.text,
      required this.cs,
      required this.tt});
  final IconData icon;
  final String text;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      );
}
