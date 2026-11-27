import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/printing/domain/receipt_roll_pdf.dart';
import 'package:pos_app/features/printing/domain/render_receipt.dart';
import 'package:pos_app/features/receipts/domain/receipt_text.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';
import 'package:pos_app/features/receipts/presentation/receipt_pdf_service.dart';

import '../../_support/pdf_text.dart';

/// S1–S3: every receipt format shows the Discount row only for a sale with
/// a discount, the loyalty block only when points were earned or redeemed,
/// and no customer line ("Walk-in") when there is no customer — all from
/// the order's own figures.
final _customer = Customer(
  id: 5,
  name: 'Asha',
  loyaltyPoints: 120,
  defaultDiscount: 0,
  defaultDiscountIsPercent: false,
  isTaxExempt: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

ReceiptBodyData _data({
  double discount = 0,
  bool customer = false,
  int earned = 0,
  int redeemed = 0,
}) =>
    ReceiptBodyData(
      order: Order(
        id: 42,
        status: 'completed',
        subtotal: 100.0,
        taxTotal: 0.0,
        discountTotal: discount,
        discountIsPercent: false,
        invoicePrefix: '',
        printCount: 0,
        total: 100.0 - discount - redeemed,
        tipAmount: 0,
        paymentMethod: 'card',
        customerId: customer ? 5 : null,
        pointsRedeemed: redeemed,
        loyaltyDiscount: redeemed.toDouble(),
        pointsEarned: earned,
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
          taxAmount: 0,
          lineTotal: 100.0,
        ),
      ],
      taxes: const [],
      businessName: 'Test Cafe',
      customer: customer ? _customer : null,
    );

/// The cases every format is checked against.
final _cases =
    <String, ({ReceiptBodyData data, bool discount, bool loyalty, bool name})>{
  'no discount, no customer': (
    data: _data(),
    discount: false,
    loyalty: false,
    name: false
  ),
  'a discount': (
    data: _data(discount: 10),
    discount: true,
    loyalty: false,
    name: false
  ),
  'a customer who earned nothing': (
    data: _data(customer: true),
    discount: false,
    loyalty: false,
    name: true
  ),
  'a customer who earned points': (
    data: _data(customer: true, earned: 3),
    discount: false,
    loyalty: true,
    name: true
  ),
  'a customer who redeemed points': (
    data: _data(customer: true, redeemed: 20),
    discount: false,
    loyalty: true,
    name: true
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fmt = CurrencyFormatter(symbol: 'Rs ', locale: 'en_US');

  /// [text] against one case: [discount] / [loyalty] / [name] say what
  /// must be there; "Walk-in" never is.
  void check(String text,
      ({ReceiptBodyData data, bool discount, bool loyalty, bool name}) c,
      {required Pattern discountRow, required Pattern loyaltyMark}) {
    expect(text.contains(discountRow), c.discount, reason: 'discount: $text');
    expect(text.contains(loyaltyMark), c.loyalty, reason: 'loyalty: $text');
    expect(text.contains('Asha'), c.name, reason: 'customer: $text');
    expect(text, isNot(contains('Walk-in')));
  }

  group('on-screen receipt', () {
    for (final e in _cases.entries) {
      testWidgets(e.key, (tester) async {
        // The test font draws every glyph a full em wide, so the 480 px
        // receipt column would overflow on long rows: scaled down here.
        await tester.pumpWidget(MaterialApp(
            home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(0.6)),
                child: Scaffold(
                    body: ReceiptBody(data: e.value.data, fmt: fmt)))));
        expect(find.text('Discount'),
            e.value.discount ? findsOneWidget : findsNothing);
        expect(find.text('Loyalty Points'),
            e.value.loyalty ? findsOneWidget : findsNothing);
        expect(find.text('Asha'), e.value.name ? findsOneWidget : findsNothing);
        expect(find.text('Walk-in'), findsNothing);
      });
    }
  });

  group('A4 PDF', () {
    for (final e in _cases.entries) {
      test(e.key, () async {
        final t =
            pdfTextRuns(await (await buildReceiptPdf(e.value.data, fmt)).save())
                .join(' ');
        check(t, e.value,
            discountRow: 'Discount', loyaltyMark: 'Loyalty Points');
      });
    }
  });

  group('roll PDF', () {
    for (final e in _cases.entries) {
      test(e.key, () async {
        final doc =
            await buildReceiptRollPdf(e.value.data, fmt, widthDots: 576);
        final t = pdfTextRuns(await doc.save()).join(' ');
        check(t, e.value, discountRow: 'Discount', loyaltyMark: 'Balance');
      });
    }
  });

  group('ESC/POS', () {
    for (final e in _cases.entries) {
      test(e.key, () async {
        final bytes = await renderReceiptBytes(e.value.data, fmt, 80);
        final t =
            String.fromCharCodes(bytes.where((b) => b >= 0x20 && b < 0x7f));
        check(t, e.value, discountRow: 'Discount', loyaltyMark: 'Balance');
        expect(t, contains('Bill '), reason: 'the bill number stays');
      });
    }
  });

  group('share text', () {
    for (final e in _cases.entries) {
      test(e.key, () {
        final t = buildReceiptText(e.value.data, fmt);
        // The text receipt has no loyalty block; its Loyalty line is the
        // redemption discount, shown when points were redeemed.
        check(
            t,
            (
              data: e.value.data,
              discount: e.value.discount,
              loyalty: e.value.data.order.pointsRedeemed > 0,
              name: e.value.name
            ),
            discountRow: 'Discount',
            loyaltyMark: 'Loyalty');
        final lines = t.split('\n');
        expect(lines[2], e.value.name ? 'Asha' : '',
            reason: 'no customer: no line, straight to the items gap');
      });
    }
  });

  test(
      'a past sale stays true: a customer with no points on that sale gets '
      'no loyalty block even with a balance today', () async {
    final d = _data(customer: true); // balance 120 today, 0 on the sale
    final t =
        pdfTextRuns(await (await buildReceiptPdf(d, fmt)).save()).join(' ');
    expect(t, isNot(contains('Balance')));
  });
}
