import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

/// A held ticket still marked as being paid is settled each time the app
/// comes back to the foreground, not only at launch.
void main() {
  testWidgets('a mark left unsettled is settled on resume', (tester) async {
    late Directory tmp;
    late Box<dynamic> box;
    late AppDatabase db;
    late ProviderContainer c;
    await tester.runAsync(() async {
      tmp = await Directory.systemTemp.createTemp('pos_settle_resume_');
      Hive.init(tmp.path);
      box = await Hive.openBox<dynamic>('held_orders', bytes: Uint8List(0));
      db = openInMemoryDatabase();
      c = ProviderContainer(overrides: [
        heldOrdersBoxProvider.overrideWithValue(box),
        databaseProvider.overrideWithValue(db),
      ]);
      c.read(heldOrdersProvider); // built with nothing to settle
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // A mark the launch could not settle, whose sale is saved.
      final pid = await seedProduct(db, sku: 'TEA');
      const key = 'feedfacefeedfacefeedfacefeedface';
      await sell(db, AuditService(db), [line(pid)], saleKey: key);
      await box.put(
          't1',
          jsonEncode({
            ...HeldOrder(
                    id: 't1',
                    ticketNumber: '#0001',
                    label: '#0001',
                    createdAt: DateTime(2026),
                    items: [line(pid)])
                .toJson(),
            'paying': {'key': key, 'at': DateTime.now().toIso8601String()},
          }));
    });
    expect(box.containsKey('t1'), isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    expect(box.containsKey('t1'), isFalse,
        reason: 'settled on resume: its sale exists');

    await tester.runAsync(() async {
      c.dispose();
      await db.close();
      await Hive.close();
      await tmp.delete(recursive: true);
    });
  });
}
