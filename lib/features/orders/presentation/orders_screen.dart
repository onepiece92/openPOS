import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/theme/tokens.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/shared/widgets/app_empty_state.dart';
import 'package:pos_app/features/customers/domain/customers_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';
import 'package:pos_app/features/orders/domain/order_history.dart';
import 'package:pos_app/features/orders/domain/order_number.dart';

// ─── Orders screen ────────────────────────────────────────────────────────────

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Fetch the next (older) page shortly before the end comes into view.
  void _onScroll() {
    if (_scrollController.position.extentAfter < 600) {
      ref.read(orderHistoryProvider.notifier).loadMore();
    }
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value.trim());
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) ref.read(orderHistoryProvider.notifier).setSearch(_query);
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
    ref.read(orderHistoryProvider.notifier).setSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(orderHistoryProvider);
    final fmt = ref.watch(currencyFormatterProvider);
    // Customers off: the list is not watched, but orders still show their
    // stored customer (read once, just for the ids on screen).
    final Map<int, String> customerNames;
    if (ref.watch(featureOnProvider(Feature.customers))) {
      final customers = ref.watch(customersStreamProvider).valueOrNull ?? [];
      customerNames = {for (final c in customers) c.id: c.name};
    } else {
      customerNames = ref
              .watch(customerNamesProvider(customerNamesKey(
                  history.orders.map((o) => o.customerId))))
              .valueOrNull ??
          const {};
    }

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(
        title: const Text('Order History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search by bill no., customer or amount…',
              leading: const Icon(Icons.search_rounded, size: 20),
              trailing: _query.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: _clearQuery,
                      )
                    ]
                  : null,
              onChanged: _onQueryChanged,
              elevation: const WidgetStatePropertyAll(0),
            ),
          ),
        ),
      ),
      body: _body(context, history, fmt, customerNames),
    );
  }

  Widget _body(BuildContext context, OrderHistoryState history,
      CurrencyFormatter fmt, Map<int, String> customerNames) {
    if (history.isLoading && history.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (history.error != null && history.orders.isEmpty) {
      return Center(child: Text('Error: ${history.error}'));
    }
    if (history.orders.isEmpty) {
      if (history.search.isEmpty) {
        return const AppEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No orders yet',
          subtitle: 'Completed sales will appear here.',
        );
      }
      return Center(
        child: Text(
          'No orders match "${history.search}"',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    final grouped = _groupByDate(history.orders);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (history.search.isEmpty)
          SliverToBoxAdapter(
            child: _SummaryBar(
              orderCount: history.todayOrders,
              revenue: history.todayRevenue,
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
        if (history.hasMore)
          SliverToBoxAdapter(
            child: _LoadMore(
              loading: history.isLoadingMore,
              onPressed: ref.read(orderHistoryProvider.notifier).loadMore,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
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

/// Foot of the list while older orders remain: a spinner during a fetch,
/// otherwise a button (scrolling near it fetches too — the button is for
/// lists too short to scroll).
class _LoadMore extends StatelessWidget {
  const _LoadMore({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(
                  onPressed: onPressed,
                  child: const Text('Show older orders'),
                ),
        ),
      );
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
                          'Order ${order.billNo}',
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

