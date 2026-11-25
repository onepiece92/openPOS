import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sql;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';

/// Format-2 snapshot coverage: streaming create/restore, receipt photos
/// travelling in the zip, path re-pointing, rollback of photos, and old
/// format-1 snapshots.
void main() {
  const svc = SnapshotService();
  const schema = AppDatabase.currentSchemaVersion;
  late Directory tmp;
  late Directory live;
  late Directory restored;

  File dbFileIn(Directory d) => File(p.join(d.path, 'pos_database.db'));
  String hivePathIn(Directory d) => p.join(d.path, 'settings.hive');
  Directory receiptsIn(Directory d) => Directory(p.join(d.path, 'receipts'));

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_photos_');
    live = await Directory(p.join(tmp.path, 'live')).create();
    restored = await Directory(p.join(tmp.path, 'restored')).create();
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  /// Seeds a DB (one product, one expense per receipt path) and a settings
  /// box in [dir], checkpointed and closed.
  Future<void> seed(Directory dir,
      {String sku = 'SNAP',
      String shop = 'Test Shop',
      List<String> receiptPaths = const []}) async {
    final db = AppDatabase(NativeDatabase(dbFileIn(dir)));
    await db.productsDao
        .upsert(ProductsCompanion.insert(sku: sku, name: 'Widget', price: 9));
    final cat = await db.expensesDao
        .insertCategory(ExpenseCategoriesCompanion.insert(name: 'Misc'));
    for (final path in receiptPaths) {
      await db.expensesDao.insert(ExpensesCompanion.insert(
        amount: 1,
        date: DateTime(2026),
        categoryId: cat,
        receiptImagePath: Value(path),
      ));
    }
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    await db.close();

    Hive.init(dir.path);
    final box = await Hive.openBox<dynamic>('settings');
    await box.put('business_name', shop);
    await box.flush();
    await Hive.close();
  }

  Future<List<String?>> receiptPaths(Directory dir) async {
    final db = AppDatabase(NativeDatabase(dbFileIn(dir)));
    try {
      final rows = await db.expensesDao.getAll();
      rows.sort((a, b) => a.id.compareTo(b.id));
      return rows.map((e) => e.receiptImagePath).toList();
    } finally {
      await db.close();
    }
  }

  Future<bool> hasProduct(Directory dir, String sku) async {
    final db = AppDatabase(NativeDatabase(dbFileIn(dir)));
    try {
      return await db.productsDao.getBySku(sku) != null;
    } finally {
      await db.close();
    }
  }

  File photo(Directory dir, String name, String content) =>
      File(p.join(dir.path, name))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(content);

  Future<File> backupOf(Directory dir) => svc.create(
        dbFile: dbFileIn(dir),
        hiveBoxFiles: {'settings': hivePathIn(dir)},
        outDir: Directory(p.join(tmp.path, 'out')),
        schemaVersion: schema,
        receiptsDir: receiptsIn(dir),
      );

  Future<RestoreBackup> restoreInto(Directory dir, File zip) => svc.restore(
        zip: zip,
        dbFile: dbFileIn(dir),
        hiveBoxFiles: {'settings': hivePathIn(dir)},
        currentSchemaVersion: schema,
        receiptsDir: receiptsIn(dir),
      );

  /// Every file under [dir] as `relative path → content`.
  Map<String, String> tree(Directory dir) => {
        for (final f in dir.listSync(recursive: true).whereType<File>())
          p.relative(f.path, from: dir.path): f.readAsStringSync(),
      };

  Archive entriesOf(File zip) => ZipDecoder().decodeBytes(zip.readAsBytesSync());

  test('photos round-trip and their paths are re-pointed to this device',
      () async {
    final src = receiptsIn(restored);
    final a = photo(src, 'a.jpg', 'photo A');
    photo(src, 'b.jpg', 'photo B');
    // b's stored path is from another iOS container; found by file name.
    await seed(restored, sku: 'NEW', receiptPaths: [
      a.path,
      '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/receipts/b.jpg',
      a.path, // two expenses may share a photo
    ]);
    final zip = await backupOf(restored);

    final m = await svc.inspect(zip);
    expect(m.formatVersion, 2);
    expect(m.photos, unorderedEquals(['a.jpg', 'b.jpg']));
    final names = entriesOf(zip).map((e) => e.name).toList();
    expect(names, containsAll(['receipts/a.jpg', 'receipts/b.jpg']));

    await seed(live, receiptPaths: const []);
    final backup = await restoreInto(live, zip);

    final dest = receiptsIn(live).path;
    expect(await receiptPaths(live), [
      p.join(dest, 'a.jpg'),
      p.join(dest, 'b.jpg'),
      p.join(dest, 'a.jpg'),
    ]);
    expect(tree(receiptsIn(live)), {'a.jpg': 'photo A', 'b.jpg': 'photo B'});
    expect(await hasProduct(live, 'NEW'), isTrue);
    expect(Directory('$dest.restore.tmp').existsSync(), isFalse);
    // After the app accepts the restore, no backup or journal is left.
    await svc.commit(backup);
    expect(Directory('$dest.bak').existsSync(), isFalse);
    expect(
        live.listSync().map((e) => p.basename(e.path)).where(
            (n) => n.contains('.bak') || n.contains('.journal')),
        isEmpty);
  });

  test('a referenced photo that no longer exists is skipped', () async {
    final a = photo(receiptsIn(live), 'a.jpg', 'photo A');
    await seed(live, receiptPaths: [
      a.path,
      p.join(receiptsIn(live).path, 'gone.jpg'),
      '/nowhere/also-gone.jpg',
    ]);
    final zip = await backupOf(live);

    expect((await svc.inspect(zip)).photos, ['a.jpg']);
    expect(entriesOf(zip).map((e) => e.name),
        isNot(contains('receipts/gone.jpg')));

    await restoreInto(restored, zip);
    final dest = receiptsIn(restored).path;
    // Rows keep pointing at the (missing) file on this device; the UI
    // already treats a missing file as "no photo".
    expect(await receiptPaths(restored), [
      p.join(dest, 'a.jpg'),
      p.join(dest, 'gone.jpg'),
      p.join(dest, 'also-gone.jpg'),
    ]);
    expect(tree(receiptsIn(restored)), {'a.jpg': 'photo A'});
  });

  test('a format-1 snapshot (no photos) restores and is re-pointed',
      () async {
    // Old device: DB rows point at an absolute path that doesn't exist here.
    await seed(restored,
        sku: 'OLD', receiptPaths: ['/old/device/Documents/receipts/k.jpg']);
    final manifest = {
      'app': 'pos_app',
      'formatVersion': 1,
      'schemaVersion': schema,
      'createdAt': DateTime(2025).toIso8601String(),
      'dbBytes': dbFileIn(restored).lengthSync(),
      'hiveBoxes': ['settings'],
      // no 'photos' key, exactly as format 1 wrote it
    };
    final archive = Archive()
      ..addFile(ArchiveFile.bytes(
          SnapshotService.dbEntryName, dbFileIn(restored).readAsBytesSync()))
      ..addFile(ArchiveFile.bytes(
          'hive/settings.hive', File(hivePathIn(restored)).readAsBytesSync()))
      ..addFile(ArchiveFile.string(
          SnapshotService.manifestName, jsonEncode(manifest)));
    final zip = File(p.join(tmp.path, 'v1.zip'))
      ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));

    // The photo already sits in this device's receipts folder.
    photo(receiptsIn(live), 'k.jpg', 'kept');
    photo(receiptsIn(live), 'other.jpg', 'unrelated');
    await seed(live);

    final m = await svc.inspect(zip);
    expect(m.formatVersion, 1);
    expect(m.photos, isEmpty);

    final backup = await restoreInto(live, zip);
    expect(backup.manifest.formatVersion, 1);
    expect(await hasProduct(live, 'OLD'), isTrue);
    expect(await receiptPaths(live), [p.join(receiptsIn(live).path, 'k.jpg')]);
    // A photo-less backup never touches the receipts folder.
    expect(tree(receiptsIn(live)), {'k.jpg': 'kept', 'other.jpg': 'unrelated'});
  });

  group('rejection leaves live data and photos untouched', () {
    late Map<String, String> photosBefore;

    setUp(() async {
      photo(receiptsIn(live), 'a.jpg', 'live A');
      await seed(live,
          receiptPaths: [p.join(receiptsIn(live).path, 'a.jpg')]);
      photosBefore = tree(receiptsIn(live));
    });

    Future<void> expectUntouched() async {
      expect(await hasProduct(live, 'SNAP'), isTrue);
      expect(tree(receiptsIn(live)), photosBefore);
      final leftovers = live
          .listSync()
          .map((e) => p.basename(e.path))
          .where((n) => n.contains('.tmp') || n.contains('.bak'));
      expect(leftovers, isEmpty);
    }

    /// A backup (from `restored`) holding photos a.jpg (clashes) + x.jpg.
    Future<File> photoBackup() async {
      final src = receiptsIn(restored);
      await seed(restored, sku: 'NEW', receiptPaths: [
        photo(src, 'a.jpg', 'backup A').path,
        photo(src, 'x.jpg', 'backup X').path,
      ]);
      return backupOf(restored);
    }

    test('a corrupted photo entry fails its CRC check', () async {
      final zip = await photoBackup();
      final bytes = zip.readAsBytesSync();
      final at = _indexOf(bytes, utf8.encode('backup X'));
      expect(at, greaterThan(0));
      bytes[at] ^= 0xff; // stored entry: flips one byte of the photo
      zip.writeAsBytesSync(bytes);

      await expectLater(
          restoreInto(live, zip),
          throwsA(isA<SnapshotFormatException>().having(
              (e) => e.message, 'message', contains('checksum'))));
      await expectUntouched();
    });

    test('a corrupted database entry is rejected', () async {
      final zip = await photoBackup();
      final bytes = zip.readAsBytesSync();
      // The DB is the first entry: local header (30) + name, then data.
      const dataStart = 30 + SnapshotService.dbEntryName.length;
      for (var i = dataStart + 50; i < dataStart + 90; i++) {
        bytes[i] ^= 0x5a;
      }
      zip.writeAsBytesSync(bytes);

      await expectLater(
          restoreInto(live, zip), throwsA(isA<SnapshotFormatException>()));
      await expectUntouched();
    });

    test('a non-SQLite database next to photos stages nothing', () async {
      final archive = Archive()
        ..addFile(ArchiveFile.string(SnapshotService.dbEntryName, 'junk'))
        ..addFile(ArchiveFile.string('receipts/x.jpg', 'X'))
        ..addFile(ArchiveFile.string(
            SnapshotService.manifestName,
            jsonEncode(SnapshotManifest(
              formatVersion: 2,
              schemaVersion: schema,
              createdAt: DateTime(2026),
              dbBytes: 4,
              hiveBoxes: const [],
              photos: const ['x.jpg'],
            ).toJson())));
      final zip = File(p.join(tmp.path, 'bad.zip'))
        ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));
      await expectLater(
          restoreInto(live, zip), throwsA(isA<SnapshotFormatException>()));
      await expectUntouched();
    });

    test('a photo name escaping the receipts folder is rejected', () async {
      await seed(restored);
      final archive = Archive()
        ..addFile(ArchiveFile.bytes(SnapshotService.dbEntryName,
            dbFileIn(restored).readAsBytesSync()))
        ..addFile(ArchiveFile.string('receipts/../../evil.jpg', 'X'))
        ..addFile(ArchiveFile.string(
            SnapshotService.manifestName,
            jsonEncode(SnapshotManifest(
              formatVersion: 2,
              schemaVersion: schema,
              createdAt: DateTime(2026),
              dbBytes: 1,
              hiveBoxes: const [],
            ).toJson())));
      final zip = File(p.join(tmp.path, 'evil.zip'))
        ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));
      await expectLater(
          restoreInto(live, zip), throwsA(isA<SnapshotFormatException>()));
      await expectUntouched();
      expect(File(p.join(tmp.path, 'evil.jpg')).existsSync(), isFalse);
    });

    test('a failed reopen rolls photos back with the database', () async {
      final zip = await photoBackup();
      var reopens = 0;
      await expectLater(
        svc.restoreWithRollback(
          swap: () => restoreInto(live, zip),
          reopen: () async {
            // On the first reopen the backup's photos are in place.
            if (reopens++ == 0) {
              expect(tree(receiptsIn(live)),
                  {'a.jpg': 'backup A', 'x.jpg': 'backup X'});
              throw StateError('migration blew up');
            }
          },
          release: () async {},
        ),
        throwsA(isA<RestoreRolledBackException>()),
      );
      expect(await hasProduct(live, 'NEW'), isFalse);
      // x.jpg removed, the overwritten a.jpg put back, no .bak dir left.
      await expectUntouched();
    });

    test('a swap that fails mid-photos rolls everything back', () async {
      final zip = await photoBackup();
      // A directory where x.jpg should land makes that rename fail after
      // the DB, the box and a.jpg have already been swapped in.
      Directory(p.join(receiptsIn(live).path, 'x.jpg'))
          .createSync(recursive: true);
      photosBefore = tree(receiptsIn(live));

      await expectLater(restoreInto(live, zip), throwsA(anything));
      expect(await hasProduct(live, 'NEW'), isFalse);
      expect(Directory(p.join(receiptsIn(live).path, 'x.jpg')).existsSync(),
          isTrue);
      await expectUntouched();
    });
  });

  test('inspect reads the manifest only — a corrupt DB entry is not read',
      () async {
    final a = photo(receiptsIn(live), 'a.jpg', 'A');
    await seed(live, receiptPaths: [a.path]);
    final zip = await backupOf(live);
    final bytes = zip.readAsBytesSync();
    const dataStart = 30 + SnapshotService.dbEntryName.length;
    for (var i = dataStart; i < dataStart + 200; i++) {
      bytes[i] = 0;
    }
    zip.writeAsBytesSync(bytes);

    final m = await svc.inspect(zip);
    expect(m.photos, ['a.jpg']);
    expect(m.schemaVersion, schema);
  });

  group('streaming', () {
    test('multi-MB database round-trips intact', () async {
      await seed(live);
      // ~6 MB of incompressible rows, well above [SnapshotService.chunkSize].
      final rnd = Random(42);
      final raw = sql.sqlite3.open(dbFileIn(live).path);
      raw.execute('CREATE TABLE ballast (i INTEGER, b BLOB)');
      final ins = raw.prepare('INSERT INTO ballast VALUES (?, ?)');
      raw.execute('BEGIN');
      for (var i = 0; i < 1500; i++) {
        ins.execute([
          i,
          Uint8List.fromList(List.generate(4096, (_) => rnd.nextInt(256))),
        ]);
      }
      raw.execute('COMMIT');
      ins.dispose();
      raw.execute('PRAGMA wal_checkpoint(TRUNCATE)');
      raw.dispose();
      final expected = dbFileIn(live).readAsBytesSync(); // test-side only
      final dbLen = dbFileIn(live).lengthSync();
      expect(dbLen, greaterThan(6 * 1024 * 1024));

      final zip = await backupOf(live);
      final dbEntry = entriesOf(zip).find(SnapshotService.dbEntryName)!;
      expect(dbEntry.size, dbLen);
      // Scratch files are cleaned up; only the zip remains.
      expect(Directory(p.join(tmp.path, 'out')).listSync(), hasLength(1));

      await restoreInto(restored, zip);
      // No photos → the restored DB is byte-identical (no re-point writes).
      expect(dbFileIn(restored).readAsBytesSync(), expected);
      expect(await hasProduct(restored, 'SNAP'), isTrue);
    });

    test('compressible DB is stored deflated', () async {
      await seed(live);
      final zip = await backupOf(live);
      final entry = entriesOf(zip).find(SnapshotService.dbEntryName)!;
      final zf = entry.rawContent! as ZipFile;
      expect(zf.compressionMethod, CompressionType.deflate);
      expect(zf.compressedSize, lessThan(zf.uncompressedSize));
    });

    test('service never loads whole files or archives into memory', () {
      // Code-path guard: these archive / dart:io calls materialise an
      // entire file, entry or zip. Only the tiny manifest may be read whole
      // (`entry.readBytes()` in `_manifestOf`).
      final src = File('lib/features/backup/data/snapshot_service.dart')
          .readAsStringSync()
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      for (final banned in [
        'readAsBytes',
        'writeAsBytes',
        'encodeBytes',
        'decodeBytes',
        'getContent(',
        'writeContent(',
        'toUint8List()',
      ]) {
        final hits = banned == 'toUint8List()'
            // allowed only on a bounded chunk read
            ? RegExp(r'toUint8List\(\)').allMatches(src).length -
                RegExp(r'readBytes\(min\(chunkSize').allMatches(src).length
            : banned.allMatches(src).length;
        expect(hits, 0, reason: '`$banned` loads a whole file into memory');
      }
      expect(RegExp(r'\.readBytes\(\)').allMatches(src), hasLength(1));
      expect(SnapshotService.chunkSize, lessThanOrEqualTo(1024 * 1024));
    });
  });
}

int _indexOf(List<int> haystack, List<int> needle) {
  outer:
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}
