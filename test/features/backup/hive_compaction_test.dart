import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/settings/data/factory_reset.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';

import '../../_support/test_db.dart';

/// Hive files are append-only: a deleted value stays in the .hive bytes
/// until the box is compacted. A factory reset and a backup must not leave
/// (or copy) deleted shop data that way.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late Box<dynamic> settings, held, usage;

  bool fileHas(String path, String needle) =>
      latin1.decode(File(path).readAsBytesSync()).contains(needle);
  bool bytesHave(List<int> bytes, String needle) =>
      latin1.decode(bytes).contains(needle);

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('pos_compact_');
    Hive.init(tmp.path);
    settings = await Hive.openBox<dynamic>('settings');
    held = await Hive.openBox<dynamic>('held_orders');
    usage = await Hive.openBox<dynamic>(kUsageBoxName);
  });
  tearDown(() async {
    await Hive.close();
    tmp.deleteSync(recursive: true);
  });

  test('after a factory reset the .hive files hold no erased value',
      () async {
    await settings.put('shop_name', 'SECRET-SHOP-7731');
    await held.put('t1', jsonEncode({'label': 'SECRET-TICKET-4410'}));
    await usage.put('e.note', 'SECRET-USAGE-5521');
    for (final b in [settings, held, usage]) {
      await b.flush();
    }
    // The check can see the values while they are there.
    expect(fileHas(settings.path!, 'SECRET-SHOP-7731'), isTrue);
    expect(fileHas(held.path!, 'SECRET-TICKET-4410'), isTrue);
    expect(fileHas(usage.path!, 'SECRET-USAGE-5521'), isTrue);

    await eraseLocalStores(
        settings: settings,
        heldOrders: held,
        usage: usage,
        receipts: Directory(p.join(tmp.path, 'receipts')));

    expect(fileHas(settings.path!, 'SECRET-SHOP-7731'), isFalse);
    expect(fileHas(held.path!, 'SECRET-TICKET-4410'), isFalse);
    expect(fileHas(usage.path!, 'SECRET-USAGE-5521'), isFalse);
  });

  test('a backup never carries a held ticket deleted before it', () async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async => tmp.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final db = openInMemoryDatabase();
    addTearDown(db.close);
    final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);

    await held.put('t1', jsonEncode({'label': 'SECRET-TICKET-8812'}));
    await held.put('t2', jsonEncode({'label': 'kept ticket'}));
    await held.delete('t1');
    await held.flush();
    expect(fileHas(held.path!, 'SECRET-TICKET-8812'), isTrue,
        reason: 'Hive keeps the deleted value until compacted');

    final zip = await c
        .read(snapshotCoordinatorProvider)
        .create(Directory(p.join(tmp.path, 'out')), includePhotos: false);

    final entry = ZipDecoder()
        .decodeBytes(zip.readAsBytesSync())
        .find('hive/held_orders.hive')!;
    final bytes = entry.readBytes()!;
    expect(bytesHave(bytes, 'kept ticket'), isTrue);
    expect(bytesHave(bytes, 'SECRET-TICKET-8812'), isFalse);
    expect(fileHas(held.path!, 'SECRET-TICKET-8812'), isFalse);
  });
}
