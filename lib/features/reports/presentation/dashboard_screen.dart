import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

// ── Period ────────────────────────────────────────────────────────────────────

enum _Period { today, week, month, year }

extension on _Period {
  String get label => switch (this) {
        _Period.today => 'Today',
        _Period.week => 'Week',
        _Period.month => 'Month',
        _Period.year => 'Year',
      };

  DateTime get from {
    final now = DateTime.now();
    return switch (this) {
      _Period.today => DateTime(now.year, now.month, now.day),
      _Period.week => DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1)),
      _Period.month => DateTime(now.year, now.month, 1),
      _Period.year => DateTime(now.year, 1, 1),
    };
  }

  // Truncated to the hour so _Query equality is stable across rebuilds and
  // the provider cache isn't invalidated every minute.
  DateTime get to {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, n.hour);
  }
}

// ── Query (period or custom range) ───────────────────────────────────────────

class _Query {
  const _Query({required this.from, required this.to, required this.label});
  final DateTime from;
  final DateTime to;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is _Query && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _TopProduct {
  const _TopProduct(
      {required this.name, required this.qty, required this.revenue});
  final String name;
  final int qty;
  final double revenue;
}

class _PayRow {
  const _PayRow(
      {required this.method, required this.count, required this.total});
  final String method;
  final int count;
  final double total;
}

class _ReportData {
  const _ReportData({
    required this.revenue,
    required this.expenses,
    required this.orderCount,
    required this.topProducts,
    required this.payBreakdown,
    required this.chartTitle,
    required this.chartDates,
    required this.chartTotals,
    required this.chartHighlightIndex,
  });
  final double revenue;
  final double expenses;
  final int orderCount;
  final List<_TopProduct> topProducts;
  final List<_PayRow> payBreakdown;
  final String chartTitle;
  final List<String> chartDates;
  final List<double> chartTotals;
  final int chartHighlightIndex;

  double get profit => revenue - expenses;
  double get avgOrder => orderCount > 0 ? revenue / orderCount : 0;
}

// ── Provider ──────────────────────────────────────────────────────────────────

String _hourLabel(int h) {
  if (h == 0) return '12am';
  if (h < 12) return '${h}am';
  if (h == 12) return '12pm';
  return '${h - 12}pm';
}

final _moneyFmt = NumberFormat('#,##0.00');

final _reportProvider =
    FutureProvider.family<_ReportData, _Query>((ref, query) async {
  final db = ref.watch(databaseProvider);
  final from = query.from;
  final to = query.to;

  final revenue = await db.ordersDao.totalRevenueForPeriod(from, to);
  final expenses = await db.expensesDao.totalForPeriod(from, to);

  final periodOrders = await db.ordersDao.completedOrdersInPeriod(from, to);

  final topRaw =
      await db.ordersDao.topSellingProductsForPeriod(from, to, limit: 5);
  final topProducts = topRaw
      .map((r) => _TopProduct(
            name: r['name'] as String,
            qty: r['qty'] as int,
            revenue: r['revenue'] as double,
          ))
      .toList();

  final payRaw = await db.ordersDao.paymentBreakdownForPeriod(from, to);
  final payBreakdown = payRaw
      .map((r) => _PayRow(
            method: r['method'] as String,
            count: r['count'] as int,
            total: r['total'] as double,
          ))
      .toList();

  // ── Duration-aware chart data ────────────────────────────────────────────
  final days = to.difference(from).inDays;
  String chartTitle;
  List<String> chartDates;
  List<double> chartTotals;
  int chartHighlightIndex;

  if (days < 2) {
    // ── Hourly (2-hour slots, full 24h) ──────────────────────────────────
    chartTitle = 'Hourly Sales';
    const slotCount = 12;
    final totals = List<double>.filled(slotCount, 0.0);
    for (final o in periodOrders) {
      totals[o.createdAt.hour ~/ 2] += o.total;
    }
    chartDates = [for (int i = 0; i < slotCount; i++) _hourLabel(i * 2)];
    chartTotals = totals;
    chartHighlightIndex = DateTime.now().hour ~/ 2;
  } else if (days <= 14) {
    // ── Daily ─────────────────────────────────────────────────────────────
    chartTitle = 'Daily Sales';
    final keyFmt = DateFormat('yyyy-MM-dd');
    final labelFmt = DateFormat('d/M');
    final daysList = <DateTime>[
      for (int i = 0; i <= days; i++) from.add(Duration(days: i))
    ];
    final dayTotals = <String, double>{
      for (final d in daysList) keyFmt.format(d): 0.0
    };
    for (final o in periodOrders) {
      final key = keyFmt.format(o.createdAt);
      if (dayTotals.containsKey(key)) {
        dayTotals[key] = dayTotals[key]! + o.total;
      }
    }
    chartDates = daysList.map((d) => labelFmt.format(d)).toList();
    chartTotals = daysList.map((d) => dayTotals[keyFmt.format(d)]!).toList();
    final todayKey = keyFmt.format(DateTime.now());
    chartHighlightIndex =
        daysList.indexWhere((d) => keyFmt.format(d) == todayKey);
    if (chartHighlightIndex < 0) chartHighlightIndex = chartDates.length - 1;
  } else if (days <= 93) {
    // ── Weekly buckets ────────────────────────────────────────────────────
    chartTitle = 'Weekly Sales';
    // Build week buckets starting from 'from'
    final buckets = <DateTime>[];
    var ws = DateTime(from.year, from.month, from.day);
    while (!ws.isAfter(to)) {
      buckets.add(ws);
      ws = ws.add(const Duration(days: 7));
    }
    final totals = List<double>.filled(buckets.length, 0.0);
    for (final o in periodOrders) {
      for (int i = buckets.length - 1; i >= 0; i--) {
        if (!o.createdAt.isBefore(buckets[i])) {
          totals[i] += o.total;
          break;
        }
      }
    }
    final labelFmt = DateFormat('d/M');
    chartDates = buckets.map((d) => labelFmt.format(d)).toList();
    chartTotals = totals;
    final now = DateTime.now();
    chartHighlightIndex = buckets.length - 1;
    for (int i = buckets.length - 1; i >= 0; i--) {
      if (!now.isBefore(buckets[i])) {
        chartHighlightIndex = i;
        break;
      }
    }
  } else {
    // ── Monthly ───────────────────────────────────────────────────────────
    chartTitle = 'Monthly Sales';
    final monthFmt = DateFormat('MMM');
    final now = DateTime.now();
    final months = <DateTime>[];
    var m = DateTime(from.year, from.month, 1);
    while (!m.isAfter(to)) {
      months.add(m);
      m = DateTime(m.year, m.month + 1, 1);
    }
    final totals = List<double>.filled(months.length, 0.0);
    for (final o in periodOrders) {
      final idx = months.indexWhere(
          (m) => m.year == o.createdAt.year && m.month == o.createdAt.month);
      if (idx >= 0) totals[idx] += o.total;
    }
    chartDates = months.map((m) => monthFmt.format(m)).toList();
    chartTotals = totals;
    chartHighlightIndex =
        months.indexWhere((m) => m.year == now.year && m.month == now.month);
    if (chartHighlightIndex < 0) chartHighlightIndex = months.length - 1;
  }

  return _ReportData(
    revenue: revenue,
    expenses: expenses,
    orderCount: periodOrders.length,
    topProducts: topProducts,
    payBreakdown: payBreakdown,
    chartTitle: chartTitle,
    chartDates: chartDates,
    chartTotals: chartTotals,
    chartHighlightIndex: chartHighlightIndex,
  );
});

// ── Screen ────────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  _Period _period = _Period.today;
  DateTimeRange? _customRange;

  static final _rangeLabelFmt = DateFormat('d MMM');

  _Query get _activeQuery {
    if (_customRange != null) {
      return _Query(
        from: _customRange!.start,
        to: _customRange!.end
            .add(const Duration(hours: 23, minutes: 59, seconds: 59)),
        label: 'Custom Range',
      );
    }
    return _Query(from: _period.from, to: _period.to, label: _period.label);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
      builder: (context, child) => child!,
    );
    if (picked != null) {
      setState(() => _customRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _activeQuery;
    final reportAsync = ref.watch(_reportProvider(query));
    final symbol = ref.watch(currencySymbolProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_month_rounded,
              color: _customRange != null ? cs.primary : null,
            ),
            tooltip: 'Custom date range',
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: SegmentedButton<_Period>(
              segments: _Period.values
                  .map((p) => ButtonSegment(value: p, label: Text(p.label)))
                  .toList(),
              emptySelectionAllowed: true,
              selected: _customRange != null ? {} : {_period},
              onSelectionChanged: (s) {
                if (s.isEmpty) return;
                setState(() {
                  _period = s.first;
                  _customRange = null;
                });
              },
            ),
          ),
          // Custom range indicator
          if (_customRange != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.date_range_rounded, size: 14, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${_rangeLabelFmt.format(_customRange!.start)} – ${_rangeLabelFmt.format(_customRange!.end)}',
                    style: TextStyle(
                        color: cs.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _customRange = null),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(_reportProvider(query));
                await ref.read(_reportProvider(query).future);
              },
              child: reportAsync.when(
                data: (data) => _Body(
                  data: data,
                  symbol: symbol,
                  cs: cs,
                  periodLabel: query.label,
                  isCustomRange: _customRange != null,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text('Error: $e')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.data,
    required this.symbol,
    required this.cs,
    required this.periodLabel,
    required this.isCustomRange,
  });
  final _ReportData data;
  final String symbol;
  final ColorScheme cs;
  final String periodLabel;
  final bool isCustomRange;

  @override
  Widget build(BuildContext context) {
    final empty = data.revenue == 0 && data.orderCount == 0;
    final kpiRows = _buildKpiRows();

    if (empty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          ...kpiRows,
          const SizedBox(height: 56),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart_rounded,
                    size: 64,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.35)),
                const SizedBox(height: 12),
                Text(
                  'No sales for ${periodLabel.toLowerCase()}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        ...kpiRows,
        const SizedBox(height: 22),

        // ── Chart ─────────────────────────────────────────────────────────
        if (data.chartTotals.any((v) => v > 0)) ...[
          _SectionHeader(data.chartTitle, cs),
          _MiniBarChart(
            labels: data.chartDates,
            values: data.chartTotals,
            highlightIndex: isCustomRange ? -1 : data.chartHighlightIndex,
            cs: cs,
          ),
          const SizedBox(height: 22),
        ],

        // ── Summary ───────────────────────────────────────────────────────
        if (data.orderCount > 0) ...[
          _SectionHeader('Summary', cs),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.receipt_rounded, color: cs.primary),
                  title: const Text('Avg. Order Value'),
                  trailing: Text(
                    '$symbol ${_fmt(data.avgOrder)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                        fontSize: 15),
                  ),
                ),
                if (data.payBreakdown.isNotEmpty) ...[
                  const Divider(height: 1, indent: 16),
                  ...data.payBreakdown.map((p) => ListTile(
                        leading: Icon(
                          p.method == 'cash'
                              ? Icons.payments_rounded
                              : Icons.credit_card_rounded,
                          color: cs.secondary,
                        ),
                        title: Text(
                          '${p.method[0].toUpperCase()}${p.method.substring(1)}',
                        ),
                        subtitle:
                            Text('${p.count} order${p.count == 1 ? '' : 's'}'),
                        trailing: Text(
                          '$symbol ${_fmt(p.total)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: cs.secondary),
                        ),
                      )),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],

        // ── Top products ──────────────────────────────────────────────────
        if (data.topProducts.isNotEmpty) ...[
          _SectionHeader('Top Products', cs),
          Card(
            child: Column(
              children: data.topProducts.indexed.map((entry) {
                final i = entry.$1;
                final p = entry.$2;
                final maxQty = data.topProducts.first.qty;
                return Column(
                  children: [
                    if (i > 0) const Divider(height: 1, indent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: i == 0
                                      ? cs.primaryContainer
                                      : cs.surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: i == 0
                                          ? cs.onPrimaryContainer
                                          : cs.onSurfaceVariant),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(p.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500))),
                              Text(
                                '${p.qty} sold',
                                style: TextStyle(
                                    fontSize: 12, color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$symbol ${_fmt(p.revenue)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: maxQty > 0 ? p.qty / maxQty : 0,
                              minHeight: 4,
                              backgroundColor: cs.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                  i == 0 ? cs.primary : cs.secondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildKpiRows() => [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Revenue',
                value: '$symbol ${_fmt(data.revenue)}',
                icon: Icons.trending_up_rounded,
                color: cs.primary,
                cs: cs,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                label: 'Expenses',
                value: '$symbol ${_fmt(data.expenses)}',
                icon: Icons.trending_down_rounded,
                color: cs.error,
                cs: cs,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Net Profit',
                value: '$symbol ${_fmt(data.profit)}',
                icon: Icons.account_balance_rounded,
                color: data.profit >= 0 ? const Color(0xFF16A34A) : cs.error,
                cs: cs,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                label: 'Orders',
                value: '${data.orderCount}',
                icon: Icons.shopping_bag_rounded,
                color: cs.secondary,
                cs: cs,
              ),
            ),
          ],
        ),
      ];

  String _fmt(double v) => _moneyFmt.format(v);
}

// ── Mini bar chart ────────────────────────────────────────────────────────────

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({
    required this.labels,
    required this.values,
    required this.highlightIndex,
    required this.cs,
  });
  final List<String> labels;
  final List<double> values;
  final int highlightIndex;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final maxVal = values.fold(0.0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(labels.length, (i) {
                final ratio = maxVal > 0 ? values[i] / maxVal : 0.0;
                final isHighlight = i == highlightIndex;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isHighlight && values[i] > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              values[i] >= 1000
                                  ? '${(values[i] / 1000).toStringAsFixed(1)}k'
                                  : values[i].toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOut,
                          height: ratio * 72,
                          decoration: BoxDecoration(
                            color: isHighlight
                                ? cs.primary
                                : cs.primary.withValues(alpha: 0.35),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: labels
                .asMap()
                .entries
                .map((e) => Expanded(
                      child: Text(
                        e.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: e.key == highlightIndex
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: e.key == highlightIndex
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── KPI card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.cs,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.cs);
  final String title;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: cs.primary),
        ),
      );
}
