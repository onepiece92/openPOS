import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/cart/data/place_order.dart';
import 'package:pos_app/features/cart/domain/cart_calculator.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/printing/domain/render_receipt.dart';
import 'package:pos_app/features/receipts/domain/receipt_labels.dart';
import 'package:pos_app/features/receipts/domain/receipt_text.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// A receipt has to add up on its face. With inclusive tax the VAT is part
/// of the prices, so "Subtotal 113 / VAT 13 / Total 113" only makes sense if
/// the VAT row says it is included.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late AuditService audit;
  var seq = 0;
  final fmt = CurrencyFormatter(symbol: 'Rs ', locale: 'en_US');

  setUp(() {
    db = openInMemoryDatabase();
    audit = AuditService(db);
  });
  tearDown(() => db.close());

  Future<ReceiptBodyData> sale({
    required bool inclusive,
    double rate = 0.13,
    int redeem = 0,
  }) async {
    final p = await seedProduct(db, sku: 'A${seq++}', stock: 0);
    final customer = await seedCustomer(db, points: 500);
    final rid = await db.taxDao.upsertRate(TaxRatesCompanion.insert(
        name: 'VAT',
        rate: rate,
        inclusionType: Value(inclusive ? 'inclusive' : 'exclusive')));
    final items = [
      CartItem(
          productId: p,
          name: 'Tea',
          unitPrice: 113,
          quantity: 1,
          isTaxable: true)
    ];
    final session = CartSession(
        ticketNumber: '#1',
        openedAt: DateTime.now(),
        customerId: customer,
        loyaltyPointsToRedeem: redeem);
    final summary = CartCalculator.compute(
        items: items,
        session: session,
        selectedRates: [(await db.taxDao.getById(rid))!],
        loyaltyEnabled: true,
        loyaltyPointValue: 1,
        customerLoyaltyPoints: 500);
    final id = await placeOrder(db, audit,
        cart: items,
        summary: summary,
        session: session,
        paymentMethod: 'card',
        tenderedAmount: 0);
    return ReceiptBodyData(
        order: (await db.ordersDao.getById(id))!,
        items: await db.ordersDao.getItems(id),
        taxes: await db.ordersDao.getTaxBreakdown(id),
        businessName: 'Shop');
  }

  /// The printable text of the ESC/POS job (control bytes dropped).
  Future<String> thermalText(ReceiptBodyData data) async {
    final bytes = await renderReceiptBytes(data, fmt, 80);
    return String.fromCharCodes(bytes.where((b) => b >= 0x20 && b < 0x7f));
  }

  test('the tax row label every receipt format shares', () async {
    final incl = (await sale(inclusive: true)).taxes.single;
    final excl = (await sale(inclusive: false)).taxes.single;
    expect(taxLineLabel(incl), 'VAT (13%, incl.)');
    expect(taxLineLabel(excl), 'VAT (13%)');
    final odd = (await sale(inclusive: false, rate: 0.0825)).taxes.single;
    expect(taxLineLabel(odd), 'VAT (8.25%)', reason: 'not rounded to 8.3%');
  });

  test('thermal: inclusive VAT is marked as included', () async {
    final text = await thermalText(await sale(inclusive: true));
    expect(text, contains('VAT (13%, incl.)'));
    expect(text, contains('Rs 13.00'));
    expect(text, isNot(contains('13.0%')));
  });

  test('thermal: exclusive VAT is a plain add-on row', () async {
    final text = await thermalText(await sale(inclusive: false, redeem: 20));
    expect(text, contains('VAT (13%)'));
    expect(text, isNot(contains('incl.')));
    expect(text, contains('Rs 14.69'));
    expect(text, contains('Loyalty (20 pts)'));
    expect(text, contains('Rs 107.69'));
  });

  test('share text: inclusive VAT is marked as included', () async {
    final text = buildReceiptText(await sale(inclusive: true), fmt);
    expect(text, contains('Subtotal: Rs 113.00'));
    expect(text, contains('VAT (13%, incl.): Rs 13.00'));
    expect(text, contains('Total: Rs 113.00'));
  });

  test('share text: shows the loyalty line the other formats show', () async {
    final text =
        buildReceiptText(await sale(inclusive: false, redeem: 20), fmt);
    final lines = text.split('\n');
    expect(lines, contains('VAT (13%): Rs 14.69'));
    expect(lines, contains('Loyalty (20 pts): -Rs 20.00'));
    expect(lines, contains('Total: Rs 107.69'));
    expect(lines.indexOf('Loyalty (20 pts): -Rs 20.00'),
        lessThan(lines.indexOf('Total: Rs 107.69')));
  });

  test('share text: an order with tax but no tax lines still shows the tax',
      () async {
    // Orders brought in by CSV import carry a tax total without a breakdown.
    final data = await sale(inclusive: false);
    final text = buildReceiptText(
        ReceiptBodyData(
            order: data.order,
            items: data.items,
            taxes: const [],
            businessName: 'Shop'),
        fmt);
    expect(text.split('\n'), contains('Tax: Rs 14.69'));
  });
}
