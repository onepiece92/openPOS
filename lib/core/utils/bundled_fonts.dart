import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:pdf/pdf.dart' show TtfParser;
import 'package:pdf/widgets.dart' as pw;

import 'package:pos_app/core/utils/currency_formatter.dart';

const jetBrainsMonoRegular = 'assets/fonts/JetBrainsMono-Regular.ttf';
const jetBrainsMonoBold = 'assets/fonts/JetBrainsMono-Bold.ttf';
const jetBrainsMonoItalic = 'assets/fonts/JetBrainsMono-Italic.ttf';

/// Subset Noto (OFL, assets/fonts/OFL.txt) for the currency symbols JetBrains
/// Mono lacks: ৳ ₵ ₹ ₩ ₦ ₱ ฿, plus digits and punctuation.
const openPosSymbolsRegular = 'assets/fonts/OpenPOSSymbols-Regular.ttf';
const openPosSymbolsBold = 'assets/fonts/OpenPOSSymbols-Bold.ttf';

/// The SIL Open Font License that covers the OpenPOS Symbols subsets.
const openPosSymbolsLicense = 'assets/fonts/OFL.txt';

/// JetBrains Mono's own OFL text (upstream OFL.txt, with its copyright line).
const jetBrainsMonoLicense = 'assets/fonts/JetBrainsMono-OFL.txt';

/// Lists the bundled symbol fonts' OFL in Flutter's license registry
/// (what `showLicensePage` reads). The file is read only when someone asks
/// for the licenses, never at startup.
void registerBundledFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['OpenPOS Symbols (Noto subset)'],
      await rootBundle.loadString(openPosSymbolsLicense),
    );
  });
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['JetBrains Mono'],
      await rootBundle.loadString(jetBrainsMonoLicense),
    );
  });
}

final Map<String, Future<ByteData>> _fontData = {};

/// The bytes of the bundled font at [asset], read from the bundle once.
///
/// `rootBundle.load` does not cache, and every receipt used to read each
/// font file again. A failed load is dropped from the cache so the next
/// receipt retries instead of failing forever.
Future<ByteData> bundledFontData(String asset) {
  final cached = _fontData[asset];
  if (cached != null) return cached;
  // Future.sync: a missing asset can throw before a future exists.
  final future = Future.sync(() => rootBundle.load(asset));
  _fontData[asset] = future;
  future.then<void>((_) {}, onError: (Object _) {
    if (identical(_fontData[asset], future)) _fontData.remove(asset);
  });
  return future;
}

/// A PDF font for the bundled [asset].
///
/// Only the bytes are shared. A fresh [pw.Font] is made per call because a
/// font object remembers the last document it was embedded in, and two
/// receipts built at once would otherwise trade embeddings mid-layout.
Future<pw.Font> bundledPdfFont(String asset) async =>
    pw.Font.ttf(await bundledFontData(asset));

/// The fonts every receipt PDF draws with, loaded on first use.
///
/// [theme] puts the symbol fallback on every style; bold styles add
/// [boldFallback] in front so a bold total keeps a bold ₹.
class ReceiptPdfFonts {
  ReceiptPdfFonts._(this.regular, this.bold, this.italic, this.symbols,
      this.symbolsBold);

  final pw.Font regular;
  final pw.Font bold;
  final pw.Font? italic;
  final pw.Font symbols;
  final pw.Font symbolsBold;

  List<pw.Font> get boldFallback => [symbolsBold];

  pw.ThemeData get theme => pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        italic: italic,
        fontFallback: [symbols],
      );
}

Future<ReceiptPdfFonts> loadReceiptPdfFonts({bool italic = false}) async {
  // Sequential awaits, not Future.wait: flutter_test serves assets as
  // SynchronousFuture, and Future.wait returned empty there.
  return ReceiptPdfFonts._(
    await bundledPdfFont(jetBrainsMonoRegular),
    await bundledPdfFont(jetBrainsMonoBold),
    italic ? await bundledPdfFont(jetBrainsMonoItalic) : null,
    await bundledPdfFont(openPosSymbolsRegular),
    await bundledPdfFont(openPosSymbolsBold),
  );
}

// ─── Coverage ────────────────────────────────────────────────────────────────

final Map<String, Future<Set<int>>> _codePoints = {};

/// The code points the bundled font at [asset] has a glyph for — its cmap,
/// parsed once (the same table the pdf package checks per character).
Future<Set<int>> bundledFontCodePoints(String asset) {
  final cached = _codePoints[asset];
  if (cached != null) return cached;
  final future = bundledFontData(asset)
      .then((data) => TtfParser(data).charToGlyphIndexMap.keys.toSet());
  _codePoints[asset] = future;
  future.then<void>((_) {}, onError: (Object _) {
    if (identical(_codePoints[asset], future)) _codePoints.remove(asset);
  });
  return future;
}

Future<Set<int>>? _receiptCoverage;

/// Code points a receipt can draw in both regular and bold: JetBrains Mono
/// plus the symbol fallback, per weight.
Future<Set<int>> receiptFontCoverage() {
  final cached = _receiptCoverage;
  if (cached != null) return cached;
  final future = _computeReceiptCoverage();
  _receiptCoverage = future;
  future.then<void>((_) {}, onError: (Object _) {
    if (identical(_receiptCoverage, future)) _receiptCoverage = null;
  });
  return future;
}

Future<Set<int>> _computeReceiptCoverage() async {
  // Sequential awaits, not Future.wait: flutter_test serves assets as
  // SynchronousFuture, and Future.wait returned empty there.
  final regular = (await bundledFontCodePoints(jetBrainsMonoRegular))
      .union(await bundledFontCodePoints(openPosSymbolsRegular));
  final bold = (await bundledFontCodePoints(jetBrainsMonoBold))
      .union(await bundledFontCodePoints(openPosSymbolsBold));
  return regular.intersection(bold);
}

/// The currency symbol a receipt prints for [symbol].
///
/// The symbol is free text a shop types. If any character in it has no glyph
/// in the bundled fonts the PDF would draw a box, so the ISO [currencyCode]
/// is printed instead ("TRY 113.00"). Stored settings are never changed, and
/// on screen the symbol is shown as typed (the OS can fill in there).
Future<String> receiptCurrencySymbol(String symbol, String? currencyCode) async {
  final code = currencyCode?.trim() ?? '';
  if (code.isEmpty) return symbol;
  final covered = await receiptFontCoverage();
  final drawable = symbol.runes.every((r) => _isSpace(r) || covered.contains(r));
  return drawable ? symbol : code;
}

/// [fmt] with its symbol swapped for one the receipt fonts can draw.
Future<CurrencyFormatter> receiptCurrencyFormatter(CurrencyFormatter fmt) async {
  final trimmed = fmt.symbol.trim();
  final printable = await receiptCurrencySymbol(trimmed, fmt.currencyCode);
  if (printable == trimmed) return fmt;
  return CurrencyFormatter(
    symbol: fmt.symbol.replaceFirst(trimmed, printable),
    locale: fmt.locale,
    decimalDigits: fmt.decimalDigits,
    currencyCode: fmt.currencyCode,
  );
}

// Spaces the pdf package lays out without a glyph.
bool _isSpace(int r) =>
    r == 0x20 ||
    r == 0x09 ||
    r == 0x0A ||
    r == 0x0D ||
    r == 0xA0 ||
    (r >= 0x2000 && r <= 0x200A) ||
    r == 0x202F ||
    r == 0x205F ||
    r == 0x3000;
