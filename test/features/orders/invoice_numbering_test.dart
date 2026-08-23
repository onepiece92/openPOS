import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/cart/data/place_order.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/orders/domain/order_number.dart';
import 'package:pos_app/features/returns/domain/void_order.dart';

import '../../_support/test_db.dart';

/// Invoice numbers: gap-free, assigned at sale time, kept on void, and
/// back-filled onto legacy rows by the v10 migration helper.
void main() {
  late AppDatabase db;
  late AuditService audit;

  setUp(() {
    db = openInMemoryDatabase();
    audit = AuditService(db);
  });
  tearDown(() => db.close());

  Future<int> seedProduct() => db.productsDao.upsert(
        ProductsCompanion.insert(sku: 'P', name: 'P', price: 5, stockQuantity: const Value(100)),
      );

  Future<int> sell(int productId,
          {double discount = 0, bool percent = false, String prefix = ''}) =>
      placeOrder(
        db,
        audit,
        cart: [
          CartItem(productId: productId, name: 'P', unitPrice: 5, quantity: 1, isTaxable: false),
        ],
        summary: const CartSummary(
          subtotal: 5,
          orderDiscount: 0,
          loyaltyDiscount: 0,
          taxLines: [],
          taxAmount: 0,
          total: 5,
          taxEnabled: false,
          pointsToEarn: 0,
        ),
        session: CartSession(
          ticketNumber: '#0001',
          openedAt: DateTime(2026),
          orderDiscount: discount,
          orderDiscountIsPercent: percent,
        ),
        paymentMethod: 'cash',
        tenderedAmount: 5,
        invoicePrefix: prefix,
      );

  test('each prefix owns an independent gap-free sequence', () async {
    final p = await seedProduct();
    final a = await sell(p); // '' prefix → #1
    final b = await sell(p, prefix: '2082/83'); // → 2082/83-1
    final c = await sell(p, prefix: '2082/83'); // → 2082/83-2
    final d = await sell(p); // '' again → #2

    Future<Order> get(int id) async => (await db.ordersDao.getById(id))!;
    expect((await get(a)).billNo, '#1');
    expect((await get(b)).billNo, '2082/83-1');
    expect((await get(c)).billNo, '2082/83-2');
    expect((await get(d)).billNo, '#2');

    // A fresh prefix restarts at 1 without disturbing the others.
    final e = await sell(p, prefix: '2083/84');
    expect((await get(e)).billNo, '2083/84-1');
    expect(await db.ordersDao.nextInvoiceNo(prefix: '2082/83'), 3);
    expect(await db.ordersDao.nextInvoiceNo(), 3);
  });

  test('the same number may exist under different prefixes, not within one',
      () async {
    final p = await seedProduct();
    await sell(p); // '' #1
    await sell(p, prefix: 'FY'); // FY-1 — same number, different prefix: fine
    expect(
      () => db.ordersDao.insertOrder(OrdersCompanion.insert(
        invoiceNo: const Value(1),
        invoicePrefix: const Value('FY'),
        subtotal: 1,
        total: 1,
        paymentMethod: 'cash',
      )),
      throwsA(anything),
    );
  });

  test('placeOrder assigns 1, 2, 3 … and stores the discount as entered',
      () async {
    final p = await seedProduct();
    final a = await sell(p);
    final b = await sell(p, discount: 10, percent: true);
    final c = await sell(p);

    final rows = [
      for (final id in [a, b, c]) (await db.ordersDao.getById(id))!,
    ];
    expect(rows.map((o) => o.invoiceNo), [1, 2, 3]);
    expect(rows.map((o) => o.displayNo), [1, 2, 3]);
    expect(rows[1].billNo, '#2');
    expect(rows[1].discountValue, 10);
    expect(rows[1].discountIsPercent, isTrue);
    expect(rows[0].discountIsPercent, isFalse);
  });

  test('a voided order keeps its number and the next sale continues after it',
      () async {
    final p = await seedProduct();
    await sell(p);
    final second = await sell(p);
    await voidOrder(db, audit, orderId: second, reason: 'test');
    final third = await sell(p);

    expect((await db.ordersDao.getById(second))!.status, 'voided');
    expect((await db.ordersDao.getById(second))!.invoiceNo, 2);
    expect((await db.ordersDao.getById(third))!.invoiceNo, 3);
  });

  test('invoice_no is unique at the database level', () async {
    final p = await seedProduct();
    final id = await sell(p);
    expect(
      () => db.ordersDao.insertOrder(OrdersCompanion.insert(
        invoiceNo: const Value(1), // already taken by `id`
        subtotal: 1,
        total: 1,
        paymentMethod: 'cash',
      )),
      throwsA(anything),
    );
    expect((await db.ordersDao.getById(id))!.invoiceNo, 1);
  });

  group('backfillInvoiceNumbers (v10 migration helper)', () {
    Future<int> legacyOrder(DateTime at) => db.ordersDao.insertOrder(
          OrdersCompanion.insert(
            subtotal: 1,
            total: 1,
            paymentMethod: 'cash',
            createdAt: Value(at),
          ),
        );

    test('numbers legacy rows by created_at then id', () async {
      final late = await legacyOrder(DateTime(2026, 3, 1));
      final early = await legacyOrder(DateTime(2026, 1, 1));
      final mid = await legacyOrder(DateTime(2026, 2, 1));

      await db.backfillInvoiceNumbers();

      expect((await db.ordersDao.getById(early))!.invoiceNo, 1);
      expect((await db.ordersDao.getById(mid))!.invoiceNo, 2);
      expect((await db.ordersDao.getById(late))!.invoiceNo, 3);
    });

    test('is idempotent and continues after the highest existing number',
        () async {
      final p = await seedProduct();
      await sell(p); // gets #1 the normal way
      final legacy = await legacyOrder(DateTime(2020));

      await db.backfillInvoiceNumbers();
      await db.backfillInvoiceNumbers(); // second run must change nothing

      // Older by date, but numbering never rewrites issued invoices:
      // the legacy row is simply appended after the current max.
      expect((await db.ordersDao.getById(legacy))!.invoiceNo, 2);
      expect(await db.ordersDao.nextInvoiceNo(), 3);
    });
  });
}
