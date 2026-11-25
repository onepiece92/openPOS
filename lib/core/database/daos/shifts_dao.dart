import 'package:drift/drift.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/tables/orders_table.dart';
import 'package:pos_app/core/database/tables/returns_table.dart';
import 'package:pos_app/core/database/tables/shifts_table.dart';

part 'shifts_dao.g.dart';

/// Thrown when a shift operation does not fit the current shift state:
/// opening while one is open, or closing one that is missing or closed.
class ShiftStateException implements Exception {
  const ShiftStateException(this.message);
  final String message;
  @override
  String toString() => 'ShiftStateException: $message';
}

/// Sales of one payment method in a window (orders that count as sales:
/// `completed` and `refunded`; see [ShiftsDao.salesInWindow]).
class MethodSales {
  const MethodSales({
    required this.count,
    required this.total,
    required this.tax,
    required this.tips,
  });
  static const zero = MethodSales(count: 0, total: 0, tax: 0, tips: 0);

  final int count;

  /// Σ orders.total — gross, tip-free; refunds are reported separately.
  final double total;

  /// Σ orders.tax_total.
  final double tax;

  /// Σ orders.tip_amount.
  final double tips;
}

/// Everything rung up in a window, by payment method.
class WindowSales {
  const WindowSales({
    required this.byMethod,
    required this.voidedCount,
    required this.voidedTotal,
  });

  /// payment_method → its sales. Methods with no sales are absent.
  final Map<String, MethodSales> byMethod;

  /// Orders rung up in the window that are now voided (not in [byMethod]).
  final int voidedCount;
  final double voidedTotal;

  MethodSales get cash => byMethod['cash'] ?? MethodSales.zero;
  double get cashSales => cash.total;
  double get cashTips => cash.tips;

  int get orderCount => byMethod.values.fold(0, (s, m) => s + m.count);
  double get totalSales => _r2(byMethod.values.fold(0.0, (s, m) => s + m.total));
  double get taxCollected => _r2(byMethod.values.fold(0.0, (s, m) => s + m.tax));
  double get tipsCollected => _r2(byMethod.values.fold(0.0, (s, m) => s + m.tips));
}

/// Refunds of one payment method handed out in a window.
class MethodRefunds {
  const MethodRefunds({
    required this.count,
    required this.amount,
    required this.tips,
  });
  static const zero = MethodRefunds(count: 0, amount: 0, tips: 0);

  final int count;

  /// Σ returns.amount (the tip-free part of the refund).
  final double amount;

  /// Σ returns.tip_amount.
  final double tips;

  /// What actually left the till: amount + tip refunded.
  double get total => _r2(amount + tips);
}

/// Refunds handed out in a window, by the original order's payment method.
class WindowRefunds {
  const WindowRefunds({required this.byMethod});
  final Map<String, MethodRefunds> byMethod;

  MethodRefunds get cash => byMethod['cash'] ?? MethodRefunds.zero;

  /// Σ amount + Σ tip_amount of refunds against cash orders.
  double get cashRefunds => cash.total;

  double get tipsRefunded =>
      _r2(byMethod.values.fold(0.0, (s, m) => s + m.tips));
}

/// The two aggregates the close screen needs, for one window.
class ShiftFigures {
  const ShiftFigures({required this.sales, required this.refunds});
  final WindowSales sales;
  final WindowRefunds refunds;

  double get cashSales => sales.cashSales;
  double get cashTips => sales.cashTips;
  double get cashRefunds => refunds.cashRefunds;

  /// Σ orders.tip_amount − Σ returns.tip_amount, all methods.
  double get netTips => _r2(sales.tipsCollected - refunds.tipsRefunded);

  /// opening + cash sales + cash tips − cash refunds − paid out.
  double expectedCash({required double openingCash, double paidOut = 0}) =>
      _r2(openingCash + cashSales + cashTips - cashRefunds - paidOut);
}

double _r2(double v) => (v * 100).roundToDouble() / 100;

/// Till sessions (open → end-of-day close) and the window aggregates the
/// close is computed from.
@DriftAccessor(tables: [Shifts, Orders, Returns])
class ShiftsDao extends DatabaseAccessor<AppDatabase> with _$ShiftsDaoMixin {
  ShiftsDao(super.db);

  // ── Lifecycle ──────────────────────────────────────────────────────────

  SimpleSelectStatement<$ShiftsTable, Shift> _open() =>
      select(shifts)
        ..where((s) => s.closedAt.isNull())
        ..limit(1);

  /// Opens a new shift and returns its id. Throws [ShiftStateException] if
  /// one is already open — at most one open shift exists at a time.
  Future<int> openShift({required double openingCash, DateTime? openedAt}) =>
      transaction(() async {
        final open = await _open().getSingleOrNull();
        if (open != null) {
          throw ShiftStateException(
              'Shift #${open.id} is still open; close it first');
        }
        return into(shifts).insert(ShiftsCompanion.insert(
          openingCash: Value(openingCash),
          openedAt: openedAt == null ? const Value.absent() : Value(openedAt),
        ));
      });

  /// The open shift, or null.
  Future<Shift?> currentShift() => _open().getSingleOrNull();

  Stream<Shift?> watchCurrentShift() => _open().watchSingleOrNull();

  /// The most recently closed shift — its `countedCash` is the natural
  /// default for the next shift's opening cash.
  Future<Shift?> lastClosedShift() async {
    final rows = await closedShifts(limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  /// Closed shifts, newest close first.
  Future<List<Shift>> closedShifts({int limit = 30}) => (select(shifts)
        ..where((s) => s.closedAt.isNotNull())
        ..orderBy([
          (s) => OrderingTerm.desc(s.closedAt),
          (s) => OrderingTerm.desc(s.id),
        ])
        ..limit(limit))
      .get();

  /// Freezes the close figures onto shift [id]. Throws
  /// [ShiftStateException] if the shift does not exist or is already closed.
  Future<void> closeShift(
    int id, {
    required double cashSales,
    required double cashTips,
    required double cashRefunds,
    required double paidOut,
    required double expectedCash,
    required double countedCash,
    required String summaryText,
    String? notes,
    DateTime? closedAt,
  }) =>
      transaction(() async {
        final shift = await (select(shifts)..where((s) => s.id.equals(id)))
            .getSingleOrNull();
        if (shift == null) {
          throw ShiftStateException('Shift #$id not found');
        }
        if (shift.closedAt != null) {
          throw ShiftStateException('Shift #$id is already closed');
        }
        await (update(shifts)..where((s) => s.id.equals(id))).write(
          ShiftsCompanion(
            closedAt: Value(closedAt ?? DateTime.now()),
            cashSales: Value(cashSales),
            cashTips: Value(cashTips),
            cashRefunds: Value(cashRefunds),
            paidOut: Value(paidOut),
            expectedCash: Value(expectedCash),
            countedCash: Value(countedCash),
            summaryText: Value(summaryText),
            notes: Value(notes),
          ),
        );
      });

  // ── Window aggregates (for the close) ──────────────────────────────────
  //
  // Windows are half-open: [from, to). Sales are attributed to the order's
  // created_at; refunds to the return's created_at — a refund given today
  // for last week's sale leaves today's drawer, so it counts today.
  // Because refunds are counted where they happen, sales here are GROSS
  // (not net of refunds, unlike the reports' _netOrders).

  /// One aggregate over the window's orders, via idx_orders_created_at.
  ///
  /// Counted as sales: `completed` (including partly refunded) and
  /// `refunded` (fully refunded — the sale happened; its refund is counted
  /// in the refund's window). `voided` orders are left out of sales and
  /// tips (the sale is cancelled) and reported apart; `held` orders were
  /// never paid and are ignored.
  Future<WindowSales> salesInWindow(DateTime from, DateTime to) async {
    final rows = await customSelect(
      "SELECT CASE WHEN status = 'voided' THEN NULL ELSE payment_method END "
      '    AS method, '
      '  COUNT(*) AS c, '
      '  COALESCE(SUM(total), 0.0) AS total, '
      '  COALESCE(SUM(tax_total), 0.0) AS tax, '
      '  COALESCE(SUM(tip_amount), 0.0) AS tips '
      'FROM orders '
      'WHERE created_at >= ? AND created_at < ? '
      "  AND status IN ('completed', 'refunded', 'voided') "
      'GROUP BY method',
      variables: [Variable(from), Variable(to)],
      readsFrom: {orders},
    ).get();
    final byMethod = <String, MethodSales>{};
    var voidedCount = 0;
    var voidedTotal = 0.0;
    for (final r in rows) {
      final method = r.read<String?>('method');
      if (method == null) {
        voidedCount = r.read<int>('c');
        voidedTotal = _r2(r.read<double>('total'));
      } else {
        byMethod[method] = MethodSales(
          count: r.read<int>('c'),
          total: _r2(r.read<double>('total')),
          tax: _r2(r.read<double>('tax')),
          tips: _r2(r.read<double>('tips')),
        );
      }
    }
    return WindowSales(
      byMethod: byMethod,
      voidedCount: voidedCount,
      voidedTotal: voidedTotal,
    );
  }

  /// One aggregate over refunds handed out in the window (by
  /// returns.created_at, via idx_returns_created_at), grouped by the
  /// original order's payment method (joined by primary key), whatever
  /// the order's date or current status.
  Future<WindowRefunds> refundsInWindow(DateTime from, DateTime to) async {
    final rows = await customSelect(
      'SELECT o.payment_method AS method, COUNT(*) AS c, '
      '  COALESCE(SUM(r.amount), 0.0) AS amount, '
      '  COALESCE(SUM(r.tip_amount), 0.0) AS tips '
      'FROM returns r JOIN orders o ON o.id = r.order_id '
      'WHERE r.created_at >= ? AND r.created_at < ? '
      'GROUP BY o.payment_method',
      variables: [Variable(from), Variable(to)],
      readsFrom: {returns, orders},
    ).get();
    return WindowRefunds(byMethod: {
      for (final r in rows)
        r.read<String>('method'): MethodRefunds(
          count: r.read<int>('c'),
          amount: _r2(r.read<double>('amount')),
          tips: _r2(r.read<double>('tips')),
        ),
    });
  }

  /// Both window aggregates — everything the close screen shows.
  Future<ShiftFigures> figuresForWindow(DateTime from, DateTime to) async =>
      ShiftFigures(
        sales: await salesInWindow(from, to),
        refunds: await refundsInWindow(from, to),
      );
}
