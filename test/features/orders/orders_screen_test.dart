import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/customers/domain/customers_provider.dart';
import 'package:pos_app/features/orders/domain/order_history.dart';
import 'package:pos_app/features/orders/presentation/orders_screen.dart';

import '../../_support/test_db.dart';

/// The order-history screen on top of paged data: date groups, the summary
/// bar, older orders on demand, and SQL search from the search field.
void main() {
  late Directory tmp;
  late Box<dynamic> settingsBox;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_orders_');
    Hive.init(tmp.path);
    settingsBox = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
    db = openInMemoryDatabase();
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      settingsBoxProvider.overrideWithValue(settingsBox),
      orderHistoryProvider
          .overrideWith((ref) => OrderHistoryNotifier(db, pageSize: 4)),
    ]);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  Future<void> order(int invoiceNo, DateTime at,
          {int? customerId, String status = 'completed'}) =>
      db.ordersDao.insertOrder(OrdersCompanion.insert(
        subtotal: 100,
        total: 100,
        paymentMethod: 'cash',
        status: Value(status),
        invoiceNo: Value(invoiceNo),
        customerId: Value(customerId),
        createdAt: Value(at),
      ));

  /// Lets real database I/O finish, then rebuilds.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: OrdersScreen()),
    ));
    await settle(tester);
  }

  testWidgets('groups by date, summarises today, and pages to older orders',
      (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 0, 0, 30);
    await tester.runAsync(() async {
      await order(1, today.subtract(const Duration(days: 40)));
      await order(2, today.subtract(const Duration(days: 39)));
      await order(3, today.subtract(const Duration(days: 1)),
          status: 'voided');
      await order(4, today.subtract(const Duration(days: 1)));
      await order(5, today);
      await order(6, today.add(const Duration(seconds: 1)));
    });

    await pumpScreen(tester);

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Voided'), findsOneWidget);
    expect(find.text("Today's orders"), findsOneWidget);
    expect(find.text('2'), findsOneWidget, reason: "today's order count");
    expect(find.text('Order #6'), findsOneWidget);
    expect(find.text('Order #3'), findsOneWidget);
    expect(find.text('Order #2'), findsNothing, reason: 'beyond page one');

    await tester.tap(find.text('Show older orders'));
    await settle(tester);

    expect(find.text('Order #2'), findsOneWidget);
    expect(find.text('Order #1'), findsOneWidget);
    expect(find.text('Show older orders'), findsNothing);
  });

  testWidgets('typing a bill number or a customer name searches all history',
      (tester) async {
    final now = DateTime.now();
    await tester.runAsync(() async {
      final asha = await db.customersDao
          .upsert(CustomersCompanion.insert(name: 'Asha Gurung'));
      await order(1, now.subtract(const Duration(days: 900)),
          customerId: asha);
      for (var i = 2; i <= 12; i++) {
        await order(i, now.subtract(Duration(days: 12 - i)));
      }
    });
    await pumpScreen(tester);
    expect(find.text('Order #1'), findsNothing);

    await tester.enterText(find.byType(TextField), 'gurung');
    await settle(tester);
    expect(find.text('Order #1'), findsOneWidget);
    expect(find.text('Order #12'), findsNothing);
    expect(find.text("Today's orders"), findsNothing,
        reason: 'the summary bar hides during a search, as before');

    await tester.enterText(find.byType(TextField), '#7');
    await settle(tester);
    expect(find.text('Order #7'), findsOneWidget);
    expect(find.text('Order #1'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await settle(tester);
    expect(find.text('No orders match "zzz"'), findsOneWidget);
  });

  testWidgets(
      'Customers off: orders still show their stored customer, and the '
      'customer list is never watched', (tester) async {
    final id = await tester.runAsync(() => db.customersDao
        .upsert(CustomersCompanion.insert(name: 'Asha Rai')));
    await tester.runAsync(() => order(1, DateTime.now(), customerId: id));
    await settingsBox.put(
        kFeaturesKey, {for (final f in Feature.values) f.name: true}
          ..['customers'] = false);
    container.dispose();
    var listReads = 0;
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      settingsBoxProvider.overrideWithValue(settingsBox),
      orderHistoryProvider
          .overrideWith((ref) => OrderHistoryNotifier(db, pageSize: 4)),
      customersStreamProvider.overrideWith((ref) {
        listReads++;
        return const Stream<List<Customer>>.empty();
      }),
    ]);
    await pumpScreen(tester);
    expect(find.textContaining('Asha Rai'), findsOneWidget);
    expect(listReads, 0);
  });

  testWidgets(
      'Customers off: names stay on screen while an older page loads, and '
      'only new customers are looked up', (tester) async {
    final ids = <int>[];
    await tester.runAsync(() async {
      for (var i = 0; i < 6; i++) {
        ids.add(await db.customersDao
            .upsert(CustomersCompanion.insert(name: 'Cust$i')));
      }
      final now = DateTime.now();
      for (var i = 0; i < 6; i++) {
        await order(i + 1, now.subtract(Duration(minutes: i)),
            customerId: ids[i]);
      }
    });
    await settingsBox.put(
        kFeaturesKey, {for (final f in Feature.values) f.name: true}
          ..['customers'] = false);
    await pumpScreen(tester);
    expect(find.textContaining('Cust0'), findsOneWidget);
    await tester.ensureVisible(find.text('Show older orders'));
    await tester.tap(find.text('Show older orders'));
    await tester.pump(); // the next page is in, its names are loading
    expect(find.textContaining('Cust0'), findsOneWidget,
        reason: 'names already looked up never blank');
    await settle(tester);
    await tester.scrollUntilVisible(find.textContaining('Cust5'), 300,
        scrollable: find.byType(Scrollable).last);
    expect(find.textContaining('Cust5'), findsOneWidget);
  });
}
