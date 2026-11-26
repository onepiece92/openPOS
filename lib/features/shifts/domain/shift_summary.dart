import 'package:intl/intl.dart';

import 'package:pos_app/core/database/daos/shifts_dao.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/core/utils/money.dart';

/// Receipt columns for a paper width: 58mm prints 32, 80mm prints 48.
int summaryColumnsFor(int paperMm) => paperMm == 58 ? 32 : 48;

/// Shown in place of an amount when the drawer was not counted.
const kNotCounted = 'Not counted';

/// "Over", "Short" or "Balanced" for an over/short in whole cents.
String overShortLabel(int cents) =>
    cents > 0 ? 'Over' : (cents < 0 ? 'Short' : 'Balanced');

/// "10 Jun 2026 09:30" — unambiguous in any locale.
String summaryTime(DateTime t) => DateFormat('d MMM yyyy HH:mm').format(t);

/// "10 Jun 2026, 09:00 to 21:30" on one day, else both full dates.
String summaryRange(DateTime from, DateTime to) {
  final sameDay =
      from.year == to.year && from.month == to.month && from.day == to.day;
  if (sameDay) {
    return '${DateFormat('d MMM yyyy, HH:mm').format(from)} to '
        '${DateFormat('HH:mm').format(to)}';
  }
  return '${summaryTime(from)} to ${summaryTime(to)}';
}

/// The plain-text end-of-day summary, at most [columns] wide (32 or 48).
/// Pure: called once inside `ShiftsDao.closeShift` and stored; it is never
/// rebuilt for a closed day.
///
/// Tax note: the "(net)" tax here is the DAO's net tax (per payment method
/// and per refund, rounded by the window query). The dashboard's VAT rounds
/// per order (ROUND(tax_total * kept, 2)) and books a refund to the day of
/// the original sale, so for the same day the two can differ by a cent or
/// two. Not aligned: the day close books money by event time.
///
/// Money is shown with the shop's own symbol ([fmt]) and tax name
/// ([taxName]). Amounts that come back out of the totals or the drawer are
/// shown negative.
String buildShiftSummary(
  ShiftClose close, {
  required String shopName,
  required String taxName,
  required CurrencyFormatter fmt,
  int columns = 32,
  String? notes,
}) {
  final f = close.figures;
  final out = <String>[];
  String money(double v) => fmt.format(v == 0 ? 0.0 : v);
  String neg(double v) => money(v == 0 ? 0.0 : -v);

  void rule([String ch = '-']) => out.add(ch * columns);
  void row(String label, String value) => out.add(_row(label, value, columns));
  void centre(String text) {
    for (final l in _wrap(text, columns)) {
      out.add(' ' * ((columns - l.length) ~/ 2) + l);
    }
  }

  centre(shopName.trim().isEmpty ? 'My Store' : shopName.trim());
  centre('END OF DAY');
  rule('=');
  out
    ..add('From: ${summaryTime(f.from)}')
    ..add('To:   ${summaryTime(f.to)}');
  rule();

  row('Sales', money(f.grossSales));
  row('- Refunds', neg(f.refunds.amount));
  row('- Voids', neg(f.voids.amount));
  row('= Net sales', money(f.netSales));
  {
    // Keep "(net)" when a long tax name has to be cut.
    final taxValue = money(f.netTax);
    final room = columns - taxValue.length - 1 - ' (net)'.length;
    final name = taxName.length <= room
        ? taxName
        : (room > 0 ? taxName.substring(0, room) : '');
    row('$name (net)', taxValue);
  }
  // Tips already taken are money in the drawer whatever the Tips switch
  // says now, so the line shows whenever the window has any.
  if (f.tipsCollected != 0 || f.tipsReturned != 0) {
    row('Tips (net)', money(f.netTips));
  }
  row('Orders', '${f.sales.count}');
  rule();

  out.add('BY PAYMENT METHOD');
  final methods = {
    ...f.sales.byMethod.keys,
    ...f.refunds.byMethod.keys,
    ...f.voids.byMethod.keys,
  }.toList()
    ..sort((a, b) => a == 'cash' ? -1 : (b == 'cash' ? 1 : a.compareTo(b)));
  if (methods.isEmpty) out.add('None');
  for (final m in methods) {
    final net =
        roundMoney(f.sales[m].total - f.refunds[m].total - f.voids[m].total);
    row(_title(m), money(net));
  }
  rule();

  out.add('CASH DRAWER');
  row('Opening cash', money(close.openingCash));
  row('+ Cash sales', money(f.cashSales));
  if (f.cashTips != 0) row('+ Cash tips', money(f.cashTips));
  row('- Cash refunds', neg(f.cashRefunds));
  row('- Cash voids', neg(f.cashVoids));
  row('- Paid out', neg(close.paidOut));
  row('= Expected cash', money(close.expectedCash));
  final counted = close.countedCash;
  final cents = close.overShortCents;
  if (counted == null || cents == null) {
    // Not counted: there is nothing to be over or short against.
    row('Counted cash', kNotCounted);
  } else {
    row('Counted cash', money(counted));
    row(overShortLabel(cents), cents == 0 ? '' : money(close.overShort!.abs()));
  }

  final note = notes?.trim() ?? '';
  if (note.isNotEmpty) {
    rule();
    out.add('NOTES');
    out.addAll(_wrap(note, columns));
  }
  rule('=');
  return out.join('\n');
}

String _title(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String _row(String label, String value, int columns) {
  // A value wider than the paper is cut with a "~" rather than wrapped.
  if (value.length > columns) value = '${value.substring(0, columns - 1)}~';
  if (value.isEmpty) {
    return label.length > columns ? label.substring(0, columns) : label;
  }
  final room = columns - value.length - 1;
  var l = label;
  if (l.length > room) l = room > 0 ? l.substring(0, room) : '';
  return '$l${' ' * (columns - l.length - value.length)}$value';
}

/// Word-wraps [text] to [width]; a word longer than a line is split.
List<String> _wrap(String text, int width) {
  final lines = <String>[];
  for (final para in text.split(RegExp(r'\r?\n'))) {
    var line = '';
    for (var word in para.trim().split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      while (word.length > width) {
        if (line.isNotEmpty) {
          lines.add(line);
          line = '';
        }
        lines.add(word.substring(0, width));
        word = word.substring(width);
      }
      if (line.isEmpty) {
        line = word;
      } else if (line.length + 1 + word.length <= width) {
        line = '$line $word';
      } else {
        lines.add(line);
        line = word;
      }
    }
    if (line.isNotEmpty || para.trim().isEmpty) lines.add(line);
  }
  return lines;
}
