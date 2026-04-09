import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:pos_app/features/receipts/presentation/receipt_body.dart';

// ─── PDF builder ──────────────────────────────────────────────────────────────

Future<pw.Document> buildReceiptPdf(ReceiptBodyData data, String symbol) async {
  final doc = pw.Document();
  final dateFmt = DateFormat('MM/dd/yyyy hh:mm:ss a');

  // Load JetBrains Mono for PDF
  final font = await PdfGoogleFonts.jetBrainsMonoRegular();
  final fontBold = await PdfGoogleFonts.jetBrainsMonoBold();
  final fontItalic = await PdfGoogleFonts.jetBrainsMonoItalic();

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
              _headerCell('Rate ($symbol)', fontBold),
              _headerCell('Amt ($symbol)', fontBold),
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
                    _dataCell(item.unitPrice.toStringAsFixed(2), font),
                    _dataCell(item.lineTotal.toStringAsFixed(2), font),
                  ],
                ),
              )),

          divider(),

          // ── Subtotals ───────────────────────────────────────────────────
          billRow('Total', '$symbol ${order.subtotal.toStringAsFixed(2)}'),
          billRow(
              'Discount', '$symbol ${order.discountTotal.toStringAsFixed(2)}'),
          ...data.taxes.map((t) => billRow(
                '${t.taxRateName} (${(t.taxRatePercent * 100).toStringAsFixed(1)}%)',
                '$symbol ${t.taxAmount.toStringAsFixed(2)}',
              )),
          divider(),
          billRow('Grand Total', '$symbol ${order.total.toStringAsFixed(2)}',
              bold: true),
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
            billRow('Cash Tendered',
                '$symbol ${order.tenderedAmount!.toStringAsFixed(2)}'),
            billRow('Change',
                '$symbol ${(order.changeAmount ?? 0).toStringAsFixed(2)}'),
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
    BuildContext context, ReceiptBodyData data, String symbol) async {
  final doc = await buildReceiptPdf(data, symbol);
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
