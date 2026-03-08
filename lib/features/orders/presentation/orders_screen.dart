import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

final _recentOrdersProvider = StreamProvider<List<Order>>((ref) {
  return ref.watch(databaseProvider).ordersDao.watchRecent(limit: 500);
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_recentOrdersProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateFmt = DateFormat('dd MMM yyyy  HH:mm');

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(title: const Text('Order History')),
      body: ordersAsync.when(
        data: (orders) => orders.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 80 / 255)),
                    const SizedBox(height: 16),
                    Text('No orders yet',
                        style: tt.titleMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: orders.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: cs.outlineVariant),
                itemBuilder: (_, i) {
                  final o = orders[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _statusColor(o.status, cs).withValues(alpha:0.12),
                      child: Icon(
                        _paymentIcon(o.paymentMethod),
                        size: 20,
                        color: _statusColor(o.status, cs),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text('Order #${o.id}',
                            style: tt.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        _StatusChip(status: o.status),
                      ],
                    ),
                    subtitle: Text(dateFmt.format(o.createdAt),
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    trailing: Text(
                      '$symbol ${o.total.toStringAsFixed(2)}',
                      style: tt.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => context.push('/orders/${o.id}'),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Color _statusColor(String status, ColorScheme cs) => switch (status) {
        'voided' => cs.error,
        'refunded' => cs.tertiary,
        'held' => cs.secondary,
        _ => cs.primary,
      };

  IconData _paymentIcon(String method) =>
      method == 'cash' ? Icons.payments_rounded : Icons.credit_card_rounded;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      'voided' => ('Voided', cs.error),
      'refunded' => ('Refunded', cs.tertiary),
      'held' => ('Held', cs.secondary),
      _ => ('Completed', cs.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
