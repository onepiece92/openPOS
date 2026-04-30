import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';

Future<pw.Font> _loadFont(String path) async {
  final data = await rootBundle.load(path);
  return pw.Font.ttf(data);
}

// ─── PDF builder ──────────────────────────────────────────────────────────────

Future<pw.Document> buildReceiptPdf(
    ReceiptBodyData data, CurrencyFormatter fmt) async {
  final doc = pw.Document();
  final dateFmt = DateFormat('MM/dd/yyyy hh:mm:ss a');
  final symbolLabel = fmt.symbol.trim();

  // Load JetBrains Mono for PDF (bundled, offline)
  final font = await _loadFont('assets/fonts/JetBrainsMono-Regular.ttf');
  final fontBold = await _loadFont('assets/fonts/JetBrainsMono-Bold.ttf');
  final fontItalic = await _loadFont('assets/fonts/JetBrainsMono-Italic.ttf');

  // Styles
  final baseStyle = pw.TextStyle(fontSize: 10, font: font);
  final boldStyle = pw.TextStyle(fontSize: 10, font: fontBold, fontWeight: pw.FontWeight.bold);
  final headerStyle = pw.TextStyle(fontSize: 11, font: fontBold, fontWeight: pw.FontWeight.bold);
  final smallStyle = pw.TextStyle(fontSize: 9, font: font, color: PdfColors.grey600);
  final titleStyle = pw.TextStyle(fontSize: 14, font: fontBold, fontWeight: pw.FontWeight.bold);

  final order = data.order;
  final customerName = data.customer?.name ?? 'Walk-in';

  pw.Widget divider() => pw.Divider(thickness: 0.5, color: PdfColors.grey400);

  pw.Widget billRow(String label, String value, {bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(
          children: [
            pw.Text(label, style: bold ? boldStyle : baseStyle),
            pw.Spacer(),
            pw.Text(value, style: bold ? boldStyle : baseStyle),
          ],
        ),
      );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ── Business name ───────────────────────────────────────────────
          pw.Center(
            child: pw.Text(data.businessName, style: titleStyle),
          ),
          pw.SizedBox(height: 10),
          divider(),

          // ── Customer + bill number ──────────────────────────────────────
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text(customerName, style: baseStyle)),
              pw.Text('Paid Bill No.: ${order.id}', style: baseStyle),
            ],
          ),
          if (data.table != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text('Table: ${data.table!.name}', style: baseStyle),
            ),
          divider(),

          // ── Items header ────────────────────────────────────────────────
          pw.Text('Items Ordered', style: headerStyle),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                flex: 5,
                child: pw.Text('Name',
                    style: pw.TextStyle(
                        fontSize: 9,
                        font: fontBold,
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline)),
              ),
              _headerCell('Qty', fontBold),
              _headerCell('Rate ($symbolLabel)', fontBold),
              _headerCell('Amt ($symbolLabel)', fontBold),
            ],
          ),
          pw.SizedBox(height: 2),

          // ── Item rows ───────────────────────────────────────────────────
          ...data.items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                        flex: 5,
                        child: pw.Text(item.productName, style: baseStyle)),
                    _dataCell('x ${item.quantity}', font),
                    _dataCell(fmt.formatPlain(item.unitPrice), font),
                    _dataCell(fmt.formatPlain(item.lineTotal), font),
                  ],
                ),
              )),

          divider(),

          // ── Subtotals ───────────────────────────────────────────────────
          billRow('Total', fmt.format(order.subtotal)),
          billRow('Discount', fmt.format(order.discountTotal)),
          ...data.taxes.map((t) => billRow(
                '${t.taxRateName} (${(t.taxRatePercent * 100).toStringAsFixed(1)}%)',
                fmt.format(t.taxAmount),
              )),
          divider(),
          billRow('Grand Total', fmt.format(order.total), bold: true),
          divider(),

          // ── Payment info ────────────────────────────────────────────────
          pw.Text('Payment', style: headerStyle),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Payment Mode: ${order.paymentMethod[0].toUpperCase()}${order.paymentMethod.substring(1)}',
                  style: baseStyle,
                ),
              ),
              pw.Text(dateFmt.format(order.createdAt), style: smallStyle),
            ],
          ),
          if (order.tenderedAmount != null) ...[
            pw.SizedBox(height: 2),
            billRow('Cash Tendered', fmt.format(order.tenderedAmount!)),
            billRow('Change', fmt.format(order.changeAmount ?? 0)),
          ],
          divider(),

          // ── Loyalty points ──────────────────────────────────────────────
          if (data.customer != null) ...[
            pw.Text('Loyalty Points', style: headerStyle),
            pw.SizedBox(height: 4),
            billRow('Current', '${data.customer!.loyaltyPoints}'),
            pw.SizedBox(height: 20),
          ] else
            pw.SizedBox(height: 12),

          pw.Center(
            child: pw.Text(
              'Thank you for your purchase!',
              style: pw.TextStyle(
                  fontSize: 9,
                  font: fontItalic,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    ),
  );

  return doc;
}

// ─── Action: save / share PDF ─────────────────────────────────────────────────

Future<void> downloadReceiptPdf(
    BuildContext context, ReceiptBodyData data, CurrencyFormatter fmt) async {
  final doc = await buildReceiptPdf(data, fmt);
  final bytes = await doc.save();
  final fileName = 'receipt_order_${data.order.id}.pdf';

  await Printing.sharePdf(bytes: bytes, filename: fileName);
}

// ─── Private helpers ──────────────────────────────────────────────────────────

pw.Widget _headerCell(String text, pw.Font font) => pw.SizedBox(
      width: 64,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.right,
        style: pw.TextStyle(
            fontSize: 9,
            font: font,
            fontWeight: pw.FontWeight.bold,
            decoration: pw.TextDecoration.underline),
      ),
    );

pw.Widget _dataCell(String text, pw.Font font) => pw.SizedBox(
      width: 64,
      child: pw.Text(text,
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(fontSize: 10, font: font)),
    );
