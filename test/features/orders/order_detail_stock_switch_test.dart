import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/tables/orders_table.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/orders/presentation/order_detail_screen.dart';

import '../../_support/sales.dart';
import '../../_support/temp_hive.dart';
import '../../_support/test_db.dart';

/// The refund's "Restock items" and the void text's stock part appear only
/// when the order owes stock back: a stock-linked (v16) order by its own
/// rows, whatever the switch; a legacy order while Stock tracking is on,
/// never for a CSV import (IMP).
void main() {
  late AppDatabase db;

  setUp(() async {
    db = openInMemoryDatabase();
    addTearDown(db.close);
  });

  /// [order] creates the order shown; by default a legacy one (no
  /// stock_linked), with [points] earned.
  Future<void> pump(WidgetTester tester,
      {required bool stock,
      int points = 0,
      String prefix = '',
      Future<int> Function()? order}) async {
    final settings = await tester.runAsync(openTempSettingsBox);
    await settings!.put(kFeaturesKey,
        {for (final f in Feature.values) f.name: true}..['stockTracking'] = stock);
    final id = await tester.runAsync(order ??
        () => db.ordersDao.insertOrder(OrdersCompanion.insert(
            subtotal: 10,
            total: 10,
            paymentMethod: 'cash',
            invoicePrefix: Value(prefix),
            pointsEarned: Value(points))));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        settingsBoxProvider.overrideWithValue(settings),
      ],
      child: MaterialApp(home: OrderDetailScreen(orderId: id!)),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> open(WidgetTester tester, String button) async {
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
  }

  /// A v16 sale of 3 × a product with [stockBefore] units (0 = untracked).
  Future<int> Function() linkedSale({int stockBefore = 10}) => () async {
        final p = await seedProduct(db, sku: 'P', stock: stockBefore);
        return sell(db, AuditService(db), [line(p, qty: 3)]);
      };

  Future<bool> restockOffered(WidgetTester tester) async {
    await open(tester, 'Refund');
    return find.byKey(const ValueKey('refund-restock')).evaluate().isNotEmpty;
  }

  String voidText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('void-text'))).data!;

  group('stock-linked order: by its rows, whatever the switch', () {
    for (final stock in [true, false]) {
      testWidgets('stock owed, tracking ${stock ? 'on' : 'off'}: offered',
          (tester) async {
        await pump(tester, stock: stock, order: linkedSale());
        expect(await restockOffered(tester), isTrue);
      });

      testWidgets('stock owed, tracking ${stock ? 'on' : 'off'}: void text',
          (tester) async {
        await pump(tester, stock: stock, order: linkedSale());
        await open(tester, 'Void');
        expect(voidText(tester),
            voidDialogText(restocks: true, points: false));
      });
    }

    testWidgets('nothing owed (untracked product): not offered',
        (tester) async {
      await pump(tester, stock: true, order: linkedSale(stockBefore: 0));
      expect(await restockOffered(tester), isFalse);
    });

    testWidgets('nothing owed: the void text leaves stock out',
        (tester) async {
      await pump(tester, stock: true, order: linkedSale(stockBefore: 0));
      await open(tester, 'Void');
      expect(voidText(tester), 'This marks the order as voided.');
    });
  });

  group('legacy CSV import (IMP): never', () {
    testWidgets('no "Restock items", tracking on', (tester) async {
      await pump(tester, stock: true, prefix: kImportedInvoicePrefix);
      expect(await restockOffered(tester), isFalse);
    });

    testWidgets('the void text leaves stock out', (tester) async {
      await pump(tester, stock: true, prefix: kImportedInvoicePrefix);
      await open(tester, 'Void');
      expect(voidText(tester), 'This marks the order as voided.');
    });
  });

  testWidgets('Stock tracking off: no "Restock items" on a refund',
      (tester) async {
    await pump(tester, stock: false);
    await open(tester, 'Refund');
    expect(find.byKey(const ValueKey('refund-restock')), findsNothing);
  });

  testWidgets('Stock tracking on: "Restock items" is offered', (tester) async {
    await pump(tester, stock: true);
    await open(tester, 'Refund');
    expect(find.byKey(const ValueKey('refund-restock')), findsOneWidget);
  });

  for (final (stock, points, text) in [
    (true, 0, voidDialogText(restocks: true, points: false)),
    (false, 0, 'This marks the order as voided.'),
    (false, 5, voidDialogText(restocks: false, points: true)),
    (true, 5, voidDialogText(restocks: true, points: true)),
  ]) {
    testWidgets('void text, stock ${stock ? 'on' : 'off'}, points $points',
        (tester) async {
      await pump(tester, stock: stock, points: points);
      await open(tester, 'Void');
      expect(
          tester.widget<Text>(find.byKey(const ValueKey('void-text'))).data,
          text);
    });
  }
}
