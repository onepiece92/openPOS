import 'dart:typed_data';

import 'package:printing/printing.dart';

import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/printing/domain/receipt_roll_pdf.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';

/// Print head resolution of the TSP100III: 203 dpi, i.e. 8 dots per mm.
/// Rasterising the roll PDF at exactly this dpi means one PDF point maps to
/// one dot and nothing is resampled on the printer.
const double kReceiptDpi = 203;

/// Width of the printable area in dots — what the Star SDK scales the image
/// to. 72mm x 8 = 576 on an 80mm roll, 50.8mm x 8 = 406 on a 58mm roll.
int rollPrintWidthDots(int paperMm) => paperMm == 58 ? 406 : 576;

/// Renders a receipt as PNG pages for a graphics-only printer.
///
/// Normally one page — the roll PDF grows to fit its content — but the list
/// keeps a very long bill printable instead of silently truncated.
Future<List<Uint8List>> renderReceiptImages(
  ReceiptBodyData data,
  CurrencyFormatter fmt,
  int paperMm, {
  bool isCopy = false,
}) async {
  final doc = await buildReceiptRollPdf(data, fmt, paperMm, isCopy: isCopy);
  return _rasterise(await doc.save());
}

/// Renders the printer-setup test slip as PNG pages.
Future<List<Uint8List>> renderTestPageImages({
  required String storeName,
  required int paperMm,
}) async {
  final doc =
      await buildTestPageRollPdf(storeName: storeName, paperMm: paperMm);
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
