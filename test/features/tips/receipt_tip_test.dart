import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/printing/domain/receipt_roll_pdf.dart';
import 'package:pos_app/features/printing/domain/render_receipt.dart';
import 'package:pos_app/features/receipts/domain/receipt_labels.dart';
import 'package:pos_app/features/receipts/domain/receipt_text.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';
import 'package:pos_app/features/receipts/presentation/receipt_pdf_service.dart';

ReceiptBodyData _data({double tip = 0}) => ReceiptBodyData(
      order: Order(
        id: 42,
        status: 'completed',
        subtotal: 100.0,
        taxTotal: 13.0,
        discountTotal: 0.0,
        discountIsPercent: false,
        invoicePrefix: '',
        printCount: 0,
        total: 113.0,
        tipAmount: tip,
        paymentMethod: 'cash',
        tenderedAmount: 140.0,
        changeAmount: 140.0 - 113.0 - tip,
        customerId: null,
        pointsRedeemed: 0,
        loyaltyDiscount: 0.0,
        pointsEarned: 0,
        notes: null,
        createdAt: DateTime(2026, 4, 22, 14, 30),
        updatedAt: DateTime(2026, 4, 22, 14, 30),
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
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fmt = CurrencyFormatter(symbol: 'Rs ', locale: 'en_US');

  Future<void> body(WidgetTester tester, ReceiptBodyData d) =>
      tester.pumpWidget(MaterialApp(
          home: Scaffold(body: ReceiptBody(data: d, fmt: fmt))));

  testWidgets('on-screen receipt: Tip row, Total Paid includes the tip',
      (tester) async {
    await body(tester, _data(tip: 10));
    expect(find.text('Tip'), findsOneWidget);
    expect(find.text('Rs 10.00'), findsOneWidget);
    expect(find.text('Total Paid'), findsOneWidget);
    expect(find.text('Rs 123.00'), findsOneWidget); // 113 + 10
    expect(find.text('Grand Total'), findsNothing);
  });

  testWidgets('on-screen receipt without a tip is unchanged', (tester) async {
    await body(tester, _data());
    expect(find.text('Tip'), findsNothing);
    expect(find.text('Total Paid'), findsNothing);
    expect(find.text('Grand Total'), findsOneWidget);
    expect(find.text('Rs 113.00'), findsOneWidget);
  });

  test('share text', () {
    final t = buildReceiptText(_data(tip: 10), fmt);
    expect(t, contains('Tip: Rs 10.00'));
    expect(t, contains('Total paid: Rs 123.00'));
    expect(t.indexOf('Tip:'), lessThan(t.indexOf('Total paid:')));
    final plain = buildReceiptText(_data(), fmt);
    expect(plain, isNot(contains('Tip')));
    expect(plain, contains('Total: Rs 113.00'));
  });

  test('ESC/POS text receipt', () async {
    String text(List<int> b) =>
        String.fromCharCodes(b.where((c) => c >= 0x20));
    final tipped = text(await renderReceiptBytes(_data(tip: 10), fmt, 80));
    expect(tipped, contains('Tip'));
    expect(tipped, contains('TOTAL PAID'));
    expect(tipped, contains('123.00'));
    final plain = text(await renderReceiptBytes(_data(), fmt, 80));
    expect(plain, isNot(contains('Tip')));
    expect(plain, contains('TOTAL'));
    expect(plain, isNot(contains('TOTAL PAID')));
  });

  test('the closing total row is total + tip, labelled for each format', () {
    final tipped = _data(tip: 10).order;
    expect(tipped.paidTotal, 123); // what both PDFs print as the total
    expect(tipped.totalRowLabel('Grand Total'), 'Total Paid'); // A4
    expect(tipped.totalRowLabel('TOTAL', shout: true), 'TOTAL PAID'); // roll
    final plain = _data().order;
    expect(plain.paidTotal, 113);
    expect(plain.totalRowLabel('Grand Total'), 'Grand Total');
    expect(plain.totalRowLabel('TOTAL', shout: true), 'TOTAL');
  });

  test('roll PDF (what ESC/POS and Star print) gains the Tip row', () async {
    Future<double> height(ReceiptBodyData d) async {
      final doc = await buildReceiptRollPdf(d, fmt, widthDots: 576);
      await doc.save();
      return doc.document.pdfPageList.pages.single.pageFormat.height;
    }

    expect(await height(_data(tip: 10)), greaterThan(await height(_data())));
    // Same row count with a tip whatever the amount.
    expect(await height(_data(tip: 10)), await height(_data(tip: 3.5)));
  });

  test('A4 PDF builds with a tip and grows in content', () async {
    final tipped = await (await buildReceiptPdf(_data(tip: 10), fmt)).save();
    final plain = await (await buildReceiptPdf(_data(), fmt)).save();
    expect(tipped.length, isNot(plain.length));
  });
}
