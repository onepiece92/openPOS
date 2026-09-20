import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/orders/domain/order_number.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';

/// Receipt laid out for a paper roll, not a page.
///
/// Graphics-only printers (Star TSP100III) can't be sent text commands at
/// all, so the receipt is drawn here and rasterised by
/// `render_receipt_image.dart`. The page is exactly as wide as the printable
/// area and as tall as the content — `double.infinity` height makes the pdf
/// package size the page to what was drawn.
///
/// [paperMm] must be 58 or 80; anything else falls back to 80mm.
Future<pw.Document> buildReceiptRollPdf(
  ReceiptBodyData data,
  CurrencyFormatter fmt,
  int paperMm, {
  bool isCopy = false,
}) async {
  final width = rollPrintWidthMm(paperMm) * PdfPageFormat.mm;
  final narrow = paperMm == 58;

  final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'));
  final fontBold =
      pw.Font.ttf(await rootBundle.load('assets/fonts/JetBrainsMono-Bold.ttf'));

  // Sized so a full line of monospace text just fits the roll: ~42 chars on
  // 80mm, ~30 on 58mm.
  final base = narrow ? 7.0 : 8.0;
  final body = pw.TextStyle(font: font, fontSize: base);
  final bold = pw.TextStyle(font: fontBold, fontSize: base);
  final title = pw.TextStyle(font: fontBold, fontSize: base * 1.75);

  final order = data.order;
  final dateFmt = DateFormat('MM/dd/yyyy hh:mm a');

  pw.Widget rule({String ch = '-'}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Container(
          height: ch == '=' ? 1.2 : 0.5,
          color: PdfColors.black,
        ),
      );

  pw.Widget kv(String label, String value, {bool strong = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1),
        child: pw.Row(
          children: [
            pw.Text(label, style: strong ? bold : body),
            pw.Spacer(),
            pw.Text(value, style: strong ? bold : body),
          ],
        ),
      );

  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(
        width,
        double.infinity,
        marginAll: 0,
      ),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ── Business name ──────────────────────────────────────────────
          pw.Center(child: pw.Text(data.businessName, style: title)),
          rule(),
          if (isCopy) ...[
            pw.Center(
                child: pw.Text('*** COPY OF ORIGINAL ***', style: bold)),
            rule(),
          ],

          // ── Customer + bill no. ────────────────────────────────────────
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(data.customer?.name ?? 'Walk-in', style: body),
              ),
              pw.Text('Bill ${order.billNo}', style: body),
            ],
          ),
          if (data.table != null)
            pw.Text('Table: ${data.table!.name}', style: body),
          pw.Text(dateFmt.format(order.createdAt), style: body),
          rule(),

          // ── Items ──────────────────────────────────────────────────────
          pw.Row(
            children: [
              pw.Expanded(flex: 6, child: pw.Text('Item', style: bold)),
              pw.Expanded(
                flex: 2,
                child: pw.Text('Qty',
                    style: bold, textAlign: pw.TextAlign.right),
              ),
              pw.Expanded(
                flex: 4,
                child: pw.Text('Total',
                    style: bold, textAlign: pw.TextAlign.right),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          ...data.items.map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 1),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                      flex: 6, child: pw.Text(item.productName, style: body)),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('x${item.quantity}',
                        style: body, textAlign: pw.TextAlign.right),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(fmt.formatPlain(item.lineTotal),
                        style: body, textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
            ),
          ),
          rule(),

          // ── Totals ─────────────────────────────────────────────────────
          kv('Subtotal', fmt.format(order.subtotal)),
          if (order.discountTotal > 0)
            kv('Discount', '- ${fmt.format(order.discountTotal)}'),
          ...data.taxes.map((t) => kv(
                '${t.taxRateName} (${(t.taxRatePercent * 100).toStringAsFixed(1)}%)',
                fmt.format(t.taxAmount),
              )),
          if (order.loyaltyDiscount > 0)
            kv('Loyalty (${order.pointsRedeemed} pts)',
                '- ${fmt.format(order.loyaltyDiscount)}'),
          rule(ch: '='),
          kv('TOTAL', fmt.format(order.total), strong: true),
          rule(),

          // ── Payment ────────────────────────────────────────────────────
          kv('Payment', _titleCase(order.paymentMethod)),
          if (order.tenderedAmount != null) ...[
            kv('Tendered', fmt.format(order.tenderedAmount!)),
            kv('Change', fmt.format(order.changeAmount ?? 0)),
          ],

          // ── Loyalty ────────────────────────────────────────────────────
          if (data.customer != null) ...[
            rule(),
            if (order.pointsRedeemed > 0)
              kv('Pts Redeemed',
                  '${order.pointsRedeemed} (${fmt.format(order.loyaltyDiscount)})'),
            if (order.pointsEarned > 0)
              kv('Pts Earned', '+${order.pointsEarned}'),
            kv('Balance', '${data.customer!.loyaltyPoints} pts'),
          ],

          // ── Footer ─────────────────────────────────────────────────────
          pw.SizedBox(height: 8),
          pw.Center(child: pw.Text('Thank you!', style: bold)),
          // Blank tail so the cutter doesn't bite into the last line.
          pw.SizedBox(height: 16),
        ],
      ),
    ),
  );

  return doc;
}

/// A short "this printer works" slip, roll-shaped like [buildReceiptRollPdf].
Future<pw.Document> buildTestPageRollPdf({
  required String storeName,
  required int paperMm,
}) async {
  final width = rollPrintWidthMm(paperMm) * PdfPageFormat.mm;
  final base = paperMm == 58 ? 7.0 : 8.0;

  final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'));
  final fontBold =
      pw.Font.ttf(await rootBundle.load('assets/fonts/JetBrainsMono-Bold.ttf'));

  final body = pw.TextStyle(font: font, fontSize: base);
  final title = pw.TextStyle(font: fontBold, fontSize: base * 1.75);

  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(width, double.infinity, marginAll: 0),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(child: pw.Text(storeName, style: title)),
          pw.SizedBox(height: 4),
          pw.Container(height: 0.5, color: PdfColors.black),
          pw.SizedBox(height: 4),
          pw.Center(child: pw.Text('Printer Test', style: body)),
          pw.Center(
              child: pw.Text(DateTime.now().toIso8601String(), style: body)),
          pw.Center(child: pw.Text('Paper: ${paperMm}mm', style: body)),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'If you can read this clearly, your printer is ready.',
              style: body,
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 16),
        ],
      ),
    ),
  );

  return doc;
}

/// Printable width of the roll in millimetres — the paper is wider than what
/// the head can actually print (TSP100III: 72mm of 80mm, 50.8mm of 58mm).
double rollPrintWidthMm(int paperMm) => paperMm == 58 ? 50.8 : 72.0;

String _titleCase(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
