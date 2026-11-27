import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';

import '../../_support/sales.dart';

/// The OS or the user can clear the cache folder between launches, and a
/// fresh macOS container may not have it yet. A backup must still work:
/// VACUUM INTO can't create its own parent folder.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory docs;
  late Directory tmp;
  late AppDatabase db;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    docs = Directory.systemTemp.createTempSync('pos_missing_tmp_');
    tmp = Directory(p.join(docs.path, 'caches', 'not_created_yet'));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            channel,
            (call) async => call.method == 'getTemporaryDirectory'
                ? tmp.path
                : docs.path);
    Hive.init(docs.path);
    for (final name in kSnapshotHiveBoxes) {
      await Hive.openBox<dynamic>(name);
    }
    db = AppDatabase(NativeDatabase(File(p.join(docs.path, 'pos.db'))));
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await db.close();
    await Hive.close();
    docs.deleteSync(recursive: true);
  });

  test('a backup is made even when the temp folder does not exist', () async {
    await seedProduct(db, sku: 'A');
    expect(tmp.existsSync(), isFalse);
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(c.dispose);
    final out = Directory(p.join(docs.path, 'out'))..createSync();

    final zip = await c.read(snapshotCoordinatorProvider).create(out);

    expect(zip.existsSync(), isTrue);
    expect(zip.lengthSync(), greaterThan(0));
  });
}
