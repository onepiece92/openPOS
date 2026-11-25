import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/presentation/usage_route_counter.dart';

/// Screen counts come from a real GoRouter, with both `go` and `push` (the
/// app opens payment, order detail, product form, backup, … with push).
void main() {
  late Box<dynamic> box;
  setUp(() async {
    Hive.init('.');
    box = await Hive.openBox<dynamic>(kUsageBoxName, bytes: Uint8List(0));
  });
  tearDown(Hive.close);

  Widget page(String name) => Scaffold(body: Text(name));

  testWidgets('go and push are both counted, by route template',
      (tester) async {
    final usage = UsageCounter(openBox: () async => box);
    await usage.ensureLoaded();
    final router = GoRouter(initialLocation: '/pos', routes: [
      GoRoute(path: '/pos', builder: (_, __) => page('pos')),
      GoRoute(path: '/payment', builder: (_, __) => page('payment')),
      GoRoute(
        path: '/orders',
        builder: (_, __) => page('orders'),
        routes: [
          GoRoute(path: ':id', builder: (_, __) => page('order')),
        ],
      ),
      GoRoute(
        path: '/products',
        builder: (_, __) => page('products'),
        routes: [
          GoRoute(path: 'add', builder: (_, __) => page('add')),
          GoRoute(path: ':id', builder: (_, __) => page('edit')),
        ],
      ),
      GoRoute(path: '/inventory', builder: (_, __) => page('inventory')),
      GoRoute(
        path: '/settings',
        builder: (_, __) => page('settings'),
        routes: [
          GoRoute(path: 'backup', builder: (_, __) => page('backup')),
          GoRoute(path: 'printer', builder: (_, __) => page('printer')),
        ],
      ),
    ]);
    addTearDown(router.dispose);
    final detach = attachUsageRouteCounter(router, usage);
    addTearDown(detach);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    Future<void> nav(void Function() f) async {
      f();
      await tester.pumpAndSettle();
    }

    await nav(() => router.push('/payment'));
    await nav(router.pop);
    await nav(() => router.go('/orders'));
    await nav(() => router.push('/orders/7'));
    await nav(router.pop);
    await nav(() => router.push('/orders/8'));
    await nav(() => router.go('/products'));
    await nav(() => router.push('/products/add'));
    await nav(() => router.push('/products/3'));
    await nav(() => router.push('/inventory'));
    await nav(() => router.go('/settings'));
    await nav(() => router.push('/settings/backup'));
    await nav(() => router.push('/settings/printer'));

    int n(UsageEvent e) => usage.counts[e]?.count ?? 0;
    expect(n(UsageEvent.screenPayment), 1);
    expect(n(UsageEvent.screenSell), 2, reason: 'start, and back from pay');
    expect(n(UsageEvent.screenOrders), 2, reason: 'go, and back from #7');
    expect(n(UsageEvent.screenOrderDetail), 2);
    expect(n(UsageEvent.screenProducts), 1);
    expect(n(UsageEvent.screenProductForm), 2);
    expect(n(UsageEvent.screenInventory), 1);
    expect(n(UsageEvent.screenSettings), 1);
    expect(n(UsageEvent.screenBackup), 1);
    expect(n(UsageEvent.screenPrinterSetup), 1);
    usage.dispose(); // writes and cancels the 30 s flush timer
  });
}
