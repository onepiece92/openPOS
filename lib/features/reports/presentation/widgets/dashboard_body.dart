import 'package:flutter/material.dart';
import 'package:pos_app/core/theme/app_theme.dart';
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
    this.sections = ReportSections.all,
  });

  /// Parts switched off in Features are not built.
  final ReportSections sections;
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
        if (sections.extras && data.chartTotals.any((v) => v > 0)) ...[
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
                        fontFamily: AppFonts.mono, fontFamilyFallback: AppFonts.monoFallback),
                  ),
                ),
                if (sections.extras && data.payBreakdown.isNotEmpty) ...[
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
                              fontFamily: AppFonts.mono, fontFamilyFallback: AppFonts.monoFallback),
                        ),
                      )),
                  if (sections.tips && data.netTips > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Text(
                        "Payment totals don't include tips.",
                        key: const ValueKey('pay-mix-tips-note'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],

        // ── Top products ──────────────────────────────────────────────────
        if (sections.extras && data.topProducts.isNotEmpty) ...[
          _SectionHeader('Top Products', cs),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Units sold and sales excl. ${data.taxLabel}, '
              'after discounts and refunds',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ),
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
                                    fontFamily: AppFonts.mono, fontFamilyFallback: AppFonts.monoFallback),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$symbol ${_fmt(p.sales)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary,
                                    fontFamily: AppFonts.mono, fontFamilyFallback: AppFonts.monoFallback),
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

  /// Revenue is what came in (VAT included). Profit is worked out from the
  /// part of it that is the shop's own: sales excluding VAT, less what the
  /// goods cost, less expenses.
  List<Widget> _buildKpiRows() {
    final cost = sections.costProfit;
    final cards = <Widget>[
      KpiCard(
        label: 'Revenue (incl. ${data.taxLabel})',
        value: '$symbol ${_fmt(data.revenue)}',
        icon: Icons.trending_up_rounded,
        color: cs.primary,
        cs: cs,
      ),
      KpiCard(
        label: '${data.taxLabel} Collected',
        value: '$symbol ${_fmt(data.vatCollected)}',
        icon: Icons.receipt_long_rounded,
        color: cs.tertiary,
        cs: cs,
      ),
      if (cost)
        KpiCard(
          label: 'Cost of Goods',
          value: '$symbol ${_fmt(data.costOfGoods)}',
          icon: Icons.inventory_2_rounded,
          color: cs.error,
          cs: cs,
        ),
      if (sections.expenses)
        KpiCard(
          label: 'Expenses',
          value: '$symbol ${_fmt(data.expenses)}',
          icon: Icons.trending_down_rounded,
          color: cs.error,
          cs: cs,
        ),
      if (cost)
        KpiCard(
          label: 'Net Profit',
          value: '$symbol ${_fmt(data.profit)}',
          icon: Icons.account_balance_rounded,
          color: data.profit >= 0 ? StatusColors.success(cs) : cs.error,
          cs: cs,
        ),
      KpiCard(
        label: 'Orders',
        value: '${data.orderCount}',
        icon: Icons.shopping_bag_rounded,
        color: cs.secondary,
        cs: cs,
      ),
      if (sections.tips)
        KpiCard(
          label: 'Tips',
          value: '$symbol ${_fmt(data.netTips)}',
          icon: Icons.volunteer_activism_rounded,
          color: cs.secondary,
          cs: cs,
        ),
    ];
    return [
      for (var i = 0; i < cards.length; i += 2) ...[
        if (i > 0) const SizedBox(height: 10),
        _kpiRow(cards[i], i + 1 < cards.length ? cards[i + 1] : null),
      ],
      if (cost)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
            'Net profit = sales excl. ${data.taxLabel} '
            '($symbol ${_fmt(data.salesExVat)}) '
            '− cost of goods${sections.expenses ? ' − expenses' : ''}.',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ),
      if (cost && data.costIsIncomplete)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: cs.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${data.uncostedLines} of ${data.soldLines} sold '
                  'item${data.soldLines == 1 ? '' : 's'} '
                  'ha${data.uncostedLines == 1 ? 's' : 've'} no purchase '
                  'price recorded and count as zero cost, so profit is '
                  'overstated. Set purchase prices on your products.',
                  style: TextStyle(fontSize: 11, color: cs.error),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _kpiRow(Widget left, Widget? right) => Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right ?? const SizedBox.shrink()),
        ],
      );

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
              color: cs.onSurfaceVariant),
        ),
      );
}

final _moneyFmt = NumberFormat('#,##0.00');
