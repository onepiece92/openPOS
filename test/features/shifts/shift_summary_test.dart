import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/daos/shifts_dao.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/shifts/domain/shift_summary.dart';

MethodFlow _flow(int c, double amount, {double tips = 0, double tax = 0}) =>
    MethodFlow(count: c, amount: amount, tips: tips, tax: tax);

ShiftClose _close({
  Map<String, MethodFlow> sales = const {},
  Map<String, MethodFlow> refunds = const {},
  Map<String, MethodFlow> voids = const {},
  double opening = 100,
  double paidOut = 0,
  double? counted = 0,
}) =>
    ShiftClose(
      shiftId: 1,
      openingCash: opening,
      paidOut: paidOut,
      countedCash: counted,
      figures: ShiftFigures(
        from: DateTime(2026, 6, 10, 9),
        to: DateTime(2026, 6, 10, 21, 30),
        sales: FlowByMethod(sales),
        refunds: FlowByMethod(refunds),
        voids: FlowByMethod(voids),
      ),
    );

final _fmt = CurrencyFormatter(symbol: r'$ ', locale: 'en_US');

String _build(ShiftClose c,
        {int columns = 32, String? notes, String shop = 'Corner Cafe'}) =>
    buildShiftSummary(c,
        shopName: shop,
        taxName: 'VAT',
        fmt: _fmt,
        columns: columns,
        notes: notes);

void main() {
  final busy = _close(
    sales: {
      'cash': _flow(8, 400, tips: 20, tax: 40),
      'card': _flow(4, 300, tips: 10, tax: 30),
    },
    refunds: {'cash': _flow(1, 25, tax: 2.5)},
    voids: {'card': _flow(1, 15, tax: 1.5)},
    paidOut: 30,
    counted: 463,
  );

  test('fits 32 and 48 columns, with the symbol and the tax name', () {
    for (final cols in [32, 48]) {
      final text = _build(busy,
          columns: cols,
          notes: 'Float topped up. A very long note that has to wrap onto '
              'more than one line.');
      for (final l in text.split('\n')) {
        expect(l.length, lessThanOrEqualTo(cols), reason: '"$l" at $cols');
      }
      expect(text, contains(r'$ 700.00'));
      expect(text, contains('VAT (net)'));
      expect(text, contains('Corner Cafe'));
      expect(text, contains('NOTES'));
    }
  });

  test('not counted: "Counted cash  Not counted" and no over/short line', () {
    final text = _build(_close(
        sales: {'cash': _flow(2, 50)}, opening: 10, counted: null));
    final lines = text.split('\n');
    expect(lines, contains('Counted cash         Not counted'));
    expect(lines.any((l) => l.startsWith('= Expected cash')), isTrue);
    for (final w in ['Balanced', 'Over', 'Short']) {
      expect(lines.any((l) => l.startsWith(w)), isFalse, reason: w);
    }
  });

  test('below zero: the explanation is in NOTES, before the user note', () {
    final text = _build(
        _close(voids: {'cash': _flow(1, 30, tax: 3)}),
        notes: 'Counted twice');
    final lines = text.split('\n');
    final at = lines.indexOf('NOTES');
    expect(at, greaterThan(0));
    expect(lines.sublist(at + 1).join(' '),
        startsWith('Net is below zero because a sale from an earlier day'));
    expect(text, contains('Counted twice'));
    expect(text.indexOf('Net is below zero'),
        lessThan(text.indexOf('Counted twice')));
    // Not below zero: no NOTES unless the user wrote one.
    expect(_build(_close(sales: {'cash': _flow(1, 10)})),
        isNot(contains('NOTES')));
  });

  test('tips handed back are their own drawer line; it all adds up', () {
    final c = _close(
      sales: {'cash': _flow(2, 50, tips: 6)},
      refunds: {'cash': _flow(1, 0, tips: 6)},
      voids: {'cash': _flow(1, 10, tips: 2)},
      opening: 0,
    );
    final lines = _build(c).split('\n');
    String line(String l) => lines.firstWhere((x) => x.startsWith(l));
    expect(line('- Refunds'), endsWith(r'$ 0.00'));
    expect(line('- Cash refunds'), endsWith(r'$ 0.00'));
    expect(line('- Cash voids'), endsWith(r'-$ 10.00'));
    expect(line('- Cash tips returned'), endsWith(r'-$ 8.00'));
    // 0 + 50 + 6 - 0 - 10 - 8 = 38
    expect(line('= Expected cash'), endsWith(r'$ 38.00'));
    expect(c.expectedCash, 38);
    expect(_build(_close(sales: {'cash': _flow(1, 10)})),
        isNot(contains('tips returned')));
  });

  test('the Tips line shows only when the window has tips', () {
    expect(_build(_close(sales: {'cash': _flow(1, 10)})),
        isNot(contains('Tips (net)')));
    expect(_build(_close(sales: {'card': _flow(1, 10, tips: 2)})),
        contains('Tips (net)'));
    // A tip handed back in the window still shows (net 0 or below).
    expect(
        _build(_close(refunds: {'cash': _flow(1, 0, tips: 2)})),
        contains('Tips (net)'));
  });

  test('the 32-column sample is exactly this', () {
    expect(_build(busy, notes: 'Float topped up'), r'''
          Corner Cafe
           END OF DAY
================================
From: 10 Jun 2026 09:00
To:   10 Jun 2026 21:30
--------------------------------
Sales                   $ 700.00
- Refunds               -$ 25.00
- Voids                 -$ 15.00
= Net sales             $ 660.00
VAT (net)                $ 66.00
Tips (net)               $ 30.00
Orders                        12
--------------------------------
BY PAYMENT METHOD
Cash                    $ 395.00
Card                    $ 295.00
--------------------------------
CASH DRAWER
Opening cash            $ 100.00
+ Cash sales            $ 400.00
+ Cash tips              $ 20.00
- Cash refunds          -$ 25.00
- Cash voids              $ 0.00
- Paid out              -$ 30.00
= Expected cash         $ 465.00
Counted cash            $ 463.00
Short                     $ 2.00
--------------------------------
NOTES
Float topped up
================================''');
  });

  test('Sales - Refunds - Voids = Net sales, net tax and tips', () {
    final text = _build(busy);
    expect(text, contains(r'$ 700.00'));
    expect(text, contains(r'-$ 25.00'));
    expect(text, contains(r'-$ 15.00'));
    expect(text, contains(r'$ 660.00')); // net sales
    expect(text, contains(r'$ 66.00')); // net tax 70 - 4
    expect(text, contains('Orders'));
  });

  test('negative net sales and tax are shown with a minus', () {
    final c = _close(voids: {'cash': _flow(1, 50, tax: 5)}, counted: 50);
    final text = _build(c, columns: 48);
    final lines = text.split('\n');
    expect(lines.firstWhere((l) => l.startsWith('= Net sales')),
        endsWith(r'-$ 50.00'));
    expect(lines.firstWhere((l) => l.startsWith('VAT (net)')),
        endsWith(r'-$ 5.00'));
  });

  test('payment methods: cash first, net of refunds and voids', () {
    final lines = _build(busy).split('\n');
    final i = lines.indexOf('BY PAYMENT METHOD');
    expect(lines[i + 1], startsWith('Cash'));
    expect(lines[i + 1], endsWith(r'$ 395.00')); // 420 - 25
    expect(lines[i + 2], startsWith('Card'));
    expect(lines[i + 2], endsWith(r'$ 295.00')); // 310 - 15
  });

  test('drawer section; cash tips only when non-zero', () {
    final text = _build(busy);
    expect(text, contains('+ Cash tips'));
    expect(text, contains('= Expected cash'));
    expect(text, contains(r'$ 465.00')); // 100+400+20-25-0-30
    expect(text, contains('Short'));
    final noTips = _build(_close(sales: {'cash': _flow(1, 10)}, counted: 110));
    expect(noTips, isNot(contains('Cash tips')));
    expect(noTips, contains('Balanced'));
  });

  test('over/short labels are decided in whole cents', () {
    expect(overShortLabel(0), 'Balanced');
    expect(overShortLabel(1), 'Over');
    expect(overShortLabel(-1), 'Short');
    // 100.1 + 0.2 is 100.30000000000001 in doubles.
    final c =
        _close(sales: {'cash': _flow(1, 0.2)}, opening: 100.1, counted: 100.3);
    expect(c.overShortCents, 0);
    expect(_build(c), contains('Balanced'));
    final over =
        _close(sales: {'cash': _flow(1, 0.2)}, opening: 100.1, counted: 100.31);
    expect(over.overShortCents, 1);
    expect(_build(over), contains('Over'));
    final short =
        _close(sales: {'cash': _flow(1, 0.2)}, opening: 100.1, counted: 100.29);
    expect(short.overShortCents, -1);
    expect(_build(short), contains('Short'));
  });

  test('a long shop name wraps and an empty one falls back', () {
    final text =
        _build(busy, shop: 'The Extraordinarily Long Named Shop of Town');
    for (final l in text.split('\n')) {
      expect(l.length, lessThanOrEqualTo(32));
    }
    expect(_build(busy, shop: '  '), contains('My Store'));
  });

  test('huge amounts keep every line inside the columns', () {
    final c =
        _close(sales: {'cash': _flow(1, 9999999.99)}, opening: 9999999.99);
    for (final l in _build(c).split('\n')) {
      expect(l.length, lessThanOrEqualTo(32), reason: l);
    }
  });

  test('columns for paper, range text', () {
    expect(summaryColumnsFor(58), 32);
    expect(summaryColumnsFor(80), 48);
    expect(
        summaryRange(DateTime(2026, 6, 10, 9), DateTime(2026, 6, 10, 21, 30)),
        '10 Jun 2026, 09:00 to 21:30');
    expect(summaryRange(DateTime(2026, 6, 10, 9), DateTime(2026, 6, 11, 2)),
        '10 Jun 2026 09:00 to 11 Jun 2026 02:00');
  });

  test('a long tax name is cut but keeps (net)', () {
    final c = _close(sales: {'cash': _flow(1, 10, tax: 1)});
    final text = buildShiftSummary(c,
        shopName: 'S',
        taxName: 'Goods and Services Tax Standard Rate',
        fmt: _fmt,
        columns: 32);
    final line = text
        .split('\n')
        .firstWhere((l) => l.contains('(net)') && !l.startsWith('Tips'));
    expect(line.length, 32);
    expect(line, contains(' (net) '));
    expect(line, endsWith(r'$ 1.00'));
  });

  test('a value wider than the paper is capped, never wrapped', () {
    final wide = CurrencyFormatter(
        symbol: 'EXTRAORDINARILYLONGSYMBOL ', locale: 'en_US');
    final text = buildShiftSummary(
        _close(sales: {'cash': _flow(1, 9999999.99)}),
        shopName: 'S',
        taxName: 'Tax',
        fmt: wide,
        columns: 32);
    for (final l in text.split('\n')) {
      expect(l.length, lessThanOrEqualTo(32), reason: l);
    }
    expect(text, contains('~'));
  });
}
