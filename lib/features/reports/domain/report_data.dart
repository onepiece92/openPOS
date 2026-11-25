import 'package:drift/drift.dart' show TableUpdateQuery;
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

  // The end of today, so the period always covers everything sold up to
  // now. It only changes at midnight, which keeps ReportQuery equality (the
  // provider key) stable across rebuilds; [reportProvider] refreshes itself
  // when the underlying tables change.
  DateTime get to {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, 23, 59, 59, 999);
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
  const TopProduct({
    required this.productId,
    required this.name,
    required this.qty,
    required this.sales,
  });
  final int productId;

  /// The product's current name.
  final String name;

  /// Units sold, in the product's main unit.
  final int qty;

  /// Sales excluding VAT, after order discounts and refunds — see
  /// `OrdersDao.topSellingProductsForPeriod`.
  final double sales;
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
    required this.vatCollected,
    required this.costOfGoods,
    required this.soldLines,
    required this.uncostedLines,
    required this.expenses,
    required this.orderCount,
    required this.topProducts,
    required this.payBreakdown,
    required this.chartTitle,
    required this.chartDates,
    required this.chartTotals,
    required this.chartHighlightIndex,
  });

  /// Takings including VAT, net of refunds.
  final double revenue;

  /// The VAT inside [revenue] — held for the tax office, not income.
  final double vatCollected;

  /// What the goods sold cost the shop at the time of each sale.
  final double costOfGoods;

  /// Order lines behind [revenue], and how many of them have no cost
  /// recorded (they count as zero in [costOfGoods], overstating [profit]).
  final int soldLines;
  final int uncostedLines;

  final double expenses;
  final int orderCount;
  final List<TopProduct> topProducts;
  final List<PayRow> payBreakdown;
  final String chartTitle;
  final List<String> chartDates;
  final List<double> chartTotals;
  final int chartHighlightIndex;

  /// Sales excluding VAT. Points redeemed are money that never came in, so
  /// they are already out of [revenue] and therefore out of this.
  double get salesExVat => _round2(revenue - vatCollected);

  /// Net profit: sales excluding VAT, less what the goods cost, less
  /// expenses.
  double get profit => _round2(salesExVat - costOfGoods - expenses);

  /// True when [costOfGoods] is missing the cost of some sold lines.
  bool get costIsIncomplete => uncostedLines > 0;

  double get avgOrder => orderCount > 0 ? revenue / orderCount : 0;

  static double _round2(double v) => (v * 100).roundToDouble() / 100;
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
  // The key no longer moves during the day, so recompute when a sale, void,
  // refund or expense lands instead of serving the first answer until midnight.
  final changes = db
      .tableUpdates(TableUpdateQuery.onAllTables(
          [db.orders, db.orderItems, db.returns, db.expenses, db.products]))
      .listen((_) => ref.invalidateSelf());
  ref.onDispose(changes.cancel);
  final from = query.from;
  final to = query.to;

  final revenue = await db.ordersDao.totalRevenueForPeriod(from, to);
  final expenses = await db.expensesDao.totalForPeriod(from, to);

  final periodOrders = await db.ordersDao.completedOrdersInPeriod(from, to);

  final vatCollected = await db.ordersDao.vatCollectedForPeriod(from, to);
  final goods = await db.ordersDao.costOfGoodsForPeriod(from, to);

  final topRaw =
      await db.ordersDao.topSellingProductsForPeriod(from, to, limit: 5);
  final topProducts = [
    for (final r in topRaw)
      TopProduct(
          productId: r.productId, name: r.name, qty: r.qty, sales: r.sales),
  ];

  final payRaw = await db.ordersDao.paymentBreakdownForPeriod(from, to);
  final payBreakdown = payRaw
      .map((r) => PayRow(
            method: r['method'] as String,
            count: r['count'] as int,
            total: r['total'] as double,
          ))
      .toList();

  // ── Duration-aware chart data ────────────────────────────────────────────
  // Whole calendar days between the two dates (0 = the same day). Counted
  // on the dates, not on elapsed hours: two days are 47h59m apart, which is
  // "1 day" by the clock, and a 25-hour autumn day must not add a bucket.
  final days = DateTime.utc(to.year, to.month, to.day)
      .difference(DateTime.utc(from.year, from.month, from.day))
      .inDays;
  String chartTitle;
  List<String> chartDates;
  List<double> chartTotals;
  int chartHighlightIndex;

  if (days < 1) {
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
      for (int i = 0; i <= days; i++)
        DateTime(from.year, from.month, from.day + i)
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
    vatCollected: vatCollected,
    costOfGoods: goods.cost,
    soldLines: goods.lines,
    uncostedLines: goods.uncostedLines,
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
