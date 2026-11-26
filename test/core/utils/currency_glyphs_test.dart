import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/core/theme/tokens.dart';
import 'package:pos_app/core/utils/bundled_fonts.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/printing/domain/receipt_roll_pdf.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';
import 'package:pos_app/features/receipts/presentation/receipt_pdf_service.dart';

/// JetBrains Mono has no ৳ ₵ ₹ ₩ ₦ ₱ ฿, and the pdf package has no system
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
      });
    }
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
      expect(await receiptCurrencySymbol(symbol, c['currency'] as String),
          symbol);
    }
    expect(missing, isEmpty);
  });

  group('a symbol the fonts cannot draw prints the currency code', () {
    // ₺ ₾ ₨ and emoji are in none of the bundled fonts.
    for (final (symbol, code) in [
      ('₺', 'TRY'),
      ('₾', 'GEL'),
      ('Rs₨', 'PKR'),
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

    test('without a code the symbol is kept', () async {
      expect(await receiptCurrencySymbol('₺', null), '₺');
      expect(await receiptCurrencySymbol('₺', ''), '₺');
    });

    test('the probe sees a box when nothing covers the symbol', () async {
      // Guards the capture itself: an uncovered glyph is reported.
      final fmt = CurrencyFormatter(symbol: '₺ ', locale: 'en_US');
      expect(
          await _missingGlyphWarnings(
              () => buildReceiptRollPdf(_data(), fmt, widthDots: 576)),
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
