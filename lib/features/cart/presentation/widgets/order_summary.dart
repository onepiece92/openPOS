import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/theme/tokens.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/shared/widgets/app_sheet.dart';
import 'package:pos_app/shared/widgets/summary_row.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/cart/presentation/widgets/discount_sheet.dart';

// ─── Order summary ─────────────────────────────────────────────────────────────

class OrderSummary extends ConsumerWidget {
  const OrderSummary({super.key, required this.summary, required this.fmt});
  final CartSummary summary;
  final CurrencyFormatter fmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final session = ref.watch(cartSessionProvider);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          SummaryRow(
            label: 'Subtotal',
            value: fmt.format(summary.subtotal),
          ),
          const SizedBox(height: 6),
          // ── Discount row ─────────────────────────────────────────────
          _TappableRow(
            label: summary.orderDiscount > 0
                ? 'Discount${session.orderDiscountIsPercent ? ' (${session.orderDiscount.toStringAsFixed(1)}%)' : ''}'
                : '+ Add Discount',
            value: summary.orderDiscount > 0
                ? '− ${fmt.format(summary.orderDiscount)}'
                : null,
            valueColor: cs.error,
            addColor: cs.primary,
            tt: tt,
            cs: cs,
            onTap: () => _showDiscountSheet(context, ref, session, summary.subtotal),
          ),
          const SizedBox(height: 6),
          // ── Tax rows (one per selected rate) ─────────────────────────
          ...summary.taxLines.map((line) {
            final label =
                '${line.name} (${(line.rate * 100).toStringAsFixed(1)}%'
                '${line.isInclusive ? ', incl.' : ''})';
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: tt.bodyMedium?.copyWith(
                        color: session.taxEnabled
                            ? cs.onSurfaceVariant
                            : cs.onSurfaceVariant.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  Text(
                    fmt.format(line.amount),
                    style: tt.bodyMedium?.copyWith(
                      color: session.taxEnabled
                          ? cs.onSurfaceVariant
                          : cs.onSurfaceVariant.withValues(alpha: 0.45),
                      decoration: session.taxEnabled
                          ? null
                          : TextDecoration.lineThrough,
                      fontFamily: AppFonts.mono,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => ref
                        .read(selectedTaxRatesProvider.notifier)
                        .remove(line.taxRateId),
                    child: Icon(Icons.close_rounded,
                        size: 14, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: session.taxEnabled,
                      onChanged: (v) => ref
                          .read(cartSessionProvider.notifier)
                          .setTaxEnabled(v),
                    ),
                  ),
                ],
              ),
            );
          }),
          // ── Add Tax button ────────────────────────────────────────────
          _TappableRow(
            label: '+ Add Tax',
            value: null,
            addColor: cs.primary,
            tt: tt,
            cs: cs,
            onTap: () => _showTaxPicker(context, ref),
          ),
          const Divider(height: 16),
          SummaryRow(
            label: 'Total',
            value: fmt.format(summary.total),
            emphasis: SummaryEmphasis.bold,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showTaxPicker(BuildContext context, WidgetRef ref) {
    showAppSheet(
      context: context,
      draggable: true,
      initialSize: 0.4,
      builder: (_) => _TaxPickerSheet(ref: ref),
    );
  }

  void _showDiscountSheet(BuildContext context, WidgetRef ref,
      CartSession session, double subtotal) {
    showAppSheet(
      context: context,
      builder: (_) => DiscountSheet(
        currentDiscount: session.orderDiscount,
        isPercent: session.orderDiscountIsPercent,
        subtotal: subtotal,
        onApply: (amount, isPercent) =>
            ref.read(cartSessionProvider.notifier)
                .setOrderDiscount(amount, isPercent: isPercent),
      ),
    );
  }
}

// ─── Tax picker sheet ─────────────────────────────────────────────────────────

class _TaxPickerSheet extends ConsumerWidget {
  const _TaxPickerSheet({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef innerRef) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final allRatesAsync = innerRef.watch(taxRatesStreamProvider);
    final selectedIds = innerRef.watch(selectedTaxRatesProvider);
    final allRates = allRatesAsync.valueOrNull ?? [];

    return Column(
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('Select Tax Rates', style: tt.titleMedium),
        ),
        Expanded(
          child: allRates.isEmpty
              ? Center(
                  child: Text('No tax rates configured',
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                )
              : ListView.builder(
                  itemCount: allRates.length,
                  itemBuilder: (_, i) {
                    final rate = allRates[i];
                    final selected = selectedIds.contains(rate.id);
                    final label =
                        '${rate.name} (${(rate.rate * 100).toStringAsFixed(1)}%'
                        '${rate.inclusionType == 'inclusive' ? ', incl.' : ''})';
                    return CheckboxListTile(
                      value: selected,
                      title: Text(label),
                      onChanged: (v) {
                        final notifier = innerRef
                            .read(selectedTaxRatesProvider.notifier);
                        if (v == true) {
                          notifier.add(rate.id);
                        } else {
                          notifier.remove(rate.id);
                        }
                      },
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: SizedBox(
            height: 44,
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ),
      ],
    );
  }
}

class _TappableRow extends StatelessWidget {
  const _TappableRow({
    required this.label,
    required this.tt,
    required this.cs,
    required this.onTap,
    this.value,
    this.valueColor,
    this.addColor,
  });
  final String label;
  final String? value;
  final Color? valueColor;
  final Color? addColor;
  final TextTheme tt;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAdd = value == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          Text(
            label,
            style: tt.bodyMedium?.copyWith(
              color: isAdd ? (addColor ?? cs.primary) : cs.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (value != null)
            Text(
              value!,
              style: tt.bodyMedium?.copyWith(
                color: valueColor ?? cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(width: 4),
          Icon(Icons.edit_rounded, size: 14,
              color: isAdd ? addColor : cs.onSurfaceVariant),
        ],
      ),
    );
  }
}
