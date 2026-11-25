import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sql;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';

/// End-to-end coverage of the zip snapshot: create → inspect → restore,
/// against real files in a temp dir (this is exactly what the app does).
void main() {
  const svc = SnapshotService();
  const schema = AppDatabase.currentSchemaVersion;
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

  /// Seeds a DB + settings box in [dir], checkpoints and closes both — the
  /// state the app is in right before it zips / restores.
  Future<void> seed(Directory dir,
      {String sku = 'SNAP',
      String name = 'Snapshot Widget',
      String shop = 'Test Shop'}) async {
    final db = openDb(dbFileIn(dir));
    await db.productsDao.upsert(
      ProductsCompanion.insert(sku: sku, name: name, price: 9),
    );
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    await db.close();

    Hive.init(dir.path);
    final box = await Hive.openBox<dynamic>('settings');
    await box.put('business_name', shop);
    await box.flush();
    await Hive.close();
  }

  Future<void> seedLive() => seed(live);

  Future<String?> productName(Directory dir, String sku) async {
    final db = openDb(dbFileIn(dir));
    try {
      return (await db.productsDao.getBySku(sku))?.name;
    } finally {
      await db.close();
    }
  }

  Future<String?> shopName(Directory dir) async {
    Hive.init(dir.path);
    final box = await Hive.openBox<dynamic>('settings');
    final v = box.get('business_name') as String?;
    await Hive.close();
    return v;
  }

  /// A hand-built zip with an arbitrary DB entry and a manifest that claims
  /// whatever we tell it to.
  File craftZip(List<int> dbBytes,
      {int schemaVersion = schema, int formatVersion = 1}) {
    final archive = Archive()
      ..addFile(ArchiveFile.bytes(SnapshotService.dbEntryName, dbBytes))
      ..addFile(ArchiveFile.string(
        SnapshotService.manifestName,
        jsonEncode(SnapshotManifest(
          formatVersion: formatVersion,
          schemaVersion: schemaVersion,
          createdAt: DateTime(2026),
          dbBytes: dbBytes.length,
          hiveBoxes: const [],
        ).toJson()),
      ));
    return File(p.join(tmp.path, 'crafted.zip'))
      ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));
  }

  /// Raw SQLite file (no Drift) with the given user_version.
  List<int> rawSqlite(int userVersion) {
    final f = File(p.join(tmp.path, 'raw_$userVersion.db'));
    final db = sql.sqlite3.open(f.path)
      ..execute('CREATE TABLE t (x INTEGER)')
      ..execute('INSERT INTO t VALUES (1)')
      ..execute('PRAGMA user_version = $userVersion');
    db.dispose();
    return f.readAsBytesSync();
  }

  /// Asserts a rejected restore left the live store exactly as it was.
  Future<void> expectLiveUntouched() async {
    expect(await productName(live, 'SNAP'), 'Snapshot Widget');
    final leftovers = live
        .listSync()
        .map((e) => p.basename(e.path))
        .where((n) => n.contains('.tmp') || n.contains('.bak'));
    expect(leftovers, isEmpty);
  }

  Future<void> expectRejected(File zip) async {
    await expectLater(
      svc.restore(
        zip: zip,
        dbFile: dbFileIn(live),
        hiveBoxFiles: {'settings': hivePathIn(live, 'settings')},
        currentSchemaVersion: schema,
      ),
      throwsA(isA<SnapshotFormatException>()),
    );
    await expectLiveUntouched();
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
    // Written via a temp name; nothing partial left behind.
    expect(
        Directory(p.join(tmp.path, 'out'))
            .listSync()
            .map((e) => p.basename(e.path)),
        ['pos_backup_20260818_140509.zip']);

    final m = await svc.inspect(zip);
    expect(m.formatVersion, SnapshotService.formatVersion);
    expect(m.schemaVersion, 9);
    expect(m.createdAt, DateTime(2026, 8, 18, 14, 5, 9));
    expect(m.hiveBoxes, ['settings']);
    expect(m.dbBytes, await dbFileIn(live).length());
  });

  test('VACUUM INTO on an open DB (as the app snapshots) round-trips',
      () async {
    final db = openDb(dbFileIn(live));
    await db.productsDao.upsert(
      ProductsCompanion.insert(sku: 'VAC', name: 'Uncheckpointed', price: 1),
    );
    // No checkpoint: the row may still be only in the WAL.
    final copy = File(p.join(tmp.path, "it's a copy.db"));
    await db.customStatement(
        "VACUUM INTO '${copy.path.replaceAll("'", "''")}'");
    await db.close();

    SnapshotService.verifyDatabaseFile(copy, currentSchemaVersion: schema);
    final zip = await svc.create(
      dbFile: copy,
      hiveBoxFiles: const {},
      outDir: tmp,
      schemaVersion: schema,
    );
    await svc.restore(
      zip: zip,
      dbFile: dbFileIn(restored),
      hiveBoxFiles: const {},
      currentSchemaVersion: schema,
    );
    expect(await productName(restored, 'VAC'), 'Uncheckpointed');
  });

  test('restore reproduces rows and settings in a fresh location', () async {
    await seedLive();
    final zip = await svc.create(
      dbFile: dbFileIn(live),
      hiveBoxFiles: {'settings': hivePathIn(live, 'settings')},
      outDir: tmp,
      schemaVersion: schema,
    );

    // Leave a stale WAL sidecar behind to prove restore clears it.
    await File('${dbFileIn(restored).path}-wal').writeAsString('junk');

    await svc.restore(
      zip: zip,
      dbFile: dbFileIn(restored),
      hiveBoxFiles: {'settings': hivePathIn(restored, 'settings')},
      currentSchemaVersion: schema,
    );

    expect(await File('${dbFileIn(restored).path}-wal').exists(), isFalse);
    expect(await productName(restored, 'SNAP'), 'Snapshot Widget');
    expect(await shopName(restored), 'Test Shop');
  });

  test('valid restore over live data swaps it and keeps the old as .bak',
      () async {
    await seed(restored, sku: 'NEW', name: 'From Backup', shop: 'New Shop');
    final zip = await svc.create(
      dbFile: dbFileIn(restored),
      hiveBoxFiles: {'settings': hivePathIn(restored, 'settings')},
      outDir: tmp,
      schemaVersion: schema,
    );
    await seedLive();
    // Simulate a WAL the old connection left behind: it must travel with
    // the .bak, not be replayed onto the restored DB.
    await File('${dbFileIn(live).path}-wal').writeAsBytes(const []);

    await svc.restore(
      zip: zip,
      dbFile: dbFileIn(live),
      hiveBoxFiles: {'settings': hivePathIn(live, 'settings')},
      currentSchemaVersion: schema,
    );

    expect(await productName(live, 'NEW'), 'From Backup');
    expect(await productName(live, 'SNAP'), isNull);
    expect(await shopName(live), 'New Shop');
    expect(File('${dbFileIn(live).path}.bak').existsSync(), isTrue);
    expect(File('${dbFileIn(live).path}.bak-wal').existsSync(), isTrue);
    expect(File('${hivePathIn(live, 'settings')}.bak').existsSync(), isTrue);
    expect(File('${dbFileIn(live).path}.restore.tmp').existsSync(), isFalse);
  });

  test('restore refuses a snapshot whose manifest claims a newer schema',
      () async {
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

  test('garbage DB entry is rejected and the live DB is unchanged', () async {
    await seedLive();
    await expectRejected(craftZip(utf8.encode('definitely not sqlite')));
  });

  test('truncated DB entry is rejected and the live DB is unchanged',
      () async {
    await seed(restored);
    final full = dbFileIn(restored).readAsBytesSync();
    await seedLive();
    await expectRejected(craftZip(full.sublist(0, full.length ~/ 2)));
  });

  test('DB with corrupted pages fails integrity_check', () async {
    await seed(restored);
    final bytes = dbFileIn(restored).readAsBytesSync();
    // Keep the 100-byte header intact; scribble over the rest of page 1+.
    for (var i = 120; i < bytes.length; i += 7) {
      bytes[i] = 0xAB;
    }
    await seedLive();
    await expectRejected(craftZip(bytes));
  });

  test('DB with a higher user_version is rejected despite the manifest',
      () async {
    await seedLive();
    // Manifest says "current schema"; the file itself says otherwise.
    await expectRejected(craftZip(rawSqlite(schema + 1)));
  });

  test('DB with user_version 0 is rejected', () async {
    await seedLive();
    await expectRejected(craftZip(rawSqlite(0)));
  });

  test('unsupported manifest formatVersion is rejected', () async {
    await seed(restored);
    await seedLive();
    await expectRejected(craftZip(dbFileIn(restored).readAsBytesSync(),
        formatVersion: SnapshotService.formatVersion + 1));
  });

  group('restoreWithRollback', () {
    late File zip;
    setUp(() async {
      await seed(restored, sku: 'NEW', name: 'From Backup', shop: 'New Shop');
      zip = await svc.create(
        dbFile: dbFileIn(restored),
        hiveBoxFiles: {'settings': hivePathIn(restored, 'settings')},
        outDir: tmp,
        schemaVersion: schema,
      );
      await seedLive();
    });

    Future<RestoreBackup> swap() => svc.restore(
          zip: zip,
          dbFile: dbFileIn(live),
          hiveBoxFiles: {'settings': hivePathIn(live, 'settings')},
          currentSchemaVersion: schema,
        );

    test('a failed reopen rolls DB and Hive back to the .bak', () async {
      var reopens = 0;
      var releases = 0;
      await expectLater(
        svc.restoreWithRollback(
          swap: swap,
          reopen: () async {
            reopens++;
            if (reopens == 1) throw StateError('migration blew up');
          },
          release: () async => releases++,
        ),
        throwsA(isA<RestoreRolledBackException>()),
      );
      expect(reopens, 2);
      expect(releases, 1);
      expect(await productName(live, 'SNAP'), 'Snapshot Widget');
      expect(await productName(live, 'NEW'), isNull);
      expect(await shopName(live), 'Test Shop');
      expect(File('${dbFileIn(live).path}.bak').existsSync(), isFalse);
    });

    test('a successful reopen keeps the restored data', () async {
      var reopens = 0;
      final m = await svc.restoreWithRollback(
        swap: swap,
        reopen: () async => reopens++,
        release: () async {},
      );
      expect(reopens, 1);
      expect(m.schemaVersion, schema);
      expect(await productName(live, 'NEW'), 'From Backup');
    });

    test('a rejected swap reopens the old data and rethrows', () async {
      var reopens = 0;
      await expectLater(
        svc.restoreWithRollback(
          swap: () => svc.restore(
            zip: craftZip(utf8.encode('junk')),
            dbFile: dbFileIn(live),
            hiveBoxFiles: const {},
            currentSchemaVersion: schema,
          ),
          reopen: () async => reopens++,
          release: () async {},
        ),
        throwsA(isA<SnapshotFormatException>()),
      );
      expect(reopens, 1);
      await expectLiveUntouched();
    });

    test('if even the old data cannot reopen, a fatal error is raised',
        () async {
      await expectLater(
        svc.restoreWithRollback(
          swap: swap,
          reopen: () async => throw StateError('disk gone'),
          release: () async {},
        ),
        throwsA(isA<RestoreFatalException>()),
      );
    });
  });

  test('inspect rejects files that are not POS snapshots', () async {
    final notZip = File(p.join(tmp.path, 'x.zip'))..writeAsStringSync('hello');
    expect(() => svc.inspect(notZip), throwsA(isA<SnapshotFormatException>()));
  });

  group('inspect reads only the manifest', () {
    File zipOf(Map<String, List<int>> entries) {
      final archive = Archive();
      entries.forEach((k, v) => archive.addFile(ArchiveFile.bytes(k, v)));
      return File(p.join(tmp.path, 'entries.zip'))
        ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));
    }

    Matcher formatError(Object message) => throwsA(
        isA<SnapshotFormatException>().having((e) => e.message, 'message',
            message));

    test('returns the manifest of a crafted snapshot', () async {
      final m = await svc.inspect(craftZip(rawSqlite(1), schemaVersion: 3));
      expect(m.schemaVersion, 3);
      expect(m.createdAt, DateTime(2026));
      expect(m.hiveBoxes, isEmpty);
    });

    test('works inside Isolate.run (as the app calls it)', () async {
      final path = craftZip(rawSqlite(1), schemaVersion: 5).path;
      final m = await Isolate.run(() => SnapshotService.inspectSync(path));
      expect(m.schemaVersion, 5);
    });

    test('empty / non-zip file → no manifest found', () async {
      // archive 4.x decodes junk without an end-of-central-directory record
      // as an empty archive, so this surfaces as a missing manifest — the
      // same message the old in-memory decode produced.
      final empty = File(p.join(tmp.path, 'empty.zip'))..writeAsBytesSync([]);
      await expectLater(svc.inspect(empty),
          formatError('Not a POS backup (manifest.json missing)'));
      final junk = File(p.join(tmp.path, 'junk.zip'))
        ..writeAsBytesSync(List.filled(5000, 7));
      await expectLater(svc.inspect(junk),
          formatError('Not a POS backup (manifest.json missing)'));
    });

    test('zip without manifest → "manifest.json missing"', () async {
      final zip = zipOf({SnapshotService.dbEntryName: rawSqlite(1)});
      await expectLater(svc.inspect(zip),
          formatError('Not a POS backup (manifest.json missing)'));
    });

    test('unparseable manifest → "Corrupt manifest"', () async {
      final zip = zipOf({
        SnapshotService.dbEntryName: rawSqlite(1),
        SnapshotService.manifestName: utf8.encode('{not json'),
      });
      await expectLater(
          svc.inspect(zip), formatError(startsWith('Corrupt manifest')));
    });

    test('manifest from another app is rejected', () async {
      final zip = zipOf({
        SnapshotService.dbEntryName: rawSqlite(1),
        SnapshotService.manifestName: utf8.encode('{"app":"other"}'),
      });
      await expectLater(
          svc.inspect(zip), formatError('Manifest is not from this app'));
    });

    test('manifest without a DB entry → "no database file"', () async {
      final manifest = craftZip(rawSqlite(1));
      final bytes = ZipDecoder()
          .decodeBytes(manifest.readAsBytesSync())
          .find(SnapshotService.manifestName)!
          .readBytes()!;
      final zip = zipOf({SnapshotService.manifestName: bytes});
      await expectLater(
          svc.inspect(zip), formatError('Snapshot has no database file'));
    });

    test('unsupported formatVersion is rejected', () async {
      final zip = craftZip(rawSqlite(1),
          formatVersion: SnapshotService.formatVersion + 1);
      await expectLater(
          svc.inspect(zip), formatError(startsWith('Unsupported backup format')));
    });
  });

  test('listLocal is newest-first and prune keeps N', () async {
    await seedLive();
    final out = Directory(p.join(tmp.path, 'auto'));
    for (var day = 1; day <= 5; day++) {
      final f = await svc.create(
        dbFile: dbFileIn(live),
        hiveBoxFiles: const {},
        outDir: out,
        schemaVersion: 9,
        now: DateTime(2026, 8, day),
      );
      await f.setLastModified(DateTime(2026, 8, day));
    }
    // A leftover partial write is never listed (or counted).
    File(p.join(out.path, 'pos_backup_20260809_000000.zip.part'))
        .writeAsStringSync('x');

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

  test('prune never deletes the snapshot just made (clock set back)',
      () async {
    await seedLive();
    final out = Directory(p.join(tmp.path, 'auto'));
    for (var day = 10; day <= 12; day++) {
      final f = await svc.create(
        dbFile: dbFileIn(live),
        hiveBoxFiles: const {},
        outDir: out,
        schemaVersion: 9,
        now: DateTime(2026, 8, day),
      );
      await f.setLastModified(DateTime(2026, 8, day));
    }
    // Clock went back: the newest file has the oldest-looking name/mtime.
    final fresh = await svc.create(
      dbFile: dbFileIn(live),
      hiveBoxFiles: const {},
      outDir: out,
      schemaVersion: 9,
      now: DateTime(2026, 1, 1),
    );
    await fresh.setLastModified(DateTime(2026, 1, 1));

    await svc.prune(out, keep: 2, protect: fresh);
    final names =
        (await svc.listLocal(out)).map((f) => p.basename(f.path)).toList();
    expect(names, contains(p.basename(fresh.path)));
    expect(names, hasLength(2));
  });
}
