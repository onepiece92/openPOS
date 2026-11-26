import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart'
    show Selectable, QueryRow, ResultSetImplementation, Value, Variable;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/cart/domain/cart_item.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';
import 'package:pos_app/features/cart/presentation/widgets/held_tickets_bar.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// A database whose custom selects wait for [gate]: the resume check stays
/// in flight while the test taps again.
class _GatedDb extends AppDatabase {
  _GatedDb(this.gate) : super(NativeDatabase.memory());
  final Completer<void> gate;

  @override
  Selectable<QueryRow> customSelect(String query,
      {List<Variable> variables = const [],
      Set<ResultSetImplementation> readsFrom = const {}}) {
    final inner =
        super.customSelect(query, variables: variables, readsFrom: readsFrom);
    return _GatedSelectable(inner, gate);
  }
}

class _GatedSelectable implements Selectable<QueryRow> {
  _GatedSelectable(this.inner, this.gate);
  final Selectable<QueryRow> inner;
  final Completer<void> gate;

  @override
  Future<List<QueryRow>> get() async {
    await gate.future;
    return inner.get();
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Tapping a held ticket in the sheet: one tap loads it once, a ticket with
/// no products left is removed instead of loaded; a dead tax rate is cleared.
void main() {
  late Directory tmp;
  late Box<dynamic> heldBox;
  late Box<dynamic> settingsBox;
  late AppDatabase db;
  late ProviderContainer c;
  late int cartOpens;
  late int pushes;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_resume_tap_');
    Hive.init(tmp.path);
    heldBox = await Hive.openBox<dynamic>('held_orders', bytes: Uint8List(0));
    settingsBox = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
    db = openInMemoryDatabase();
    cartOpens = 0;
    pushes = 0;
    c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      settingsBoxProvider.overrideWithValue(settingsBox),
      heldOrdersBoxProvider.overrideWithValue(heldBox),
    ]);
  });

  tearDown(() async {
    c.dispose();
    await db.close();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  CartItem item(int id) => CartItem(
      productId: id,
      name: 'P$id',
      unitPrice: 10,
      quantity: 1,
      isTaxable: false);

  Widget app() {
    final router = GoRouter(observers: [
      _Count(() => pushes++)
    ], routes: [
      GoRoute(
          path: '/',
          builder: (_, __) =>
              const Scaffold(bottomNavigationBar: HeldTicketsBar())),
      GoRoute(
          path: '/cart',
          builder: (_, __) {
            cartOpens++;
            return const Text('cart detail');
          }),
    ]);
    return UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Future<void> pumpAsync(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.tap(find.textContaining('held ticket'));
    await pumpAsync(tester);
  }

  testWidgets('a second tap while the check runs does not load twice',
      (tester) async {
    final gate = Completer<void>();
    final slow = _GatedDb(gate);
    addTearDown(slow.close);
    final a = (await tester.runAsync(() => seedProduct(slow, sku: 'A')))!;
    c.dispose();
    c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(slow),
      settingsBoxProvider.overrideWithValue(settingsBox),
      heldOrdersBoxProvider.overrideWithValue(heldBox),
    ]);
    c.read(heldOrdersProvider.notifier).hold([item(a)], ticketNumber: '#0001');
    await openSheet(tester);

    final row = find.textContaining('#0001');
    await tester.tap(row);
    await tester.pump();
    await tester.tap(row, warnIfMissed: false); // the check is still running
    await tester.pump();
    gate.complete();
    await pumpAsync(tester);

    expect(pushes, 2, reason: 'home, then the cart once');
    expect(cartOpens, 1);
    expect(c.read(cartProvider), hasLength(1));
  });

  testWidgets('a ticket with every product gone is kept, with a Delete button',
      (tester) async {
    c
        .read(heldOrdersProvider.notifier)
        .hold([item(404), item(405)], ticketNumber: '#0001');
    await openSheet(tester);

    await tester.tap(find.textContaining('#0001'));
    await pumpAsync(tester);

    expect(cartOpens, 0);
    expect(c.read(cartProvider), isEmpty);
    expect(c.read(heldOrdersProvider), hasLength(1), reason: 'kept');
    expect(find.text('None of the items on this ticket exist any more.'),
        findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Delete ticket'));
    await tester.pump(const Duration(seconds: 1));
    expect(c.read(heldOrdersProvider), isEmpty);
    await tester.pump(const Duration(seconds: 10));
  });

  group('tax rate on a held ticket', () {
    Future<int> rate({bool active = true}) =>
        db.taxDao.upsertRate(TaxRatesCompanion.insert(
            name: 'GST', rate: 0.1, isActive: Value(active)));

    test('a rate that is gone is cleared with the message', () async {
      final a = await seedProduct(db, sku: 'A');
      final held = c
          .read(heldOrdersProvider.notifier)
          .hold([item(a)], ticketNumber: '#0001', taxRateIds: [99]);

      final check =
          await c.read(heldOrdersProvider.notifier).checkForResume(held);

      expect(check.taxRateRemoved, isTrue);
      expect(check.ticket.taxRateIds, isEmpty);
      expect(check.ticket.items, hasLength(1));
      expect(check.message,
          'The tax on this ticket no longer exists and was removed.');
      // Saved back: cleaned only once.
      final saved = c.read(heldOrdersProvider).single;
      expect(saved.taxRateIds, isEmpty);
      final again =
          await c.read(heldOrdersProvider.notifier).checkForResume(saved);
      expect(again.changed, isFalse);
    });

    test('only the dead rate is removed, a live one stays', () async {
      final a = await seedProduct(db, sku: 'A');
      final live = await rate();
      final held = c
          .read(heldOrdersProvider.notifier)
          .hold([item(a)], ticketNumber: '#0001', taxRateIds: [live, 99]);
      final check =
          await c.read(heldOrdersProvider.notifier).checkForResume(held);
      expect(check.ticket.taxRateIds, [live]);
      expect(check.message, kTicketTaxRemovedMessage);
    });

    test('a rate switched off is removed with its own message', () async {
      final a = await seedProduct(db, sku: 'A');
      final r = await rate(active: false);
      final held = c
          .read(heldOrdersProvider.notifier)
          .hold([item(a)], ticketNumber: '#0001', taxRateIds: [r]);
      final check =
          await c.read(heldOrdersProvider.notifier).checkForResume(held);
      expect(check.taxRateOff, isTrue);
      expect(check.taxRateRemoved, isFalse);
      expect(check.ticket.taxRateIds, isEmpty);
      expect(check.message,
          'A tax on this ticket is switched off and was removed.');
    });

    test('a live rate, or no stored rate, is left alone', () async {
      final a = await seedProduct(db, sku: 'A');
      final r = await rate();
      final n = c.read(heldOrdersProvider.notifier);
      final live = n.hold([item(a)], ticketNumber: '#0001', taxRateIds: [r]);
      final legacy = n.hold([item(a)], ticketNumber: '#0002');
      expect((await n.checkForResume(live)).changed, isFalse);
      final check = await n.checkForResume(legacy);
      expect(check.changed, isFalse);
      expect(check.ticket.taxRateIds, isNull);
    });

    test('items and tax both gone: the ticket is kept untouched', () async {
      final held = c
          .read(heldOrdersProvider.notifier)
          .hold([item(404)], ticketNumber: '#0001', taxRateIds: [99]);
      final check =
          await c.read(heldOrdersProvider.notifier).checkForResume(held);
      expect(check.emptied, isTrue);
      expect(check.message, kTicketEmptyMessage);
      expect(c.read(heldOrdersProvider).single.taxRateIds, [99]);
    });
  });
}

/// Counts pages pushed on the navigator (not sheets or dialogs).
class _Count extends NavigatorObserver {
  _Count(this.onPush);
  final void Function() onPush;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previous) {
    if (route is PageRoute) onPush();
  }
}
