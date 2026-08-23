import 'package:flutter/material.dart';

import 'package:pos_app/features/onboarding/domain/onboarding_state.dart';

class ConfirmStep extends StatelessWidget {
  const ConfirmStep({super.key, required this.state});
  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 44,
                color: cs.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'You\'re all set!',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s a summary of your store setup.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          _SummaryCard(
            children: [
              _SummaryRow(
                icon: Icons.storefront_rounded,
                label: 'Business',
                value: state.businessName,
              ),
              _SummaryRow(
                icon: Icons.location_on_rounded,
                label: 'Country',
                value: state.country?.name ?? '—',
              ),
              _SummaryRow(
                icon: Icons.currency_exchange_rounded,
                label: 'Currency',
                value: state.country != null
                    ? '${state.country!.currency} (${state.country!.symbol})'
                    : '—',
              ),
              _SummaryRow(
                icon: Icons.schedule_rounded,
                label: 'Timezone',
                value: state.country?.timezone ?? '—',
              ),
              _SummaryRow(
                icon: Icons.percent_rounded,
                label: state.taxName.isNotEmpty ? state.taxName : 'Tax',
                value: '${state.taxRate.toStringAsFixed(1)}%',
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'You can change these later in Settings.',
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 12),
              Text(
                label,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                value,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: cs.outlineVariant,
          ),
      ],
    );
  }
}
