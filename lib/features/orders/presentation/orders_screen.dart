import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/theme/tokens.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/core/widgets/app_empty_state.dart';
import 'package:pos_app/features/customers/domain/customers_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

final _recentOrdersProvider = StreamProvider<List<Order>>((ref) {
  return ref.watch(databaseProvider).ordersDao.watchRecent(limit: 500);
});

// ─── Orders screen ────────────────────────────────────────────────────────────

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(_recentOrdersProvider);
    final fmt = ref.watch(currencyFormatterProvider);
    final customers = ref.watch(customersStreamProvider).valueOrNull ?? [];
    final customerNames = {for (final c in customers) c.id: c.name};

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(
        title: const Text('Order History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              hintText: 'Search by order ID or amount…',
              leading: const Icon(Icons.search_rounded, size: 20),
              trailing: _query.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _query = ''),
                      )
                    ]
                  : null,
              onChanged: (v) => setState(() => _query = v.trim()),
              elevation: const WidgetStatePropertyAll(0),
            ),
          ),
        ),
      ),
      body: ordersAsync.when(
        data: (all) {
          final filtered = _filter(all, _query);
          if (all.isEmpty) {
            return const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Completed sales will appear here.',
            );
          }
          if (filtered.isEmpty) {
            return Center(
              child: Text(
                'No orders match "$_query"',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            );
          }

          // Build summary from today's orders
          final today = _todayOrders(all);
          final todayRevenue =
              today.fold(0.0, (s, o) => s + (o.status == 'completed' ? o.total : 0));

          final grouped = _groupByDate(filtered);

          return CustomScrollView(
            slivers: [
              if (_query.isEmpty)
                SliverToBoxAdapter(
                  child: _SummaryBar(
                    orderCount: today.length,
                    revenue: todayRevenue,
                    fmt: fmt,
                  ),
                ),
              for (final entry in grouped.entries) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: entry.value.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _OrderCard(
                      order: entry.value[i],
                      fmt: fmt,
                      customerName: entry.value[i].customerId != null
                          ? customerNames[entry.value[i].customerId]
                          : null,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  List<Order> _filter(List<Order> orders, String q) {
    if (q.isEmpty) return orders;
    final lower = q.toLowerCase();
    return orders.where((o) {
      return o.id.toString().contains(lower) ||
          o.total.toStringAsFixed(2).contains(lower);
    }).toList();
  }

  List<Order> _todayOrders(List<Order> orders) {
    final now = DateTime.now();
    return orders.where((o) {
      final d = o.createdAt;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  /// Groups orders by a human-readable date label.
  Map<String, List<Order>> _groupByDate(List<Order> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final fmt = DateFormat('d MMM yyyy');

    final result = <String, List<Order>>{};
    for (final o in orders) {
      final d = DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
      final String label;
      if (d == today) {
        label = 'Today';
      } else if (d == yesterday) {
        label = 'Yesterday';
      } else {
        label = fmt.format(d);
      }
      (result[label] ??= []).add(o);
    }
    return result;
  }
}

// ─── Summary bar ─────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.orderCount,
    required this.revenue,
    required this.fmt,
  });
  final int orderCount;
  final double revenue;
  final CurrencyFormatter fmt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              label: "Today's orders",
              value: orderCount.toString(),
              icon: Icons.receipt_long_rounded,
              cs: cs,
              tt: tt,
            ),
          ),
          Container(width: 1, height: 40, color: cs.outlineVariant),
          Expanded(
            child: _StatCell(
              label: "Today's revenue",
              value: fmt.format(revenue),
              icon: Icons.attach_money_rounded,
              cs: cs,
              tt: tt,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.cs,
    required this.tt,
  });
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(height: 4),
          Text(value,
              style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800, fontFamily: AppFonts.mono)),
          Text(label,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      );
}

// ─── Order card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.fmt,
    this.customerName,
  });
  final Order order;
  final CurrencyFormatter fmt;
  final String? customerName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final timeFmt = DateFormat('HH:mm');
    final statusColor = _statusColor(order.status, cs);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Payment icon badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _paymentIcon(order.paymentMethod),
                  size: 20,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              // Middle info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: tt.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        _StatusDot(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          timeFmt.format(order.createdAt),
                          style: tt.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        if (customerName != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.person_outline_rounded,
                              size: 12, color: cs.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              customerName!,
                              style: tt.labelSmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 8),
                          Icon(
                            order.paymentMethod == 'cash'
                                ? Icons.payments_outlined
                                : Icons.credit_card_outlined,
                            size: 12,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _methodLabel(order.paymentMethod),
                            style: tt.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.format(order.total),
                    style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFamily: AppFonts.mono),
                  ),
                  if (order.discountTotal > 0)
                    Text(
                      '−${fmt.format(order.discountTotal)} off',
                      style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontFamily: AppFonts.mono),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: cs.onSurfaceVariant),
            ],
          ),
        ),
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

  String _methodLabel(String method) => switch (method) {
        'cash' => 'Cash',
        'card' => 'Card',
        'split' => 'Split',
        _ => method,
      };
}

// ─── Status dot / chip ────────────────────────────────────────────────────────

/// Completed = small colored dot only. Other statuses = dot + short label.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      'voided' => ('Voided', cs.error),
      'refunded' => ('Refund', cs.tertiary),
      'held' => ('Held', cs.secondary),
      _ => (null, cs.primary), // completed — dot only
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        if (label != null) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

