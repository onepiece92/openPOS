import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sql;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/backup/data/restore_journal.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';

/// Restore journal, startup recovery, stale `.bak` handling and staging
/// limits.
void main() {
  const svc = SnapshotService();
  const schema = AppDatabase.currentSchemaVersion;
  const boxes = ['settings', 'held_orders'];
  late Directory tmp;
  late Directory live;
  late Directory source;

  File dbFileIn(Directory d) => File(p.join(d.path, 'pos_database.db'));
  String hivePathIn(Directory d, String box) => p.join(d.path, '$box.hive');
  Map<String, String> hiveIn(Directory d) =>
      {for (final b in boxes) b: hivePathIn(d, b)};
  Directory receiptsIn(Directory d) => Directory(p.join(d.path, 'receipts'));
  File journalIn(Directory d) => SnapshotService.journalFileFor(dbFileIn(d));

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_recovery_');
    live = await Directory(p.join(tmp.path, 'live')).create();
    source = await Directory(p.join(tmp.path, 'source')).create();
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  File photo(Directory dir, String name, String content) =>
      File(p.join(dir.path, name))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(content);

  /// DB with product [sku] (+ one expense per photo) and both boxes
  /// holding [tag], all closed.
  Future<void> seed(Directory dir, String sku, String tag,
      {Map<String, String> photos = const {}}) async {
    final db = AppDatabase(NativeDatabase(dbFileIn(dir)));
    await db.productsDao
        .upsert(ProductsCompanion.insert(sku: sku, name: sku, price: 1));
    final cat = await db.expensesDao
        .insertCategory(ExpenseCategoriesCompanion.insert(name: 'Misc'));
    for (final e in photos.entries) {
      await db.expensesDao.insert(ExpensesCompanion.insert(
        amount: 1,
        date: DateTime(2026),
        categoryId: cat,
        receiptImagePath:
            Value(photo(receiptsIn(dir), e.key, e.value).path),
      ));
    }
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    await db.close();

    Hive.init(dir.path);
    for (final b in boxes) {
      final box = await Hive.openBox<dynamic>(b);
      await box.put('tag', '$b:$tag');
      await box.flush();
    }
    await Hive.close();
  }

  Future<String?> skuIn(Directory dir) async {
    final raw = sql.sqlite3.open(dbFileIn(dir).path);
    try {
      return raw.select('SELECT sku FROM products').first.columnAt(0)
          as String?;
    } finally {
      raw.dispose();
    }
  }

  Future<Map<String, Object?>> tags(Directory dir) async {
    Hive.init(dir.path);
    final out = <String, Object?>{};
    for (final b in boxes) {
      out[b] = (await Hive.openBox<dynamic>(b)).get('tag');
    }
    await Hive.close();
    return out;
  }

  Map<String, String> tree(Directory dir) => !dir.existsSync()
      ? const {}
      : {
          for (final f in dir.listSync(recursive: true).whereType<File>())
            p.relative(f.path, from: dir.path): f.readAsStringSync(),
        };

  List<String> leftovers(Directory dir) => dir
      .listSync()
      .map((e) => p.basename(e.path))
      .where((n) =>
          n.contains('.tmp') ||
          n.contains('.bak') ||
          n.contains('.journal') ||
          n.contains('.part'))
      .toList();

  Future<File> backupOf(Directory dir) => svc.create(
        dbFile: dbFileIn(dir),
        hiveBoxFiles: hiveIn(dir),
        outDir: Directory(p.join(tmp.path, 'out')),
        schemaVersion: schema,
        receiptsDir: receiptsIn(dir),
      );

  Future<RestoreBackup> restoreLive(File zip,
          {Future<void> Function(String)? pause, int? maxStagedBytes}) =>
      svc.restore(
        zip: zip,
        dbFile: dbFileIn(live),
        hiveBoxFiles: hiveIn(live),
        currentSchemaVersion: schema,
        receiptsDir: receiptsIn(live),
        maxStagedBytes:
            maxStagedBytes ?? SnapshotService.defaultMaxStagedBytes,
        debugPause: pause,
      );

  /// Live: SNAP / "live", photo a.jpg. Backup: NEW / "backup", photos
  /// a.jpg (clashes) and x.jpg.
  Future<File> standardSetup() async {
    await seed(source, 'NEW', 'backup',
        photos: {'a.jpg': 'backup A', 'x.jpg': 'backup X'});
    final zip = await backupOf(source);
    await seed(live, 'SNAP', 'live', photos: {'a.jpg': 'live A'});
    return zip;
  }

  Future<void> expectLiveIsOriginal() async {
    expect(await skuIn(live), 'SNAP');
    expect(await tags(live),
        {'settings': 'settings:live', 'held_orders': 'held_orders:live'});
    expect(tree(receiptsIn(live)), {'a.jpg': 'live A'});
    expect(leftovers(live), isEmpty);
  }

  // ── A. startup recovery after a kill ──────────────────────────────────────

  group('startup recovery rolls back a restore killed at', () {
    /// Starts a restore that freezes forever at the [n]th [point], as if
    /// the process had been killed there, and returns once it is frozen.
    Future<void> killAt(File zip, String point, {int n = 1}) async {
      final reached = Completer<void>();
      var seen = 0;
      unawaited(restoreLive(zip, pause: (at) {
        if (at == point && ++seen == n) {
          reached.complete();
          return Completer<void>().future; // never resumes
        }
        return Future.value();
      }).then((_) {}, onError: (Object e) {
        if (!reached.isCompleted) reached.completeError(e);
      }));
      await reached.future;
      expect(journalIn(live).existsSync(), isTrue);
    }

    for (final (point, n) in [
      ('db-aside', 1), // DB moved to .bak, nothing placed yet
      ('db-placed', 1), // new DB in, Hive not yet swapped
      ('hive-aside', 1),
      ('hive-placed', 1), // one box swapped, the other not
      ('hive-placed', 2),
      ('photo-aside', 1), // clashing a.jpg moved into receipts.bak
      ('photo-placed', 1),
      ('photo-aside', 2), // mid-loop: a.jpg replaced, x.jpg pending
      ('photo-placed', 2),
      ('swapped', 1), // swap done, never reopened / committed
    ]) {
      test('$point #$n', () async {
        final zip = await standardSetup();
        await killAt(zip, point, n: n);
        expect(await SnapshotService.recoverInterruptedRestore(journalIn(live)),
            RestoreRecovery.rolledBack);
        await expectLiveIsOriginal();
        expect(Directory('${receiptsIn(live).path}.restore.tmp').existsSync(),
            isFalse);
      });
    }

    test('db-aside, after Drift created an empty DB on the next launch',
        () async {
      final zip = await standardSetup();
      await killAt(zip, 'db-aside');
      expect(dbFileIn(live).existsSync(), isFalse); // the bug's symptom
      dbFileIn(live).writeAsBytesSync(Uint8List(0));
      await SnapshotService.recoverInterruptedRestore(journalIn(live));
      await expectLiveIsOriginal();
    });

    test('recovery is idempotent and tolerates a torn last record',
        () async {
      final zip = await standardSetup();
      await killAt(zip, 'photo-aside', n: 2);
      final journal = journalIn(live);
      final copy = journal.readAsStringSync();
      journal.writeAsStringSync('$copy{"op":"pla'); // killed mid-write
      await SnapshotService.recoverInterruptedRestore(journal);
      await expectLiveIsOriginal();
      // Same journal again (e.g. the first recovery was itself killed).
      journal.writeAsStringSync(copy);
      await SnapshotService.recoverInterruptedRestore(journal);
      await expectLiveIsOriginal();
    });

    test('the next restore recovers a leftover journal first', () async {
      final zip = await standardSetup();
      await killAt(zip, 'hive-placed');
      await restoreLive(zip);
      expect(await skuIn(live), 'NEW');
      expect((await tags(live))['settings'], 'settings:backup');
    });
  });

  test('no journal → recovery is a no-op', () async {
    await seed(live, 'SNAP', 'live');
    expect(await SnapshotService.recoverInterruptedRestore(journalIn(live)),
        RestoreRecovery.none);
    expect(await skuIn(live), 'SNAP');
  });

  test('a committed restore killed during cleanup keeps the new data',
      () async {
    final zip = await standardSetup();
    final backup = await restoreLive(zip);
    RestoreJournal.markCommitted(File(backup.journalPath));
    // …killed here, before the .bak files were deleted.
    expect(File('${dbFileIn(live).path}.bak').existsSync(), isTrue);

    expect(await SnapshotService.recoverInterruptedRestore(journalIn(live)),
        RestoreRecovery.completed);
    expect(await skuIn(live), 'NEW');
    expect(tree(receiptsIn(live)), {'a.jpg': 'backup A', 'x.jpg': 'backup X'});
    expect(leftovers(live), isEmpty);
  });

  // ── B. stale .bak files ───────────────────────────────────────────────────

  group('with stale .bak files from an earlier restore', () {
    late File zip;

    setUp(() async {
      zip = await standardSetup();
      // What an earlier, successful restore used to leave behind.
      await seed(source, 'STALE', 'stale');
      dbFileIn(source).copySync('${dbFileIn(live).path}.bak');
      for (final b in boxes) {
        File(hivePathIn(source, b)).copySync('${hivePathIn(live, b)}.bak');
      }
      photo(Directory('${receiptsIn(live).path}.bak'), 'a.jpg', 'stale A');
    });

    test('a swap failing mid-way restores only what this run moved',
        () async {
      await expectLater(
        restoreLive(zip, pause: (at) async {
          if (at == 'hive-placed') throw StateError('disk full');
        }),
        throwsA(isA<StateError>()),
      );
      await expectLiveIsOriginal();
    });

    test('a failed reopen restores only what this run moved', () async {
      var reopens = 0;
      await expectLater(
        svc.restoreWithRollback(
          swap: () => restoreLive(zip),
          reopen: () async {
            if (reopens++ == 0) throw StateError('migration blew up');
          },
          release: () async {},
        ),
        throwsA(isA<RestoreRolledBackException>()),
      );
      await expectLiveIsOriginal();
    });

    test('a box missing from the backup keeps its live data', () async {
      // Backup without held_orders: its stale .bak must never come back.
      final noHeld = await svc.create(
        dbFile: dbFileIn(source),
        hiveBoxFiles: {'settings': hivePathIn(source, 'settings')},
        outDir: Directory(p.join(tmp.path, 'out2')),
        schemaVersion: schema,
      );
      var reopens = 0;
      await expectLater(
        svc.restoreWithRollback(
          swap: () => restoreLive(noHeld),
          reopen: () async {
            if (reopens++ == 0) throw StateError('boom');
          },
          release: () async {},
        ),
        throwsA(isA<RestoreRolledBackException>()),
      );
      expect((await tags(live))['held_orders'], 'held_orders:live');
      expect(await skuIn(live), 'SNAP');
    });

    test('a successful restore removes every .bak once reopened', () async {
      final m = await svc.restoreWithRollback(
        swap: () => restoreLive(zip),
        reopen: () async {},
        release: () async {},
      );
      expect(m.photos, unorderedEquals(['a.jpg', 'x.jpg']));
      expect(await skuIn(live), 'NEW');
      expect(tree(receiptsIn(live)), {'a.jpg': 'backup A', 'x.jpg': 'backup X'});
      expect(leftovers(live), isEmpty);
    });
  });

  // ── C. staging limits ─────────────────────────────────────────────────────

  group('staging limits', () {
    /// Patches the declared uncompressed size of [entry] in both the local
    /// header and the central directory.
    void shrinkDeclaredSize(File zip, String entry, int newSize) {
      final b = zip.readAsBytesSync();
      final bd = ByteData.sublistView(b);
      final name = utf8.encode(entry);
      bool nameAt(int off) {
        for (var i = 0; i < name.length; i++) {
          if (b[off + i] != name[i]) return false;
        }
        return true;
      }

      var patched = 0;
      for (var i = 0; i + 46 < b.length; i++) {
        final sig = bd.getUint32(i, Endian.little);
        if (sig == 0x04034b50 && nameAt(i + 30)) {
          bd.setUint32(i + 22, newSize, Endian.little);
          patched++;
        } else if (sig == 0x02014b50 && nameAt(i + 46)) {
          bd.setUint32(i + 24, newSize, Endian.little);
          patched++;
        }
      }
      expect(patched, 2);
      zip.writeAsBytesSync(b);
    }

    test('an entry inflating past its declared size is rejected', () async {
      final zip = await standardSetup();
      shrinkDeclaredSize(zip, SnapshotService.dbEntryName, 1000);
      await expectLater(
          restoreLive(zip),
          throwsA(isA<SnapshotFormatException>().having((e) => e.message,
              'message', contains('larger than its declared size'))));
      await expectLiveIsOriginal();
    });

    test('a backup declaring more than the cap is refused up front',
        () async {
      final zip = await standardSetup();
      await expectLater(
          restoreLive(zip, maxStagedBytes: 4096),
          throwsA(isA<SnapshotFormatException>()
              .having((e) => e.message, 'message', contains('too large'))));
      await expectLiveIsOriginal();
    });

    test('default cap is 4 GiB', () {
      expect(SnapshotService.defaultMaxStagedBytes, 4 << 30);
    });

    test('photo names that differ only by case are rejected', () async {
      await seed(source, 'NEW', 'backup');
      await seed(live, 'SNAP', 'live', photos: {'a.jpg': 'live A'});
      final archive = Archive()
        ..addFile(ArchiveFile.bytes(SnapshotService.dbEntryName,
            dbFileIn(source).readAsBytesSync()))
        ..addFile(ArchiveFile.string('receipts/IMG.jpg', '1'))
        ..addFile(ArchiveFile.string('receipts/img.JPG', '2'))
        ..addFile(ArchiveFile.string(
            SnapshotService.manifestName,
            jsonEncode(SnapshotManifest(
              formatVersion: 2,
              schemaVersion: schema,
              createdAt: DateTime(2026),
              dbBytes: 1,
              hiveBoxes: const [],
            ).toJson())));
      final zip = File(p.join(tmp.path, 'case.zip'))
        ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));
      await expectLater(
          restoreLive(zip),
          throwsA(isA<SnapshotFormatException>()
              .having((e) => e.message, 'message', contains('clashing'))));
      await expectLiveIsOriginal();
    });
  });

  // ── Older schemas / create failures ───────────────────────────────────────

  for (final (label, ddl) in [
    ('expenses without receipt_image_path',
        'CREATE TABLE expenses (id INTEGER PRIMARY KEY, amount REAL)'),
    ('no expenses table', 'CREATE TABLE products (id INTEGER PRIMARY KEY)'),
  ]) {
    test('backup + restore of a DB with $label', () async {
      final f = File(p.join(source.path, 'old.db'));
      sql.sqlite3.open(f.path)
        ..execute(ddl)
        ..execute('PRAGMA user_version = 3')
        ..dispose();
      final zip = await svc.create(
        dbFile: f,
        hiveBoxFiles: const {},
        outDir: Directory(p.join(tmp.path, 'out')),
        schemaVersion: 3,
        receiptsDir: receiptsIn(source),
      );
      expect((await svc.inspect(zip)).photos, isEmpty);
      final backup = await restoreLive(zip);
      await svc.commit(backup);
      SnapshotService.verifyDatabaseFile(dbFileIn(live),
          currentSchemaVersion: schema);
      expect(leftovers(live), isEmpty);
    });
  }

  test('a failed create leaves no .part or scratch files', () async {
    await seed(live, 'SNAP', 'live');
    final unreadable = hivePathIn(live, 'held_orders');
    await Process.run('chmod', ['000', unreadable]);
    addTearDown(() => Process.run('chmod', ['644', unreadable]));
    final out = Directory(p.join(tmp.path, 'out'));
    await expectLater(
      svc.create(
        dbFile: dbFileIn(live),
        hiveBoxFiles: hiveIn(live),
        outDir: out,
        schemaVersion: schema,
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(out.listSync(), isEmpty);
  }, skip: Platform.isWindows ? 'needs chmod' : false);
}
