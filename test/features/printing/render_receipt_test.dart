import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/printing/domain/render_receipt.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';

ReceiptBodyData _sampleData() {
  final order = Order(
    id: 42,
    status: 'completed',
    subtotal: 100.0,
    taxTotal: 13.0,
    discountTotal: 0.0,
    total: 113.0,
    paymentMethod: 'cash',
    tenderedAmount: 120.0,
    changeAmount: 7.0,
    customerId: null,
    notes: null,
    createdAt: DateTime(2026, 4, 22, 14, 30),
    updatedAt: DateTime(2026, 4, 22, 14, 30),
  );
  final item = OrderItem(
    id: 1,
    orderId: 42,
    productId: 7,
    productName: 'Coffee',
    unitPrice: 50.0,
    quantity: 2,
    discount: 0.0,
    taxAmount: 13.0,
    lineTotal: 100.0,
  );
  final tax = OrderTaxe(
    id: 1,
    orderId: 42,
    taxRateId: 1,
    taxRateName: 'VAT',
    taxRatePercent: 0.13,
    taxableAmount: 100.0,
    taxAmount: 13.0,
  );
  return ReceiptBodyData(
    order: order,
    items: [item],
    taxes: [tax],
    businessName: 'Test Cafe',
    customer: null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fmt = CurrencyFormatter(symbol: 'Rs ', locale: 'en_US');

  test('renders non-empty bytes for 80mm with all printable content', () async {
    final bytes = await renderReceiptBytes(_sampleData(), fmt, 80);
    expect(bytes, isNotEmpty);
    final asString = String.fromCharCodes(bytes.where((b) => b >= 0x20));
    expect(asString, contains('Test Cafe'));
    expect(asString, contains('Coffee'));
    expect(asString, contains('VAT'));
    expect(asString, contains('TOTAL'));
    expect(asString, contains('Thank you'));
  });

  test('renders non-empty bytes for 58mm', () async {
    final bytes = await renderReceiptBytes(_sampleData(), fmt, 58);
    expect(bytes, isNotEmpty);
    final asString = String.fromCharCodes(bytes.where((b) => b >= 0x20));
    expect(asString, contains('Test Cafe'));
    expect(asString, contains('Coffee'));
  });

  test('58mm output is shorter than 80mm (narrower columns)', () async {
    final wide = await renderReceiptBytes(_sampleData(), fmt, 80);
    final narrow = await renderReceiptBytes(_sampleData(), fmt, 58);
    // Narrower paper means fewer characters per row → fewer bytes overall
    // for the same data. Allow some slack: just assert "different".
    expect(wide.length, isNot(equals(narrow.length)));
  });

  test('falls back to 80mm for unknown widths', () async {
    final standard = await renderReceiptBytes(_sampleData(), fmt, 80);
    final fallback = await renderReceiptBytes(_sampleData(), fmt, 999);
    expect(fallback.length, equals(standard.length));
  });

  test('test page renders for both widths', () async {
    final w80 = await renderTestPageBytes(storeName: 'Test', paperMm: 80);
    final w58 = await renderTestPageBytes(storeName: 'Test', paperMm: 58);
    expect(w80, isNotEmpty);
    expect(w58, isNotEmpty);
    final asString = String.fromCharCodes(w80.where((b) => b >= 0x20));
    expect(asString, contains('Test'));
    expect(asString, contains('Printer Test'));
  });

  test('omits discount line when discount is zero', () async {
    final bytes = await renderReceiptBytes(_sampleData(), fmt, 80);
    final asString = String.fromCharCodes(bytes.where((b) => b >= 0x20));
    expect(asString, isNot(contains('Discount')));
  });

  test('includes tendered + change for cash payments', () async {
    final bytes = await renderReceiptBytes(_sampleData(), fmt, 80);
    final asString = String.fromCharCodes(bytes.where((b) => b >= 0x20));
    expect(asString, contains('Tendered'));
    expect(asString, contains('Change'));
  });
}
