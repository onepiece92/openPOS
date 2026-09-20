import 'dart:typed_data';

import 'package:printing/printing.dart';

import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/printing/domain/receipt_roll_pdf.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';

/// Print head resolution shared by every receipt printer worth supporting:
/// 203 dpi, i.e. 8 dots per mm. Rasterising the roll PDF at exactly this dpi
/// means one PDF point maps to one dot and nothing is resampled.
const double kReceiptDpi = 203;

/// Printable width in dots on a Star TSP100III: 72mm of an 80mm roll,
/// 50.8mm of a 58mm roll.
int starPrintWidthDots(int paperMm) => paperMm == 58 ? 406 : 576;

/// Printable width in dots on a generic ESC/POS printer — the de-facto
/// 576/384 standard those printers are built to.
int escPosPrintWidthDots(int paperMm) => paperMm == 58 ? 384 : 576;

/// Renders a receipt as PNG pages.
///
/// Every driver prints the same rendered image, which is what makes
/// non-Latin text and logos print identically on any hardware — ESC/POS
/// text mode can only reach the printer's built-in character set.
///
/// Normally one page — the roll PDF grows to fit its content — but the list
/// keeps a very long bill printable instead of silently truncated.
Future<List<Uint8List>> renderReceiptImages(
  ReceiptBodyData data,
  CurrencyFormatter fmt, {
  required int widthDots,
  bool isCopy = false,
}) async {
  final doc = await buildReceiptRollPdf(
    data,
    fmt,
    widthDots: widthDots,
    isCopy: isCopy,
  );
  return _rasterise(await doc.save());
}

/// Renders the printer-setup test slip as PNG pages.
Future<List<Uint8List>> renderTestPageImages({
  required String storeName,
  required int paperMm,
  required int widthDots,
}) async {
  final doc = await buildTestPageRollPdf(
    storeName: storeName,
    paperMm: paperMm,
    widthDots: widthDots,
  );
  return _rasterise(await doc.save());
}

Future<List<Uint8List>> _rasterise(Uint8List pdf) async {
  final pages = <Uint8List>[];
  await for (final page in Printing.raster(pdf, dpi: kReceiptDpi)) {
    pages.add(await page.toPng());
  }
  if (pages.isEmpty) {
    throw StateError('Receipt produced no printable page');
  }
  return pages;
}
