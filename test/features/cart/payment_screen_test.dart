import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/sqlite_errors.dart';
import 'package:pos_app/core/providers/audit_service_provider.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/presentation/payment_screen.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// Holds `placeOrder` open on its last step until [gate] is released, so a
/// test can act while the order is still being saved.
class _GatedAudit extends AuditService {
  _GatedAudit(super.db, this.gate);
  final Completer<void> gate;

  @override
  Future<void> orderPlaced(
    int orderId, {
    required double total,
    required String paymentMethod,
    double tip = 0,
  }) async {
    await gate.future;
    return super
        .orderPlaced(orderId,
            total: total, paymentMethod: paymentMethod, tip: tip);
  }
}

/// Confirming a payment: the cleanup after the order is written must not
/// depend on the screen still being on stage, and one sale is one order.
void main() {
  late Directory tmp;
  late Box<dynamic> heldBox;
  late Box<dynamic> settingsBox;
  late AppDatabase db;
  late Completer<void> gate; // holds placeOrder open until released
  late int productId;
  late ProviderContainer c;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_pay_');
    Hive.init(tmp.path);
    // Memory-backed boxes: file writes started inside a widget test's fake
    // clock never finish, and Hive.close() would wait on them forever.
    heldBox = await Hive.openBox<dynamic>('held_orders', bytes: Uint8List(0));
    settingsBox = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
    gate = Completer<void>();
    db = openInMemoryDatabase();
    productId = await seedProduct(db, sku: 'TEA', stock: 0, price: 10);
    c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      auditServiceProvider.overrideWithValue(_GatedAudit(db, gate)),
      settingsBoxProvider.overrideWithValue(settingsBox),
      heldOrdersBoxProvider.overrideWithValue(heldBox),
    ]);
  });

  tearDown(() async {
    c.dispose();
    if (!gate.isCompleted) gate.complete();
    await db.close();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  /// Cart with one line, parked once and resumed, so a held ticket exists.
  void resumeAHeldTicket() {
    final cart = c.read(cartProvider.notifier);
    cart.restoreItem(CartItem(
        productId: productId,
        name: 'Tea',
        unitPrice: 10,
        quantity: 2,
        isTaxable: false));
    final ticket = c.read(heldOrdersProvider.notifier).holdCurrentCart();
    c.read(cartSessionProvider.notifier).resumeTicket(ticket);
    expect(c.read(heldOrdersProvider), hasLength(1));
  }

  Widget app(ValueNotifier<bool> showPayment) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => ValueListenableBuilder<bool>(
            valueListenable: showPayment,
            builder: (_, show, __) =>
                show ? const PaymentScreen() : const Text('elsewhere'),
          ),
        ),
        GoRoute(
            path: '/receipt/:id',
            builder: (_, s) => Text('receipt ${s.pathParameters['id']}')),
      ],
    );
    return UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    gate.complete();
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Finder confirm() => find.textContaining('Confirm & Charge');

  testWidgets('cart and held ticket are cleared even if the screen closed '
      'while the order was being saved', (tester) async {
    resumeAHeldTicket();
    final showPayment = ValueNotifier(true);
    await tester.pumpWidget(app(showPayment));
    await tester.pump();

    await tester.tap(confirm());
    // The screen goes away while placeOrder is still saving.
    showPayment.value = false;
    await tester.pump();
    expect(find.text('elsewhere'), findsOneWidget);

    await settle(tester);

    final orders = await tester.runAsync(() => db.select(db.orders).get());
    expect(orders, hasLength(1), reason: 'the order itself was written');
    expect(c.read(cartProvider), isEmpty,
        reason: 'a sold cart must not stay loaded');
    expect(c.read(heldOrdersProvider), isEmpty,
        reason: 'the sale retires the held ticket');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a second tap on Confirm while placing does not sell twice',
      (tester) async {
    resumeAHeldTicket();
    final showPayment = ValueNotifier(true);
    await tester.pumpWidget(app(showPayment));
    await tester.pump();

    // Two taps land before the frame that disables the button.
    await tester.tap(confirm());
    await tester.tap(confirm(), warnIfMissed: false);

    await settle(tester);

    final orders = await tester.runAsync(() => db.select(db.orders).get());
    expect(orders, hasLength(1));
    expect(find.textContaining('receipt'), findsOneWidget);
    expect(c.read(cartProvider), isEmpty);
  });

  testWidgets('a product that no longer exists: plain message, no SQL',
      (tester) async {
    final logged = <String>[];
    final oldPrint = debugPrint;
    debugPrint = (String? m, {int? wrapWidth}) => logged.add(m ?? '');
    c.read(cartProvider.notifier).restoreItem(CartItem(
        productId: 999, // no such product: the order item's FK fails
        name: 'Gone',
        unitPrice: 10,
        quantity: 1,
        isTaxable: false));
    await tester.pumpWidget(app(ValueNotifier(true)));
    await tester.pump();

    await tester.tap(confirm());
    await settle(tester);

    expect(
        find.text('Some items or the customer on this sale no longer exist. '
            'Remove them and try again.'),
        findsOneWidget);
    expect(find.textContaining('FOREIGN KEY'), findsNothing);
    expect(find.textContaining('Sqlite'), findsNothing);
    // Support gets the error and the stack trace in the log.
    expect(logged.any((l) => l.startsWith('Sale failed:') && l.contains('#0')),
        isTrue);
    debugPrint = oldPrint;
    final orders = await tester.runAsync(() => db.select(db.orders).get());
    expect(orders, isEmpty, reason: 'the sale was rolled back');
    expect(c.read(cartProvider), hasLength(1), reason: 'cart kept to fix');
    await tester.pump(const Duration(seconds: 5)); // SnackBar runs out
  });

  test('the message for each sale failure', () {
    expect(saleFailureMessage(StateError('disk I/O error')),
        "The sale couldn't be saved. Please try again.");
    expect(
        saleFailureMessage(Exception('SqliteException(787): while executing, '
            'FOREIGN KEY constraint failed')),
        kSaleForeignKeyMessage);
  });

  group('cash tendered', () {
    void addToCart({required double price, int qty = 1}) =>
        c.read(cartProvider.notifier).restoreItem(CartItem(
            productId: productId,
            name: 'Tea',
            unitPrice: price,
            quantity: qty,
            isTaxable: false));

    String tenderedText(WidgetTester tester) => tester
        .widget<TextField>(find.widgetWithText(
            TextField, 'Amount received from customer'))
        .controller!
        .text;

    test('shows two decimals, or none for a whole amount', () {
      expect(exactAmountText(12.5), '12.50');
      expect(exactAmountText(1000), '1000');
      expect(exactAmountText(0.1 + 0.2), '0.30');
      expect(exactAmountText(987.5), '987.50');
    });

    testWidgets('starts at the exact amount due, so change starts at zero',
        (tester) async {
      addToCart(price: 12.5);
      await tester.pumpWidget(app(ValueNotifier(true)));
      await tester.pump();

      expect(tenderedText(tester), '12.50',
          reason: 'not rounded up to 1000');
      expect(find.textContaining('987.50'), findsNothing);

      // Confirming without touching the field records tendered = total.
      await tester.tap(confirm());
      await settle(tester);
      final order =
          (await tester.runAsync(() => db.select(db.orders).getSingle()))!;
      expect(order.total, 12.5);
      expect(order.tenderedAmount, 12.5);
      expect(order.changeAmount ?? 0, 0);
    });

    testWidgets('typing a larger amount gives change as before',
        (tester) async {
      addToCart(price: 12.5);
      await tester.pumpWidget(app(ValueNotifier(true)));
      await tester.pump();
      await tester.enterText(
          find.widgetWithText(TextField, 'Amount received from customer'),
          '20');
      await tester.pump();
      expect(find.textContaining('7.50'), findsOneWidget);

      await tester.tap(confirm());
      await settle(tester);
      final order =
          (await tester.runAsync(() => db.select(db.orders).getSingle()))!;
      expect(order.tenderedAmount, 20);
      expect(order.changeAmount, 7.5);
    });

    testWidgets('an untouched field follows the amount due; an edited one '
        'is left alone', (tester) async {
      addToCart(price: 12.5);
      await tester.pumpWidget(app(ValueNotifier(true)));
      await tester.pump();

      addToCart(price: 12.5); // the total changes while the screen is open
      await tester.pump();
      expect(tenderedText(tester), '25');

      await tester.enterText(
          find.widgetWithText(TextField, 'Amount received from customer'),
          '50');
      await tester.pump();
      c.read(cartProvider.notifier).clear();
      addToCart(price: 30);
      await tester.pump();
      expect(tenderedText(tester), '50');
    });
  });
}
