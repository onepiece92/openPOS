import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/daos/shifts_dao.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/core/utils/money.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/shifts/data/shift_service.dart';
import 'package:pos_app/features/shifts/domain/shift_summary.dart';
import 'package:pos_app/features/shifts/presentation/shift_summary_panel.dart';
import 'package:pos_app/features/shifts/shift_settings.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

/// Parses a money field: null when empty, malformed, negative or too large.
///
/// A comma is accepted as the decimal separator ("12,5" is 12.5). When a dot
/// is present too, commas are thousands separators and are dropped.
double? parseMoneyField(String raw) {
  var t = raw.trim();
  t = t.contains('.') ? t.replaceAll(',', '') : t.replaceAll(',', '.');
  final v = double.tryParse(t);
  if (v == null || !v.isFinite || v < 0 || v > kMaxMoneyAmount) return null;
  return roundMoney(v);
}

/// A plain sentence for an error shown to the shopkeeper.
String friendlyShiftError(Object e) => e is ShiftStateException
    ? 'The till changed. Pull down to refresh and try again.'
    : 'Something went wrong. Please try again.';

const kBelowZeroNote =
    'Net is below zero because a sale from an earlier day was voided or '
    'refunded.';

/// Close day: open the till, watch the live drawer figures, count the cash
/// and close. Selling is never blocked by any of this.
///
/// The figures are read with `previewClose` once when the screen opens, on
/// pull-to-refresh, and just before the close is confirmed — never on a
/// timer and never on each keystroke (typing only redoes the drawer
/// arithmetic on the figures already loaded).
class CloseDayScreen extends ConsumerStatefulWidget {
  const CloseDayScreen({super.key});

  @override
  ConsumerState<CloseDayScreen> createState() => _CloseDayScreenState();
}

class _CloseDayScreenState extends ConsumerState<CloseDayScreen> {
  final _opening = TextEditingController();
  final _paidOut = TextEditingController();
  final _counted = TextEditingController();
  final _notes = TextEditingController();

  bool _loading = true;
  bool _busy = false;
  Shift? _shift;
  ShiftFigures? _figures;
  GapInfo? _gap;
  Shift? _justClosed;

  @override
  void initState() {
    super.initState();
    _load(firstLoad: true);
  }

  @override
  void dispose() {
    _opening.dispose();
    _paidOut.dispose();
    _counted.dispose();
    _notes.dispose();
    super.dispose();
  }

  ShiftsDao get _dao => ref.read(databaseProvider).shiftsDao;

  Future<void> _load({bool firstLoad = false}) async {
    try {
      final shift = await _dao.currentShift();
      ShiftFigures? figures;
      GapInfo? gap;
      if (shift != null) {
        figures = (await _dao.previewClose(shift.id)).figures;
      } else {
        gap = await ref.read(shiftServiceProvider).gapBeforeOpen();
        if (firstLoad || _opening.text.isEmpty) {
          final last = await _dao.lastClosedShift();
          final c = last?.countedCash;
          _opening.text = c == null ? '' : c.toStringAsFixed(2);
        }
      }
      if (!mounted) return;
      setState(() {
        _shift = shift;
        _figures = figures;
        _gap = gap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('Could not load the till. ${friendlyShiftError(e)}');
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  CurrencyFormatter get _fmt => ref.read(currencyFormatterProvider);

  Future<void> _open() async {
    final cash = parseMoneyField(_opening.text.isEmpty ? '0' : _opening.text);
    if (cash == null) {
      _toast('Enter the opening cash as a number');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(shiftServiceProvider).openTill(openingCash: cash);
      _opening.clear();
      await _load();
    } catch (e) {
      _toast('Could not open the till. ${friendlyShiftError(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Builds the summary callback with everything the frozen text needs.
  Future<String Function(ShiftClose, String)> _summaryBuilder() async {
    final settings = ref.read(settingsProvider);
    final taxName = await ref
        .read(shiftServiceProvider)
        .taxName(defaultTaxId: settings.defaultTaxId);
    final fmt = _fmt;
    final columns = summaryColumnsFor(settings.printerPaperWidth);
    final shop = settings.businessNameOrDefault;
    return (close, notes) => buildShiftSummary(close,
        shopName: shop,
        taxName: taxName,
        fmt: fmt,
        columns: columns,
        notes: notes);
  }

  Future<void> _keepSeparate() async {
    setState(() => _busy = true);
    try {
      final build = await _summaryBuilder();
      await ref.read(shiftServiceProvider).keepGapSeparate(summary: build);
      _toast('Saved as its own day. See History.');
      await _load(firstLoad: true);
    } catch (e) {
      _toast('Could not save it. ${friendlyShiftError(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  ShiftClose? _live() {
    final shift = _shift;
    final f = _figures;
    if (shift == null || f == null) return null;
    return ShiftClose(
      shiftId: shift.id,
      openingCash: shift.openingCash,
      paidOut: parseMoneyField(_paidOut.text) ?? 0,
      countedCash: parseMoneyField(_counted.text),
      figures: f,
    );
  }

  bool get _hasCount => parseMoneyField(_counted.text) != null;

  Future<void> _closeDay() async {
    final shift = _shift!;
    final paid = parseMoneyField(_paidOut.text.isEmpty ? '0' : _paidOut.text);
    final counted = parseMoneyField(_counted.text);
    if (paid == null || counted == null) {
      _toast('Check the paid out and counted cash amounts');
      return;
    }
    setState(() => _busy = true);
    try {
      // Fresh figures for the confirm: sales may have been made since the
      // screen opened.
      final fresh = await _dao.previewClose(shift.id,
          paidOut: paid, countedCash: counted);
      if (!mounted) return;
      setState(() => _figures = fresh.figures);
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Close day?'),
          content: Text(
            'Expected cash ${_fmt.format(fresh.expectedCash)}\n'
            'Counted cash ${_fmt.format(counted)}\n'
            '${_overShortText(fresh)}\n\n'
            'The day will be closed and cannot be reopened.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                key: const ValueKey('confirm-close'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Close day')),
          ],
        ),
      );
      if (ok != true) return;
      final build = await _summaryBuilder();
      final notes = _notes.text.trim();
      await _dao.closeShift(
        shift.id,
        countedCash: counted,
        paidOut: paid,
        notes: notes.isEmpty ? null : notes,
        summary: (c) => build(c, notes),
      );
      final closed = await _dao.lastClosedShift();
      if (!mounted) return;
      _paidOut.clear();
      _counted.clear();
      _notes.clear();
      setState(() => _justClosed = closed);
    } catch (e) {
      _toast('Could not close the day. ${friendlyShiftError(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _overShortText(ShiftClose c) {
    final cents = c.overShortCents;
    if (cents == null) return kNotCounted;
    final label = overShortLabel(cents);
    return cents == 0 ? label : '$label ${_fmt.format(c.overShort!.abs())}';
  }

  void _done() {
    setState(() {
      _justClosed = null;
      _loading = true;
    });
    _load(firstLoad: true);
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild if the gate flips while the screen is up.
    ref.watch(endOfDayEnabledProvider);
    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(
        title: const Text('Close day'),
        actions: [
          TextButton(
            key: const ValueKey('open-history'),
            onPressed: () => context.push(kCloseDayHistoryRoute),
            child: const Text('History'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: _justClosed != null
                    ? _afterClose(_justClosed!)
                    : (_shift == null ? _openForm() : _openDay()),
              ),
            ),
    );
  }

  // ── No shift open ────────────────────────────────────────────────────────

  List<Widget> _openForm() {
    final tt = Theme.of(context).textTheme;
    final msg = gapMessage(_gap);
    return [
      Text('Open the till', style: tt.titleLarge),
      const SizedBox(height: 4),
      const Text('No day is open. You can keep selling; sales made while the '
          'till is closed are counted in the next day you open.'),
      const SizedBox(height: 16),
      if (msg != null) ...[
        Card(
          key: const ValueKey('gap-card'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg, key: const ValueKey('gap-message')),
                if (_gap!.canKeepSeparate) ...[
                  const SizedBox(height: 8),
                  const Text(
                      'It has been a long time. You can save them as their '
                      'own closed day instead.'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: const ValueKey('keep-separate'),
                    onPressed: _busy ? null : _keepSeparate,
                    child: const Text('Keep them separate'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      _moneyField(_opening, 'Opening cash',
          helper: 'Cash counted at the last close'),
      const SizedBox(height: 16),
      FilledButton(
        key: const ValueKey('open-till'),
        onPressed: _busy ? null : _open,
        child: const Text('Open'),
      ),
    ];
  }

  // ── Shift open ───────────────────────────────────────────────────────────

  List<Widget> _openDay() {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final shift = _shift!;
    final live = _live()!;
    final f = live.figures;
    final fmt = _fmt;
    final negative = f.netSales < 0 || f.netTax < 0;

    Widget row(String label, String value, {bool bold = false, Key? key}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: bold
                          ? tt.bodyLarge?.copyWith(fontWeight: FontWeight.w700)
                          : tt.bodyLarge)),
              Text(value,
                  key: key,
                  style: bold
                      ? tt.bodyLarge?.copyWith(fontWeight: FontWeight.w700)
                      : tt.bodyLarge),
            ],
          ),
        );

    return [
      Text('Open since ${summaryTime(shift.openedAt)}', style: tt.titleLarge),
      Text('Pull down to refresh the figures.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      const SizedBox(height: 16),
      row('Net sales', fmt.format(f.netSales),
          key: const ValueKey('net-sales')),
      row('Orders', '${f.sales.count}'),
      if (negative)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(kBelowZeroNote,
              key: const ValueKey('below-zero-note'),
              style: tt.bodySmall?.copyWith(color: cs.error)),
        ),
      const Divider(height: 24),
      Text('Cash drawer', style: tt.titleMedium),
      row('Opening cash', fmt.format(live.openingCash)),
      row('Cash sales', fmt.format(f.cashSales)),
      if (f.cashTips != 0) row('Cash tips', fmt.format(f.cashTips)),
      row('Cash refunds', fmt.format(f.cashRefunds)),
      row('Cash voids', fmt.format(f.cashVoids)),
      row('Paid out', fmt.format(live.paidOut)),
      row('Expected cash', fmt.format(live.expectedCash),
          bold: true, key: const ValueKey('expected')),
      const SizedBox(height: 12),
      _moneyField(_paidOut, 'Paid out', onChanged: (_) => setState(() {})),
      const SizedBox(height: 12),
      _moneyField(_counted, 'Counted cash', onChanged: (_) => setState(() {})),
      const SizedBox(height: 8),
      if (live.overShortCents case final cents?)
        row(overShortLabel(cents),
            cents == 0 ? '' : fmt.format(live.overShort!.abs()),
            bold: true, key: const ValueKey('over-short'))
      else
        Text('Enter the counted cash to see over or short.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('notes'),
        controller: _notes,
        maxLines: 3,
        decoration: const InputDecoration(
            labelText: 'Notes (optional)', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 16),
      FilledButton(
        key: const ValueKey('close-day'),
        onPressed: (_busy || !_hasCount) ? null : _closeDay,
        child: const Text('Close day'),
      ),
    ];
  }

  // ── After close ──────────────────────────────────────────────────────────

  List<Widget> _afterClose(Shift closed) {
    final tt = Theme.of(context).textTheme;
    return [
      Text('Day closed', style: tt.titleLarge),
      const SizedBox(height: 12),
      ShiftSummaryPanel(
        text: closed.summaryText ?? '',
        subject:
            'End of day, ${summaryTime(closed.closedAt ?? closed.openedAt)}',
      ),
      const SizedBox(height: 16),
      OutlinedButton(
        key: const ValueKey('done'),
        onPressed: _done,
        child: const Text('Done'),
      ),
    ];
  }

  Widget _moneyField(TextEditingController c, String label,
          {String? helper, ValueChanged<String>? onChanged}) =>
      TextField(
        key: ValueKey('field-$label'),
        controller: c,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
        ],
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          border: const OutlineInputBorder(),
        ),
      );
}
