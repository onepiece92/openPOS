import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pos_app/core/providers/database_provider.dart';

/// Reporting periods, the (from, to, label) query they resolve to, and
/// [reportProvider] — the one query that feeds the whole dashboard
/// (KPIs, duration-aware chart buckets, top products, payment mix).
// ── Period ────────────────────────────────────────────────────────────────────

enum ReportPeriod { today, week, month, year }

extension ReportPeriodX on ReportPeriod {
  String get label => switch (this) {
        ReportPeriod.today => 'Today',
        ReportPeriod.week => 'Week',
        ReportPeriod.month => 'Month',
        ReportPeriod.year => 'Year',
      };

  DateTime get from {
    final now = DateTime.now();
    return switch (this) {
      ReportPeriod.today => DateTime(now.year, now.month, now.day),
      ReportPeriod.week => DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1)),
      ReportPeriod.month => DateTime(now.year, now.month, 1),
      ReportPeriod.year => DateTime(now.year, 1, 1),
    };
  }

  // Truncated to the hour so ReportQuery equality is stable across rebuilds and
  // the provider cache isn't invalidated every minute.
  DateTime get to {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, n.hour);
  }
}

// ── Query (period or custom range) ───────────────────────────────────────────

class ReportQuery {
  const ReportQuery({required this.from, required this.to, required this.label});
  final DateTime from;
  final DateTime to;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is ReportQuery && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

// ── Data classes ──────────────────────────────────────────────────────────────

class TopProduct {
  const TopProduct(
      {required this.name, required this.qty, required this.revenue});
  final String name;
  final int qty;
  final double revenue;
}

class PayRow {
  const PayRow(
      {required this.method, required this.count, required this.total});
  final String method;
  final int count;
  final double total;
}

class ReportData {
  const ReportData({
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
  final List<TopProduct> topProducts;
  final List<PayRow> payBreakdown;
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

final reportProvider =
    FutureProvider.family<ReportData, ReportQuery>((ref, query) async {
  final db = ref.watch(databaseProvider);
  final from = query.from;
  final to = query.to;

  final revenue = await db.ordersDao.totalRevenueForPeriod(from, to);
  final expenses = await db.expensesDao.totalForPeriod(from, to);

  final periodOrders = await db.ordersDao.completedOrdersInPeriod(from, to);

  final topRaw =
      await db.ordersDao.topSellingProductsForPeriod(from, to, limit: 5);
  final topProducts = topRaw
      .map((r) => TopProduct(
            name: r['name'] as String,
            qty: r['qty'] as int,
            revenue: r['revenue'] as double,
          ))
      .toList();

  final payRaw = await db.ordersDao.paymentBreakdownForPeriod(from, to);
  final payBreakdown = payRaw
      .map((r) => PayRow(
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

  return ReportData(
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
