import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:pos_app/core/theme/tokens.dart';
import 'package:pos_app/features/reports/domain/report_data.dart';
import 'package:pos_app/features/reports/presentation/widgets/kpi_card.dart';
import 'package:pos_app/features/reports/presentation/widgets/mini_bar_chart.dart';

// ── Body ──────────────────────────────────────────────────────────────────────

class DashboardBody extends StatelessWidget {
  const DashboardBody({
    super.key,
    required this.data,
    required this.symbol,
    required this.cs,
    required this.periodLabel,
    required this.isCustomRange,
  });
  final ReportData data;
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
          MiniBarChart(
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
                        fontSize: 15,
                        fontFamily: AppFonts.mono),
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
                              fontWeight: FontWeight.w600,
                              color: cs.secondary,
                              fontFamily: AppFonts.mono),
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
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                    fontFamily: AppFonts.mono),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$symbol ${_fmt(p.revenue)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary,
                                    fontFamily: AppFonts.mono),
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
              child: KpiCard(
                label: 'Revenue',
                value: '$symbol ${_fmt(data.revenue)}',
                icon: Icons.trending_up_rounded,
                color: cs.primary,
                cs: cs,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
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
              child: KpiCard(
                label: 'Net Profit',
                value: '$symbol ${_fmt(data.profit)}',
                icon: Icons.account_balance_rounded,
                color: data.profit >= 0 ? const Color(0xFF16A34A) : cs.error,
                cs: cs,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
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

final _moneyFmt = NumberFormat('#,##0.00');
