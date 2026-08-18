import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';

/// End-to-end coverage of the zip snapshot: create → inspect → restore,
/// against real files in a temp dir (this is exactly what the app does).
void main() {
  const svc = SnapshotService();
  late Directory tmp;
  late Directory live;
  late Directory restored;

  File dbFileIn(Directory d) => File(p.join(d.path, 'pos_database.db'));
  String hivePathIn(Directory d, String box) => p.join(d.path, '$box.hive');

  /// Opens (or creates) a file-backed AppDatabase — WAL mode, like prod.
  AppDatabase openDb(File f) => AppDatabase(NativeDatabase(f));

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_snapshot_');
    live = await Directory(p.join(tmp.path, 'live')).create();
    restored = await Directory(p.join(tmp.path, 'restored')).create();
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  /// Seeds a live DB + settings box, checkpoints and closes both — the
  /// state the app is in right before it zips.
  Future<void> seedLive() async {
    final db = openDb(dbFileIn(live));
    await db.productsDao.upsert(
      ProductsCompanion.insert(sku: 'SNAP', name: 'Snapshot Widget', price: 9),
    );
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    await db.close();

    Hive.init(live.path);
    final box = await Hive.openBox<dynamic>('settings');
    await box.put('business_name', 'Test Shop');
    await box.flush();
    await Hive.close();
  }

  test('create → inspect: zip carries db, hive box and a valid manifest',
      () async {
    await seedLive();
    final zip = await svc.create(
      dbFile: dbFileIn(live),
      hiveBoxFiles: {'settings': hivePathIn(live, 'settings')},
      outDir: Directory(p.join(tmp.path, 'out')),
      schemaVersion: 9,
      now: DateTime(2026, 8, 18, 14, 5, 9),
    );

    expect(p.basename(zip.path), 'pos_backup_20260818_140509.zip');
    expect(await zip.length(), greaterThan(0));

    final m = await svc.inspect(zip);
    expect(m.formatVersion, SnapshotService.formatVersion);
    expect(m.schemaVersion, 9);
    expect(m.createdAt, DateTime(2026, 8, 18, 14, 5, 9));
    expect(m.hiveBoxes, ['settings']);
    expect(m.dbBytes, await dbFileIn(live).length());
  });

  test('restore reproduces rows and settings in a fresh location', () async {
    await seedLive();
    final zip = await svc.create(
      dbFile: dbFileIn(live),
      hiveBoxFiles: {'settings': hivePathIn(live, 'settings')},
      outDir: tmp,
      schemaVersion: 9,
    );

    // Leave a stale WAL sidecar behind to prove restore clears it.
    await File('${dbFileIn(restored).path}-wal').writeAsString('junk');

    await svc.restore(
      zip: zip,
      dbFile: dbFileIn(restored),
      hiveBoxFiles: {'settings': hivePathIn(restored, 'settings')},
      currentSchemaVersion: 9,
    );

    expect(await File('${dbFileIn(restored).path}-wal').exists(), isFalse);

    final db = openDb(dbFileIn(restored));
    final product = await db.productsDao.getBySku('SNAP');
    expect(product?.name, 'Snapshot Widget');
    await db.close();

    Hive.init(restored.path);
    final box = await Hive.openBox<dynamic>('settings');
    expect(box.get('business_name'), 'Test Shop');
  });

  test('restore refuses a snapshot from a newer schema', () async {
    await seedLive();
    final zip = await svc.create(
      dbFile: dbFileIn(live),
      hiveBoxFiles: const {},
      outDir: tmp,
      schemaVersion: 42,
    );
    expect(
      () => svc.restore(
        zip: zip,
        dbFile: dbFileIn(restored),
        hiveBoxFiles: const {},
        currentSchemaVersion: 9,
      ),
      throwsA(isA<SnapshotFormatException>()),
    );
    // Nothing was written.
    expect(await dbFileIn(restored).exists(), isFalse);
  });

  test('inspect rejects files that are not POS snapshots', () async {
    final notZip = File(p.join(tmp.path, 'x.zip'))..writeAsStringSync('hello');
    expect(() => svc.inspect(notZip), throwsA(isA<SnapshotFormatException>()));
  });

  test('listLocal is newest-first and prune keeps N', () async {
    await seedLive();
    final out = Directory(p.join(tmp.path, 'auto'));
    for (var day = 1; day <= 5; day++) {
      await svc.create(
        dbFile: dbFileIn(live),
        hiveBoxFiles: const {},
        outDir: out,
        schemaVersion: 9,
        now: DateTime(2026, 8, day),
      );
    }
    final before = await svc.listLocal(out);
    expect(before.map((f) => p.basename(f.path)).first,
        'pos_backup_20260805_000000.zip');

    final removed = await svc.prune(out, keep: 3);
    expect(removed, 2);
    final after = await svc.listLocal(out);
    expect(after.map((f) => p.basename(f.path)), [
      'pos_backup_20260805_000000.zip',
      'pos_backup_20260804_000000.zip',
      'pos_backup_20260803_000000.zip',
    ]);
  });
}
