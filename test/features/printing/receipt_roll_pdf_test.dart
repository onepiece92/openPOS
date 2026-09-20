import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/printing/domain/receipt_roll_pdf.dart';
import 'package:pos_app/features/printing/domain/render_receipt_image.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';

/// The roll PDF is what graphics-only printers (Star TSP100III) actually
/// print, once rasterised. Rasterising itself needs a platform channel, so
/// these tests cover the layout that feeds it: right width, grows with
/// content, never paginates.

ReceiptBodyData _sampleData({int items = 1}) {
  final order = Order(
    id: 42,
    status: 'completed',
    subtotal: 100.0,
    taxTotal: 13.0,
    discountTotal: 0.0,
    discountIsPercent: false,
    invoicePrefix: '',
    printCount: 0,
    total: 113.0,
    paymentMethod: 'cash',
    tenderedAmount: 120.0,
    changeAmount: 7.0,
    customerId: null,
    pointsRedeemed: 0,
    loyaltyDiscount: 0.0,
    pointsEarned: 0,
    notes: null,
    createdAt: DateTime(2026, 4, 22, 14, 30),
    updatedAt: DateTime(2026, 4, 22, 14, 30),
  );
  return ReceiptBodyData(
    order: order,
    items: [
      for (var i = 0; i < items; i++)
        OrderItem(
          id: i + 1,
          orderId: 42,
          productId: 7,
          productName: 'Coffee ${i + 1}',
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
      ),
    ],
    businessName: 'Test Cafe',
    customer: null,
  );
}

/// Page geometry is only resolved once the document is generated.
Future<List<PdfPageFormat>> _pageFormats(
  ReceiptBodyData data,
  CurrencyFormatter fmt,
  int paperMm,
) async {
  final doc = await buildReceiptRollPdf(data, fmt, paperMm);
  await doc.save();
  return doc.document.pdfPageList.pages.map((p) => p.pageFormat).toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fmt = CurrencyFormatter(symbol: 'Rs ', locale: 'en_US');

  test('80mm roll is one page exactly as wide as the printable area',
      () async {
    final formats = await _pageFormats(_sampleData(), fmt, 80);

    expect(formats, hasLength(1), reason: 'a receipt is one continuous roll');
    expect(formats.single.width, closeTo(72 * PdfPageFormat.mm, 0.01));
    expect(formats.single.height, greaterThan(0));
    expect(formats.single.height.isFinite, isTrue,
        reason: 'infinite height must resolve to the content height');
  });

  test('58mm roll is narrower', () async {
    final wide = await _pageFormats(_sampleData(), fmt, 80);
    final narrow = await _pageFormats(_sampleData(), fmt, 58);

    expect(narrow.single.width, closeTo(50.8 * PdfPageFormat.mm, 0.01));
    expect(narrow.single.width, lessThan(wide.single.width));
  });

  test('unknown paper width falls back to 80mm', () async {
    final fallback = await _pageFormats(_sampleData(), fmt, 999);
    final standard = await _pageFormats(_sampleData(), fmt, 80);

    expect(fallback.single.width, standard.single.width);
  });

  test('the roll grows with the bill instead of paginating', () async {
    final short = await _pageFormats(_sampleData(items: 1), fmt, 80);
    final long = await _pageFormats(_sampleData(items: 30), fmt, 80);

    expect(long, hasLength(1));
    expect(long.single.height, greaterThan(short.single.height));
  });

  test('a copy prints taller than the original (COPY banner)', () async {
    final original = await buildReceiptRollPdf(_sampleData(), fmt, 80);
    await original.save();
    final copy =
        await buildReceiptRollPdf(_sampleData(), fmt, 80, isCopy: true);
    await copy.save();

    expect(
      copy.document.pdfPageList.pages.single.pageFormat.height,
      greaterThan(
          original.document.pdfPageList.pages.single.pageFormat.height),
    );
  });

  test('test page renders on the same roll geometry', () async {
    final doc = await buildTestPageRollPdf(storeName: 'Test Cafe', paperMm: 80);
    final bytes = await doc.save();

    expect(bytes, isNotEmpty);
    expect(doc.document.pdfPageList.pages.single.pageFormat.width,
        closeTo(72 * PdfPageFormat.mm, 0.01));
  });

  test('print width in dots matches the head at 203 dpi', () {
    // 72mm x 8 dots/mm, 50.8mm x 8 dots/mm.
    expect(rollPrintWidthDots(80), 576);
    expect(rollPrintWidthDots(58), 406);
    expect(rollPrintWidthDots(999), 576, reason: 'falls back to 80mm');
  });
}
