import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/core/widgets/customer_avatar.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/cart_notifier.dart';
import 'package:pos_app/features/customers/domain/customers_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

class CartDetailScreen extends ConsumerWidget {
  const CartDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final summary = ref.watch(cartSummaryProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final session = ref.watch(cartSessionProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(cart.isEmpty
            ? 'Cart'
            : 'Cart (${cart.fold(0, (s, i) => s + i.quantity)})'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: const Text('Clear'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 72,
                      color: cs.onSurfaceVariant.withAlpha(80)),
                  const SizedBox(height: 16),
                  Text('Your cart is empty',
                      style: tt.titleMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => context.pop(),
                    child: const Text('Browse Products'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _TicketHeader(session: session),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _CartLineItem(
                      item: cart[i],
                      currencySymbol: symbol,
                    ),
                  ),
                ),
                _OrderSummary(summary: summary, currencySymbol: symbol),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.push('/payment'),
                    style: AppTheme.ctaButtonStyle(cs),
                    child: Text(
                      'Checkout  •  $symbol ${summary.total.toStringAsFixed(2)}',
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ─── Ticket header ─────────────────────────────────────────────────────────────

class _TicketHeader extends ConsumerWidget {
  const _TicketHeader({required this.session});
  final CartSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final customersAsync = ref.watch(customersStreamProvider);
    final customers = customersAsync.valueOrNull ?? [];
    final selectedCustomer = customers.cast<Customer?>().firstWhere(
          (c) => c?.id == session.customerId,
          orElse: () => null,
        );
    final dateFmt = DateFormat('dd MMM yyyy  HH:mm');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        children: [
          // ── Ticket number + date ──────────────────────────────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session.ticketNumber,
                  style: tt.labelLarge?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.access_time_rounded,
                  size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                dateFmt.format(session.openedAt),
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Customer selector ─────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: customers.isEmpty
                ? null
                : () => _pickCustomer(context, ref, customers, session.customerId),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedCustomer != null
                        ? Icons.person_rounded
                        : Icons.person_add_alt_1_rounded,
                    size: 18,
                    color: selectedCustomer != null
                        ? cs.primary
                        : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedCustomer?.name ?? 'Select customer (optional)',
                      style: tt.bodyMedium?.copyWith(
                        color: selectedCustomer != null
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (selectedCustomer != null)
                    GestureDetector(
                      onTap: () {
                        final n = ref.read(cartSessionProvider.notifier);
                        n.setCustomer(null);
                        n.setOrderDiscount(0, isPercent: false);
                      },
                      child: Icon(Icons.close_rounded,
                          size: 16, color: cs.onSurfaceVariant),
                    )
                  else
                    Icon(Icons.expand_more_rounded,
                        size: 18, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickCustomer(BuildContext context, WidgetRef ref,
      List<Customer> customers, int? currentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CustomerPickerSheet(
        customers: customers,
        selectedId: currentId,
        onSelect: (c) {
          ref.read(cartSessionProvider.notifier).setCustomer(c.id);
          if (c.defaultDiscount > 0) {
            ref.read(cartSessionProvider.notifier).setOrderDiscount(
                  c.defaultDiscount,
                  isPercent: c.defaultDiscountIsPercent,
                );
          }
        },
      ),
    );
  }
}

// ─── Customer picker sheet ────────────────────────────────────────────────────

class _CustomerPickerSheet extends StatefulWidget {
  const _CustomerPickerSheet({
    required this.customers,
    required this.selectedId,
    required this.onSelect,
  });
  final List<Customer> customers;
  final int? selectedId;
  final ValueChanged<Customer> onSelect;

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
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

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (ctx, scrollCtrl) => Column(
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
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
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
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cart line item ────────────────────────────────────────────────────────────

class _CartLineItem extends ConsumerWidget {
  const _CartLineItem({required this.item, required this.currencySymbol});
  final CartItem item;
  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final notifier = ref.read(cartProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${item.unitPrice.toStringAsFixed(2)} each',
                  style: tt.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Qty stepper
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove_rounded,
                onPressed: () => notifier.setQuantity(
                    item.productId, item.quantity - 1),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${item.quantity}',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                onPressed: () => notifier.setQuantity(
                    item.productId, item.quantity + 1),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Line total
          SizedBox(
            width: 72,
            child: Text(
              item.lineSubtotal.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: tt.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          // Delete
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: cs.error),
            onPressed: () => notifier.remove(item.productId),
            iconSize: 20,
            padding: const EdgeInsets.only(left: 4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

// ─── Order summary ─────────────────────────────────────────────────────────────

class _OrderSummary extends ConsumerWidget {
  const _OrderSummary(
      {required this.summary, required this.currencySymbol});
  final CartSummary summary;
  final String currencySymbol;

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
          _SummaryRow(
            label: 'Subtotal',
            value: '$currencySymbol ${summary.subtotal.toStringAsFixed(2)}',
            tt: tt,
            cs: cs,
          ),
          const SizedBox(height: 6),
          // ── Discount row ─────────────────────────────────────────────
          _TappableRow(
            label: summary.orderDiscount > 0
                ? 'Discount${session.orderDiscountIsPercent ? ' (${session.orderDiscount.toStringAsFixed(1)}%)' : ''}'
                : '+ Add Discount',
            value: summary.orderDiscount > 0
                ? '− $currencySymbol ${summary.orderDiscount.toStringAsFixed(2)}'
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
                    '$currencySymbol ${line.amount.toStringAsFixed(2)}',
                    style: tt.bodyMedium?.copyWith(
                      color: session.taxEnabled
                          ? cs.onSurfaceVariant
                          : cs.onSurfaceVariant.withValues(alpha: 0.45),
                      decoration: session.taxEnabled
                          ? null
                          : TextDecoration.lineThrough,
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
          _SummaryRow(
            label: 'Total',
            value: '$currencySymbol ${summary.total.toStringAsFixed(2)}',
            tt: tt,
            cs: cs,
            bold: true,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showTaxPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TaxPickerSheet(ref: ref),
    );
  }

  void _showDiscountSheet(BuildContext context, WidgetRef ref,
      CartSession session, double subtotal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DiscountSheet(
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

// ─── Discount sheet ───────────────────────────────────────────────────────────

class _DiscountSheet extends StatefulWidget {
  const _DiscountSheet({
    required this.currentDiscount,
    required this.isPercent,
    required this.subtotal,
    required this.onApply,
  });
  final double currentDiscount;
  final bool isPercent;
  final double subtotal;
  final void Function(double amount, bool isPercent) onApply;

  @override
  State<_DiscountSheet> createState() => _DiscountSheetState();
}

class _DiscountSheetState extends State<_DiscountSheet> {
  late bool _isPercent;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _isPercent = widget.isPercent;
    _ctrl = TextEditingController(
      text: widget.currentDiscount > 0
          ? widget.currentDiscount.toStringAsFixed(
              widget.isPercent ? 1 : 2)
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _parsed => double.tryParse(_ctrl.text) ?? 0.0;

  double get _preview {
    if (_isPercent) return widget.subtotal * (_parsed / 100);
    return _parsed.clamp(0.0, widget.subtotal);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Order Discount', style: tt.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Flat amount')),
              ButtonSegment(value: true, label: Text('Percentage (%)')),
            ],
            selected: {_isPercent},
            onSelectionChanged: (s) => setState(() {
              _isPercent = s.first;
              _ctrl.clear();
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _isPercent ? 'Discount %' : 'Discount amount',
              suffixText: _isPercent ? '%' : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_parsed > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text('Discount applied:',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  const Spacer(),
                  Text(
                    '− ${_preview.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: cs.error),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              if (widget.currentDiscount > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onApply(0, false);
                      Navigator.pop(context);
                    },
                    child: const Text('Remove'),
                  ),
                ),
              if (widget.currentDiscount > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _parsed <= 0
                      ? null
                      : () {
                          widget.onApply(_parsed, _isPercent);
                          Navigator.pop(context);
                        },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
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

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.4,
      maxChildSize: 0.7,
      builder: (ctx, scrollCtrl) => Column(
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
                    controller: scrollCtrl,
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
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ),
          ),
        ],
      ),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.tt,
    required this.cs,
    this.bold = false,
  });
  final String label;
  final String value;
  final TextTheme tt;
  final ColorScheme cs;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant);
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value,
            style: style?.copyWith(
                color: bold ? cs.primary : null,
                fontWeight: bold ? FontWeight.bold : null)),
      ],
    );
  }
}
