import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/core/utils/money.dart';
import 'package:pos_app/features/backup/data/backup_repository.dart';
import 'package:pos_app/features/cart/data/place_order.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/orders/presentation/order_detail_screen.dart';
import 'package:pos_app/features/returns/domain/process_return.dart';
import 'package:pos_app/features/returns/domain/void_order.dart';
import 'package:pos_app/features/tips/tip_math.dart';
import 'package:pos_app/features/tips/tips_settings.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

void main() {
  late AppDatabase db;
  late AuditService audit;
  late int pid;

  setUp(() async {
    db = openInMemoryDatabase();
    audit = AuditService(db);
    pid = await seedProduct(db, sku: 'T', stock: 100, price: 100);
  });
  tearDown(() => db.close());

  CartSummary summaryOf(double total) => CartSummary(
        subtotal: total,
        orderDiscount: 0,
        loyaltyDiscount: 0,
        taxLines: const [],
        taxAmount: 0,
        total: total,
        taxEnabled: false,
        pointsToEarn: 0,
      );

  Future<int> sale({double total = 100, double tip = 0}) => placeOrder(db, audit,
      cart: [line(pid, price: total)],
      summary: summaryOf(total),
      session: CartSession(ticketNumber: '#1', openedAt: DateTime(2026, 1, 1)),
      paymentMethod: 'card',
      tenderedAmount: 0,
      tipAmount: tip);

  Future<List<AuditLogData>> auditRows(String action) async =>
      (await db.select(db.auditLog).get())
          .where((a) => a.entityType == 'order' && a.action == action)
          .toList();

  Future<void> tipOnlyRefund(int id) => processReturn(db, audit,
      orderId: id,
      amount: 0,
      restock: false,
      trackStock: true,
      refundTip: true);

  group('tip cap in placeOrder', () {
    test('the cap is 10x the sale, or 1000 on a free order', () {
      expect(kTipMaxFactor, 10);
      expect(maxTipFor(100), 1000);
      expect(maxTipFor(0), 1000);
      expect(maxTipFor(999999999), kMaxMoneyAmount);
    });

    test('a tip up to 10x is stored; more is refused and nothing is written',
        () async {
      final id = await sale(tip: 1000);
      expect((await db.ordersDao.getById(id))!.tipAmount, 1000);
      await expectLater(sale(tip: 1500), throwsA(isA<ArgumentError>()));
      await expectLater(sale(tip: 99999999999), throwsA(isA<ArgumentError>()));
      expect(await db.select(db.orders).get(), hasLength(1));
    });

    test('the error says what the limit is', () async {
      await expectLater(sale(tip: 1000.01),
          throwsA(predicate((e) => '$e'.contains('at most 1000.00'))));
    });

    test('a zero-total order allows a small tip only', () async {
      await sale(total: 0, tip: 1000);
      await expectLater(
          sale(total: 0, tip: 1001), throwsA(isA<ArgumentError>()));
    });
  });

  group('audit', () {
    test('place records the tip', () async {
      await sale(tip: 15);
      final row = (await auditRows('place')).single;
      expect(row.newValue, contains('"tip":15.0'));
    });

    test('refund records the tip refunded; a tip-only refund too', () async {
      final id = await sale(tip: 15);
      await tipOnlyRefund(id);
      var row = (await auditRows('refund')).single;
      expect(row.newValue, contains('"amount":0.0'));
      expect(row.newValue, contains('"tip":15.0'));

      final id2 = await sale(tip: 5);
      await processReturn(db, audit,
          orderId: id2, amount: 100, restock: false, trackStock: true);
      row = (await auditRows('refund')).last;
      expect(row.newValue, contains('"tip":5.0'));
    });

    test('void records the tip handed back, less what a refund returned',
        () async {
      final a = await sale(tip: 20);
      await voidOrder(db, audit, orderId: a, reason: 'x', trackStock: true);
      expect((await auditRows('void')).single.newValue, contains('"tip":20.0'));

      final b = await sale(tip: 20);
      await tipOnlyRefund(b);
      await voidOrder(db, audit, orderId: b, reason: 'y', trackStock: true);
      expect((await auditRows('void')).last.newValue, contains('"tip":0.0'));
    });
  });

  test('a second tip-only refund says the tip was already refunded', () async {
    final id = await sale(tip: 15);
    await tipOnlyRefund(id);
    await expectLater(
        tipOnlyRefund(id),
        throwsA(predicate(
            (e) => '$e'.contains('The tip was already refunded.'))));
  });

  group('parseTipPresets', () {
    List<double> ok(String raw) {
      final out = <double>[];
      expect(parseTipPresets(raw, out), isNull, reason: raw);
      return out;
    }

    test('rejects NaN and Infinity', () {
      final out = <double>[];
      for (final bad in ['NaN', 'Infinity', '10, NaN', '-Infinity', '1e999']) {
        expect(parseTipPresets(bad, out), isNotNull, reason: bad);
      }
    });

    test('rounds to one decimal', () {
      expect(ok('12.34, 17.96'), [12.3, 18.0]);
      expect(ok('12.5'), [12.5]);
    });

    test('a value that rounds to zero is refused', () {
      expect(parseTipPresets('0.04', <double>[]), isNotNull);
    });
  });

  group('CSV import: the Tip value', () {
    Future<double> importedTip(String tip) async {
      await db.productsDao.upsert(
          ProductsCompanion.insert(sku: 'TEA', name: 'Tea', price: 100));
      final csv = 'Order ID,Status,Subtotal,Tax Total,Discount,Total,Tip,'
          'Payment Method,Tendered,Change,Customer Name,Notes,Created At,'
          'Item Product ID,Item Name,Item SKU,Item Price,Item Qty,'
          'Item Discount,Item Tax,Item Total\r\n'
          '7,completed,100,0,0,100,$tip,cash,100,0,,,2026-03-01T10:00:00.000,'
          '1,Tea,TEA,100,1,0,0,100\r\n';
      await BackupRepository(db).importOrdersReport(csv);
      return (await db.select(db.orders).getSingle()).tipAmount;
    }

    test('rounded to the cent', () async {
      expect(await importedTip('12.3456'), 12.35);
    });

    test('capped at the largest money amount', () async {
      expect(await importedTip('99999999999'), kMaxMoneyAmount);
    });

    test('negative reads as zero', () async {
      expect(await importedTip('-4'), 0);
    });
  });

  test('void hand-back text', () {
    expect(voidHandBackText('Rs 115.00', 'Rs 15.00'),
        'Hand back Rs 115.00 including the tip of Rs 15.00.');
    expect(
        voidDialogText(
            restocks: false,
            points: false,
            handBack: voidHandBackText('115', '15')),
        'This marks the order as voided. '
        'Hand back 115 including the tip of 15.');
  });
}
