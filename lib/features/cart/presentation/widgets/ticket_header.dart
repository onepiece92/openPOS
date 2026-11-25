import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/shared/widgets/app_sheet.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/customers/domain/customers_provider.dart';
import 'package:pos_app/features/cart/presentation/widgets/customer_picker_sheet.dart';
import 'package:pos_app/features/cart/presentation/widgets/table_selector.dart';
import 'package:pos_app/features/usage/usage_providers.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';

// ─── Ticket header ─────────────────────────────────────────────────────────────

class TicketHeader extends ConsumerWidget {
  const TicketHeader({super.key, required this.session});
  final CartSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    // Each optional row is its own widget behind its switch: with the
    // feature off it is never built, so its stream never starts.
    final customersOn = ref.watch(featureOnProvider(Feature.customers));
    final tablesOn = ref.watch(featureOnProvider(Feature.tables));
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
          if (customersOn) ...[
            const SizedBox(height: 10),
            _CustomerRow(session: session),
          ],
          if (tablesOn) ...[
            const SizedBox(height: 8),
            TableSelectorRow(session: session),
          ],
        ],
      ),
    );
  }
}

/// The customer row of the ticket. Only built while Customers is on: it is
/// the one widget on the sell screen that watches the customer list.
class _CustomerRow extends ConsumerWidget {
  const _CustomerRow({required this.session});
  final CartSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final customers = ref.watch(customersStreamProvider).valueOrNull ?? [];
    final selectedCustomer = customers.cast<Customer?>().firstWhere(
          (c) => c?.id == session.customerId,
          orElse: () => null,
        );
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: customers.isEmpty
          ? null
          : () => _pickCustomer(context, ref, customers, session.customerId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
              color:
                  selectedCustomer != null ? cs.primary : cs.onSurfaceVariant,
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
    );
  }

  void _pickCustomer(BuildContext context, WidgetRef ref,
      List<Customer> customers, int? currentId) {
    showAppSheet(
      context: context,
      draggable: true,
      initialSize: 0.5,
      builder: (_) => CustomerPickerSheet(
        customers: customers,
        selectedId: currentId,
        onSelect: (c) {
          ref.read(usageCounterProvider).record(UsageEvent.customerAddedToSale);
          ref.read(cartSessionProvider.notifier).setCustomer(c.id);
          // A customer's default discount needs Discounts on too.
          if (c.defaultDiscount > 0 &&
              ref.read(featureOnProvider(Feature.discounts))) {
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
