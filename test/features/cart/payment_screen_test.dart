import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
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
  }) async {
    await gate.future;
    return super
        .orderPlaced(orderId, total: total, paymentMethod: paymentMethod);
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
}
