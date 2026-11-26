import 'package:drift/drift.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/daos/orders_dao.dart';
import 'package:pos_app/core/database/tables/orders_table.dart';
import 'package:pos_app/core/database/tables/returns_table.dart';
import 'package:pos_app/core/database/tables/shifts_table.dart';
import 'package:pos_app/core/utils/money.dart';

part 'shifts_dao.g.dart';

/// Thrown when a shift operation does not fit the current shift state:
/// opening while one is open, or closing one that is missing or closed.
class ShiftStateException implements Exception {
  const ShiftStateException(this.message);
  final String message;
  @override
  String toString() => 'ShiftStateException: $message';
}

// ── Result types ─────────────────────────────────────────────────────────
//
// Every amount is already passed through roundMoney.

/// One payment method's slice of a money flow (sales, refunds or voids).
class MethodFlow {
  const MethodFlow({
    required this.count,
    required this.amount,
    required this.tips,
    required this.tax,
  });
  static const zero = MethodFlow(count: 0, amount: 0, tips: 0, tax: 0);

  final int count;

  /// The tip-free part (orders.total, returns.amount, or what a void handed
  /// back of the total).
  final double amount;

  /// The tip part.
  final double tips;

  /// The tax inside [amount]: for sales the order's tax_total, for refunds
  /// and voids the same share of it as [amount] is of the order total.
  final double tax;

  /// Cash that moved: amount + tips.
  double get total => roundMoney(amount + tips);
}

/// A money flow in a window, by payment method (trimmed, lower-case, blank
/// read as cash). Methods with nothing in the window are absent.
class FlowByMethod {
  const FlowByMethod(this.byMethod);
  final Map<String, MethodFlow> byMethod;

  MethodFlow get cash => byMethod['cash'] ?? MethodFlow.zero;
  MethodFlow operator [](String method) => byMethod[method] ?? MethodFlow.zero;

  int get count => byMethod.values.fold(0, (s, m) => s + m.count);
  double get amount =>
      roundMoney(byMethod.values.fold(0.0, (s, m) => s + m.amount));
  double get tips => roundMoney(byMethod.values.fold(0.0, (s, m) => s + m.tips));
  double get tax => roundMoney(byMethod.values.fold(0.0, (s, m) => s + m.tax));
  double get total => roundMoney(amount + tips);
}

/// Everything the close screen shows for one window. See [ShiftsDao] for
/// the rules; in short: sales gross by order time, money out by event time.
class ShiftFigures {
  const ShiftFigures({
    required this.from,
    required this.to,
    required this.sales,
    required this.refunds,
    required this.voids,
  });

  /// The window, [from, to).
  final DateTime from;
  final DateTime to;

  /// Orders rung up in the window: completed, refunded and voided alike.
  final FlowByMethod sales;

  /// Refunds handed out in the window.
  final FlowByMethod refunds;

  /// Voids made in the window: what each handed back.
  final FlowByMethod voids;

  // Drawer (cash only).
  double get cashSales => sales.cash.amount;
  double get cashTips => sales.cash.tips;
  double get cashRefunds => refunds.cash.total;
  double get cashVoids => voids.cash.total;

  /// opening + cash sales + cash tips − cash refunds − cash voids − paid out.
  double expectedCash({required double openingCash, double paidOut = 0}) =>
      roundMoney(roundMoney(openingCash) +
          cashSales +
          cashTips -
          cashRefunds -
          cashVoids -
          roundMoney(paidOut));

  // Sales − Refunds = Net, all methods (tips are never in these).
  double get grossSales => sales.amount;
  double get refundedSales => roundMoney(refunds.amount + voids.amount);
  double get netSales => roundMoney(grossSales - refundedSales);

  /// Tax on the window's sales, before refunds and voids.
  double get grossTax => sales.tax;

  /// The tax share of the window's refunds and voids.
  double get refundedTax => roundMoney(refunds.tax + voids.tax);

  /// grossTax − refundedTax: the figure to show as tax.
  double get netTax => roundMoney(grossTax - refundedTax);

  // Tips, all methods.
  double get tipsCollected => sales.tips;
  double get tipsReturned => roundMoney(refunds.tips + voids.tips);
  double get netTips => roundMoney(tipsCollected - tipsReturned);
}

/// A computed close: the figures plus the drawer arithmetic.
///
/// Rounding rule (use it everywhere in the EOD flow): every aggregate and
/// [expectedCash] is roundMoney'd here; [countedCash] and [paidOut] are
/// roundMoney'd on input; [overShort] = roundMoney(counted − expected);
/// compare money in whole cents ([overShortCents]), never with `==` on
/// doubles. A close may be uncounted ([countedCash] null): then [counted]
/// is false and [overShort] / [overShortCents] are null.
class ShiftClose {
  const ShiftClose({
    required this.shiftId,
    required this.openingCash,
    required this.paidOut,
    required this.countedCash,
    required this.figures,
  });

  final int shiftId;
  final double openingCash;
  final double paidOut;
  /// The drawer as counted, or null when the close was not counted.
  final double? countedCash;
  final ShiftFigures figures;

  bool get counted => countedCash != null;

  double get expectedCash =>
      figures.expectedCash(openingCash: openingCash, paidOut: paidOut);

  /// counted − expected, or null when not counted.
  double? get overShort {
    final c = countedCash;
    return c == null ? null : roundMoney(c - expectedCash);
  }

  int? get overShortCents {
    final o = overShort;
    return o == null ? null : (o * 100).round();
  }
}

DateTime _wholeSecond(DateTime t) => DateTime.fromMillisecondsSinceEpoch(
    t.millisecondsSinceEpoch ~/ 1000 * 1000);

DateTime _latest(Iterable<DateTime> ts) =>
    ts.reduce((a, b) => a.isAfter(b) ? a : b);

/// Till sessions (open → end-of-day close) and the window aggregates the
/// close is computed from.
///
/// **Windows.** Shift windows are half-open, [from, to), in whole seconds,
/// and contiguous: a shift's window starts where the previous shift's
/// closed (its `closed_at`), or at its own `opened_at` for the first shift
/// ever, and ends at its own `closed_at`. Every sale, refund and void
/// therefore lands in exactly one window — one made in the same second as
/// a close belongs to the next shift. If the clock is set back, `closed_at`
/// is clamped to no earlier than the window start (and `opened_at`), so
/// windows never overlap; activity stamped before the start (by a clock
/// that went backwards) falls in an already closed window and is not
/// counted again.
///
/// **Money in / out — one rule: sales gross by order time, money out by
/// event time.**
///  * Sales: Σ orders.total (and tip, tax) of orders created in the window
///    with status completed, refunded or voided. Held orders were never
///    paid.
///  * Refunds: Σ returns.amount + returns.tip_amount of returns created in
///    the window, under the original order's payment method, whatever the
///    sale's date.
///  * Voids: orders voided in the window (`voided_at`), each handing back
///    total + tip − what earlier refunds already returned.
///  So a 100 sale refunded 20 then voided in one shift nets to 0, and a sale
///  voided in a later shift shows up as money out in that later shift.
///  Voids made before schema v16 have no `voided_at`; they predate every
///  shift and are ignored.
///  * Imported orders (invoice prefix `IMP`) are history, not till
///    activity, and are left out of everything here — with their refunds and
///    voids.
@DriftAccessor(tables: [Shifts, Orders, Returns])
class ShiftsDao extends DatabaseAccessor<AppDatabase> with _$ShiftsDaoMixin {
  ShiftsDao(super.db);

  // ── Lifecycle ──────────────────────────────────────────────────────────

  SimpleSelectStatement<$ShiftsTable, Shift> _open() =>
      select(shifts)
        ..where((s) => s.closedAt.isNull())
        ..limit(1);

  /// Opens a new shift and returns its id. Throws [ShiftStateException] if
  /// one is already open — at most one open shift exists at a time (also
  /// enforced by the unique index idx_shifts_one_open).
  Future<int> openShift({required double openingCash, DateTime? openedAt}) =>
      transaction(() async {
        final open = await _open().getSingleOrNull();
        if (open != null) {
          throw ShiftStateException(
              'Shift #${open.id} is still open; close it first');
        }
        return into(shifts).insert(ShiftsCompanion.insert(
          openingCash: Value(roundMoney(openingCash)),
          openedAt: openedAt == null
              ? const Value.absent()
              : Value(_wholeSecond(openedAt)),
        ));
      });

  /// The open shift, or null.
  Future<Shift?> currentShift() => _open().getSingleOrNull();

  Stream<Shift?> watchCurrentShift() => _open().watchSingleOrNull();

  /// The most recently closed shift, counted or not.
  Future<Shift?> lastClosedShift() async {
    final rows = await closedShifts(limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  /// The most recent close whose drawer was counted — its `countedCash` is
  /// the natural default for the next shift's opening cash. Walks
  /// idx_shifts_closed_at newest first and stops at the first counted one.
  Future<Shift?> lastCountedShift() => (select(shifts)
        ..where((s) => s.closedAt.isNotNull() & s.countedCash.isNotNull())
        ..orderBy([
          (s) => OrderingTerm.desc(s.closedAt),
          (s) => OrderingTerm.desc(s.id),
        ])
        ..limit(1))
      .getSingleOrNull();

  /// Closed shifts, newest close first.
  Future<List<Shift>> closedShifts({int limit = 30}) => (select(shifts)
        ..where((s) => s.closedAt.isNotNull())
        ..orderBy([
          (s) => OrderingTerm.desc(s.closedAt),
          (s) => OrderingTerm.desc(s.id),
        ])
        ..limit(limit))
      .get();

  /// Where [shift]'s window starts: the previous shift's close, else its
  /// own opening.
  Future<DateTime> windowStart(Shift shift) async {
    final prev = await (select(shifts)
          ..where((s) => s.id.isSmallerThanValue(shift.id))
          ..orderBy([(s) => OrderingTerm.desc(s.id)])
          ..limit(1))
        .getSingleOrNull();
    return prev?.closedAt ?? shift.openedAt;
  }

  Future<Shift> _require(int id) async {
    final shift = await (select(shifts)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    if (shift == null) throw ShiftStateException('Shift #$id not found');
    return shift;
  }

  Future<ShiftClose> _compute(Shift shift,
      {DateTime? at, required double paidOut, required double? countedCash}) async {
    final from = await windowStart(shift);
    final to = _latest(
        [_wholeSecond(at ?? DateTime.now()), from, shift.openedAt]);
    return ShiftClose(
      shiftId: shift.id,
      openingCash: shift.openingCash,
      paidOut: roundMoney(paidOut),
      countedCash: countedCash == null ? null : roundMoney(countedCash),
      figures: await figuresForWindow(from, to),
    );
  }

  /// The close of open shift [id] as it would be at [at] (default now),
  /// without writing anything — for the close screen while it is open.
  Future<ShiftClose> previewClose(int id,
          {DateTime? at, double paidOut = 0, double? countedCash}) =>
      transaction(() async {
        final shift = await _require(id);
        return _compute(shift,
            at: shift.closedAt ?? at, paidOut: paidOut, countedCash: countedCash);
      });

  /// Closes shift [id] at [at] (default now; whole seconds; clamped to the
  /// window start / opening if the clock went back). The figures are
  /// computed inside the same transaction as the write, so they cannot be
  /// stale; [summary] is called with them to build the frozen
  /// `summary_text`. Returns what was stored. Pass [countedCash] null for
  /// a close without a count: counted_cash stays NULL, everything else
  /// (expected cash included) is stored as usual.
  ///
  /// Throws [ShiftStateException] if the shift does not exist or is already
  /// closed.
  Future<ShiftClose> closeShift(
    int id, {
    required double? countedCash,
    double paidOut = 0,
    String? notes,
    DateTime? at,
    required String Function(ShiftClose close) summary,
  }) =>
      transaction(() async {
        final shift = await _require(id);
        if (shift.closedAt != null) {
          throw ShiftStateException('Shift #$id is already closed');
        }
        final close = await _compute(shift,
            at: at, paidOut: paidOut, countedCash: countedCash);
        final f = close.figures;
        await (update(shifts)..where((s) => s.id.equals(id))).write(
          ShiftsCompanion(
            closedAt: Value(f.to),
            cashSales: Value(f.cashSales),
            cashTips: Value(f.cashTips),
            cashRefunds: Value(f.cashRefunds),
            cashVoids: Value(f.cashVoids),
            paidOut: Value(close.paidOut),
            expectedCash: Value(close.expectedCash),
            countedCash: Value(close.countedCash),
            netSales: Value(f.netSales),
            summaryText: Value(summary(close)),
            notes: Value(notes),
          ),
        );
        return close;
      });

  // ── Window aggregates ──────────────────────────────────────────────────

  static const _notImported = "o.invoice_prefix != '$kImportedInvoicePrefix'";
  /// Same bucketing as [OrdersDao.methodSql], on alias `o`.
  static const _method =
      "COALESCE(NULLIF(LOWER(TRIM(o.payment_method)), ''), 'cash')";

  static FlowByMethod _flows(List<QueryRow> rows) => FlowByMethod({
        for (final r in rows)
          r.read<String>('method'): MethodFlow(
            count: r.read<int>('c'),
            amount: roundMoney(r.read<double>('amount')),
            tips: roundMoney(r.read<double>('tips')),
            tax: roundMoney(r.read<double>('tax')),
          ),
      });

  /// Orders rung up in [from, to), gross. One range seek on
  /// idx_orders_created_at.
  Future<FlowByMethod> salesInWindow(DateTime from, DateTime to) async =>
      _flows(await customSelect(
        'SELECT $_method AS method, COUNT(*) AS c, '
        '  COALESCE(SUM(total), 0.0) AS amount, '
        '  COALESCE(SUM(tip_amount), 0.0) AS tips, '
        '  COALESCE(SUM(tax_total), 0.0) AS tax '
        'FROM orders o '
        'WHERE created_at >= ? AND created_at < ? '
        "  AND status IN ('completed', 'refunded', 'voided') "
        '  AND $_notImported '
        'GROUP BY 1',
        variables: [Variable(from), Variable(to)],
        readsFrom: {orders},
      ).get());

  /// Refunds handed out in [from, to), under the original order's method.
  /// A range seek on idx_returns_created_at, then each order by primary key.
  Future<FlowByMethod> refundsInWindow(DateTime from, DateTime to) async =>
      _flows(await customSelect(
        'SELECT $_method AS method, COUNT(*) AS c, '
        '  COALESCE(SUM(r.amount), 0.0) AS amount, '
        '  COALESCE(SUM(r.tip_amount), 0.0) AS tips, '
        '  COALESCE(SUM(CASE WHEN o.total > 0 '
        '    THEN r.amount / o.total * o.tax_total ELSE 0.0 END), 0.0) AS tax '
        'FROM returns r JOIN orders o ON o.id = r.order_id '
        'WHERE r.created_at >= ? AND r.created_at < ? AND $_notImported '
        'GROUP BY 1',
        variables: [Variable(from), Variable(to)],
        readsFrom: {returns, orders},
      ).get());

  /// Voids made in [from, to): each hands back total + tip less what its
  /// earlier refunds returned. A range seek on the partial index
  /// idx_orders_voided_at (only voided rows are in it), then each void's
  /// refunds by idx_returns_order_id.
  Future<FlowByMethod> voidsInWindow(DateTime from, DateTime to) async =>
      _flows(await customSelect(
        'SELECT method, COUNT(*) AS c, '
        '  COALESCE(SUM(amount), 0.0) AS amount, '
        '  COALESCE(SUM(tips), 0.0) AS tips, '
        '  COALESCE(SUM(CASE WHEN total > 0 '
        '    THEN amount / total * tax_total ELSE 0.0 END), 0.0) AS tax '
        'FROM (SELECT $_method AS method, o.total, o.tax_total, '
        '    MAX(0.0, o.total - (SELECT COALESCE(SUM(amount), 0.0) '
        '      FROM returns WHERE order_id = o.id)) AS amount, '
        '    MAX(0.0, o.tip_amount - (SELECT COALESCE(SUM(tip_amount), 0.0) '
        '      FROM returns WHERE order_id = o.id)) AS tips '
        '  FROM orders o '
        '  WHERE o.voided_at IS NOT NULL '
        '    AND o.voided_at >= ? AND o.voided_at < ? '
        "    AND o.status = 'voided' AND $_notImported) "
        'GROUP BY 1',
        variables: [Variable(from), Variable(to)],
        readsFrom: {orders, returns},
      ).get());

  /// All three flows for [from, to).
  Future<ShiftFigures> figuresForWindow(DateTime from, DateTime to) async =>
      ShiftFigures(
        from: from,
        to: to,
        sales: await salesInWindow(from, to),
        refunds: await refundsInWindow(from, to),
        voids: await voidsInWindow(from, to),
      );
}
