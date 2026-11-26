import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart' show TtfParser;
import 'package:pdf/widgets.dart' as pw;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/daos/shifts_dao.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/core/theme/tokens.dart';
import 'package:pos_app/core/utils/bundled_fonts.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/printing/domain/receipt_roll_pdf.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';
import 'package:pos_app/features/receipts/presentation/receipt_pdf_service.dart';
import 'package:pos_app/features/settings/domain/currencies.dart';
import 'package:pos_app/features/shifts/domain/shift_summary.dart';
import 'package:pos_app/features/shifts/presentation/shift_summary_panel.dart';

/// JetBrains Mono has no ৳ ₵ ₹ ₨ ₩ ₦ ₱ ฿, and the pdf package has no system
/// fallback: without the bundled OpenPOS Symbols fallback every receipt for
/// those shops drew a box where the currency symbol goes.

ReceiptBodyData _data() {
  final at = DateTime(2026, 4, 22, 14, 30);
  return ReceiptBodyData(
    order: Order(
      id: 42,
      status: 'completed',
      subtotal: 100.0,
      taxTotal: 13.0,
      discountTotal: 5.0,
      discountIsPercent: false,
      invoicePrefix: '',
      printCount: 1,
      total: 108.0,
      paymentMethod: 'cash',
      tenderedAmount: 120.0,
      changeAmount: 12.0,
      customerId: 3,
      pointsRedeemed: 10,
      loyaltyDiscount: 1.0,
      pointsEarned: 4,
      tipAmount: 0.0,
      notes: null,
      createdAt: at,
      updatedAt: at,
    ),
    items: const [
      OrderItem(
        id: 1,
        orderId: 42,
        productId: 7,
        productName: 'Coffee',
        unitPrice: 50.0,
        quantity: 2,
        unitLabel: '',
        unitsPerQty: 1.0,
        discount: 0.0,
        taxAmount: 13.0,
        lineTotal: 100.0,
      ),
    ],
    taxes: const [
      OrderTaxe(
        id: 1,
        orderId: 42,
        taxRateId: 1,
        taxRateName: 'VAT',
        taxRatePercent: 0.13,
        taxableAmount: 100.0,
        taxAmount: 13.0,
        isInclusive: false,
      ),
    ],
    businessName: 'Test Cafe',
    customer: Customer(
      id: 3,
      name: 'Asha',
      loyaltyPoints: 20,
      defaultDiscount: 0,
      defaultDiscountIsPercent: false,
      isTaxExempt: false,
      createdAt: at,
      updatedAt: at,
    ),
  );
}

/// Runs [build] and saves the PDF, returning the pdf package's
/// "Unable to find a font" warnings (it reports them with `print`).
Future<List<String>> _missingGlyphWarnings(
    Future<pw.Document> Function() build) async {
  final warnings = <String>[];
  await runZoned(
    () async => (await build()).save(),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        if (line.contains('Unable to find a font')) {
          warnings.add(line);
        } else {
          parent.print(zone, line);
        }
      },
    ),
  );
  return warnings;
}

CurrencyFormatter _fmt(String symbol, String code) =>
    CurrencyFormatter(symbol: '$symbol ', locale: 'en_US', currencyCode: code);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const symbols = {
    'BDT': '৳',
    'GHS': '₵',
    'INR': '₹',
    'KRW': '₩',
    'NGN': '₦',
    'PHP': '₱',
    'PKR': '₨',
    'LKR': '₨',
    'THB': '฿',
    'USD': r'$',
    'EUR': '€',
  };

  group('every receipt draws the currency symbol, not a box', () {
    for (final MapEntry(key: code, value: symbol) in symbols.entries) {
      test('$code $symbol', () async {
        final fmt = _fmt(symbol, code);
        // The shop's symbol is printed as is, not swapped for the code.
        expect((await receiptCurrencyFormatter(fmt)).symbol, '$symbol ');

        expect(await _missingGlyphWarnings(() => buildReceiptPdf(_data(), fmt)),
            isEmpty,
            reason: 'A4 receipt');
        for (final dots in [576, 384]) {
          expect(
              await _missingGlyphWarnings(() => buildReceiptRollPdf(
                  _data(), fmt,
                  widthDots: dots, isCopy: true)),
              isEmpty,
              reason: 'roll receipt, $dots dots (what thermal printers get)');
        }
        expect(
            await _missingGlyphWarnings(() => buildTestPageRollPdf(
                storeName: 'Shop $symbol', paperMm: 80, widthDots: 576)),
            isEmpty,
            reason: 'printer test page');
        expect(
            await _missingGlyphWarnings(() => buildTextSlipRollPdf(
                lines: ['Cash sales   ${fmt.format(12.5)}', 'x' * 32],
                widthDots: 384)),
            isEmpty,
            reason: 'end-of-day text slip');
      });
    }
  });

  group('the end-of-day slip after a symbol-to-code swap', () {
    ShiftClose close() => ShiftClose(
          shiftId: 1,
          openingCash: 100,
          paidOut: 5,
          countedCash: 160,
          figures: ShiftFigures(
            from: DateTime(2026, 6, 10, 9),
            to: DateTime(2026, 6, 10, 21),
            sales: const FlowByMethod({
              'cash': MethodFlow(count: 3, amount: 60, tips: 4, tax: 6),
              'card': MethodFlow(count: 1, amount: 1234.5, tips: 0, tax: 0),
            }),
            refunds: const FlowByMethod({}),
            voids: const FlowByMethod({}),
          ),
        );

    for (final cols in [32, 48]) {
      test('$cols columns: right edges stay aligned, nothing grows', () async {
        final text = buildShiftSummary(close(),
            shopName: 'Shop',
            taxName: 'KDV',
            fmt: _fmt('₺', 'TRY'),
            columns: cols,
            notes: 'Paid the ₺ 5.00 for milk');
        final lines = await summaryPrintLines(text, currencyCode: 'TRY');
        expect(lines.length, text.split('\n').length);
        expect(lines.join('\n'), isNot(contains('₺')));
        final original = text.split('\n');
        for (var i = 0; i < lines.length; i++) {
          expect(lines[i].length, lessThanOrEqualTo(cols), reason: lines[i]);
          if (original[i].length == cols && original[i].contains('₺ ')) {
            expect(lines[i].length, cols, reason: 'flush right: ${lines[i]}');
          }
        }
        expect(lines, contains(startsWith('Opening cash')));
        final opening = lines.firstWhere((l) => l.startsWith('Opening cash'));
        expect(opening, endsWith('TRY 100.00'));
        expect(opening.length, cols);
        expect(lines.firstWhere((l) => l.startsWith('Card')),
            endsWith('TRY 1,234.50'));
        // The longest line is the paper width, so the slip's font is the
        // same size as for a summary that needed no swap.
        expect(
            lines.map((l) => l.length).reduce((a, b) => a > b ? a : b), cols);
      });
    }

    test('the symbol comes from the frozen text, not today\'s setting',
        () async {
      final text = buildShiftSummary(close(),
          shopName: 'Shop', taxName: 'VAT', fmt: _fmt('₹', 'INR'));
      expect(frozenSummarySymbol(text), '₹');
      // ₹ is drawable: printed as stored even if the shop now uses TRY.
      expect(
          await summaryPrintLines(text, currencyCode: 'TRY'), text.split('\n'));
      final lira = buildShiftSummary(close(),
          shopName: 'Shop', taxName: 'VAT', fmt: _fmt('₺', 'TRY'));
      // No code to fall back on: the neutral marker, padded the same way.
      final marked = await summaryPrintLines(lira, currencyCode: '');
      expect(marked.join('\n'), isNot(contains('₺')));
      expect(marked.firstWhere((l) => l.startsWith('Opening cash')),
          endsWith('¤ 100.00'));
      expect(
          marked.map((l) => l.length), lira.split('\n').map((l) => l.length));
      expect(await summaryPrintLines('x\ny', currencyCode: 'TRY'), ['x', 'y']);
      expect(frozenSummaryColumns(lira), 32);
    });
  });

  test('every symbol in country_defaults.json has a glyph in the bundled fonts',
      () async {
    final countries = (jsonDecode(
                File('assets/locales/country_defaults.json').readAsStringSync())
            as List)
        .cast<Map<String, dynamic>>();
    final covered = await receiptFontCoverage();
    final missing = <String>[];
    for (final c in countries) {
      final symbol = c['symbol'] as String;
      for (final r in symbol.runes) {
        if (r != 0x20 && !covered.contains(r)) {
          missing.add('${c['code']} "$symbol" U+${r.toRadixString(16)}');
        }
      }
      expect(
          await receiptCurrencySymbol(symbol, c['currency'] as String), symbol);
    }
    expect(missing, isEmpty);
  });

  test('every symbol in the Settings currency picker prints as itself',
      () async {
    final covered = await receiptFontCoverage();
    final missing = <String>[];
    for (final c in kPopularCurrencies) {
      for (final r in c.symbol.runes) {
        if (r != 0x20 && !covered.contains(r)) {
          missing.add('${c.code} "${c.symbol}" U+${r.toRadixString(16)}');
        }
      }
      // PKR and LKR used to print "PKR 113.00": ₨ was missing.
      final fmt = _fmt(c.symbol, c.code);
      expect((await receiptCurrencyFormatter(fmt)).format(113), fmt.format(113),
          reason: c.code);
    }
    expect(missing, isEmpty);
  });

  test('the symbol fallback has JetBrains Mono\'s vertical metrics', () async {
    // A taller fallback made every line with ₹ (or any fallback glyph) taller
    // than the same line with \$: about 4.5 mm more per roll receipt.
    for (final (mono, symbols) in [
      (jetBrainsMonoRegular, openPosSymbolsRegular),
      (jetBrainsMonoBold, openPosSymbolsBold),
    ]) {
      final m = TtfParser(await bundledFontData(mono));
      final s = TtfParser(await bundledFontData(symbols));
      expect(s.unitsPerEm, m.unitsPerEm, reason: symbols);
      expect(s.ascent, m.ascent, reason: symbols);
      expect(s.descent, m.descent, reason: symbols);
    }
  });

  test('a roll receipt with ₹ or ₨ is as tall as one with \$', () async {
    Future<double> height(String symbol, String code) async {
      final doc = await buildReceiptRollPdf(_data(), _fmt(symbol, code),
          widthDots: 576);
      await doc.save();
      return doc.document.pdfPageList.pages.single.pageFormat.height;
    }

    final dollar = await height(r'$', 'USD');
    expect(await height('₹', 'INR'), dollar);
    expect(await height('₨', 'PKR'), dollar);
  });

  group('a symbol the fonts cannot draw prints the currency code', () {
    // ₺ ₾ ₸ and emoji are in none of the bundled fonts.
    for (final (symbol, code) in [
      ('₺', 'TRY'),
      ('₾', 'GEL'),
      ('₸', 'KZT'),
      ('\u{1F4B0}', 'XXX'),
    ]) {
      test(symbol, () async {
        final fmt = _fmt(symbol, code);
        final printed = await receiptCurrencyFormatter(fmt);
        expect(printed.format(113), '$code 113.00');
        // The stored formatter (what the screen shows) is untouched.
        expect(fmt.symbol, '$symbol ');

        expect(await _missingGlyphWarnings(() => buildReceiptPdf(_data(), fmt)),
            isEmpty);
        expect(
            await _missingGlyphWarnings(
                () => buildReceiptRollPdf(_data(), fmt, widthDots: 576)),
            isEmpty);
      });
    }

    test('without a code a neutral ¤ is printed, never a box', () async {
      // Only a hand-edited or foreign backup has a symbol and no code.
      final covered = await receiptFontCoverage();
      expect(kUncoveredCurrencyMarker.runes.every(covered.contains), isTrue);
      for (final code in [null, '', '  ']) {
        expect(await receiptCurrencySymbol('₺', code), '¤');
        expect(await receiptCurrencySymbol('Rs', code), 'Rs');
      }
      final fmt = CurrencyFormatter(symbol: '₺ ', locale: 'en_US');
      expect((await receiptCurrencyFormatter(fmt)).format(113), '¤ 113.00');
      expect(fmt.symbol, '₺ ');
      expect(await _missingGlyphWarnings(() => buildReceiptPdf(_data(), fmt)),
          isEmpty);
      expect(
          await _missingGlyphWarnings(
              () => buildReceiptRollPdf(_data(), fmt, widthDots: 576)),
          isEmpty);
    });

    test('the probe sees a box when nothing covers the symbol', () async {
      // Guards the capture itself: an uncovered glyph is reported. A text
      // slip draws its lines as given (the swap happens before it).
      expect(
          await _missingGlyphWarnings(() =>
              buildTextSlipRollPdf(lines: ['Cash  ₺ 5.00'], widthDots: 384)),
          isNotEmpty);
    });
  });

  test('the symbol fallback is in the app theme', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      final tt = theme.textTheme;
      for (final style in <TextStyle?>[
        tt.bodyMedium,
        tt.bodyLarge,
        tt.labelLarge,
        tt.titleLarge,
        tt.headlineLarge,
        tt.displayLarge,
      ]) {
        expect(style?.fontFamilyFallback, contains(AppFonts.symbols));
      }
    }
    expect(AppFonts.monoFallback, [AppFonts.symbols]);
  });
}
