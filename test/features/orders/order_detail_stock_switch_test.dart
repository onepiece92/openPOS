import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/orders/presentation/order_detail_screen.dart';

import '../../_support/temp_hive.dart';
import '../../_support/test_db.dart';

/// The order screen follows Stock tracking: the refund's "Restock items"
/// and the void text's stock part only while it is on.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = openInMemoryDatabase();
    addTearDown(db.close);
  });

  Future<void> pump(WidgetTester tester,
      {required bool stock, int points = 0}) async {
    final settings = await tester.runAsync(openTempSettingsBox);
    await settings!.put(kFeaturesKey,
        {for (final f in Feature.values) f.name: true}..['stockTracking'] = stock);
    final id = await tester.runAsync(() => db.ordersDao.insertOrder(
        OrdersCompanion.insert(
            subtotal: 10,
            total: 10,
            paymentMethod: 'cash',
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
