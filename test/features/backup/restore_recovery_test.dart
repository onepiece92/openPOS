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
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/startup.dart';

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

  Future<RestoreRecovery> recoverLive() =>
      SnapshotService.recoverInterruptedRestore(
        dbFile: dbFileIn(live),
        hivePaths: hiveIn(live).values.toList(),
        receiptsDir: receiptsIn(live),
      );

  /// Starts a restore that freezes forever at the [n]th [point], as if the
  /// process had been killed (or the power cut) there, and returns once it
  /// is frozen.
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
    // The journal holds only the fsynced plan, so each of these is also
    // the power-cut case: moves done, nothing about them logged.
    for (final (point, n) in [
      ('begun', 1), // plan logged, nothing moved yet ("logged, not done")
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
        expect(await recoverLive(),
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
      await recoverLive();
      await expectLiveIsOriginal();
    });

    test('power cut after the whole swap: only the plan is on disk',
        () async {
      final zip = await standardSetup();
      await killAt(zip, 'swapped');
      // Everything moved, yet the journal says nothing beyond `begin`.
      expect(journalIn(live).readAsLinesSync(), hasLength(1));
      expect(await skuIn(live), 'NEW');
      expect(await recoverLive(), RestoreRecovery.rolledBack);
      await expectLiveIsOriginal();
    });

    test('a torn commit record reads as not committed', () async {
      final zip = await standardSetup();
      await killAt(zip, 'swapped');
      journalIn(live).writeAsStringSync('{"op":"comm', mode: FileMode.append);
      expect(await recoverLive(), RestoreRecovery.rolledBack);
      await expectLiveIsOriginal();
    });

    test('a kill during rollback, then recovery again', () async {
      final zip = await standardSetup();
      await killAt(zip, 'photo-aside', n: 2);
      final copy = journalIn(live).readAsStringSync();
      // First recovery gets as far as putting the DB back, then dies
      // (the journal is still there, the rest untouched).
      final db = dbFileIn(live).path;
      File(db).deleteSync();
      File('$db.bak').renameSync(db);
      expect(journalIn(live).readAsStringSync(), copy);
      expect(await recoverLive(), RestoreRecovery.rolledBack);
      await expectLiveIsOriginal();
      // And once more with the same journal: still a no-op on good data.
      journalIn(live).writeAsStringSync(copy);
      await recoverLive();
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
    expect(await recoverLive(),
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

    expect(await recoverLive(),
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

  // ── Unreadable journals ───────────────────────────────────────────────────

  group('an unreadable journal falls back to state-based recovery', () {
    File corrupt() => File('${journalIn(live).path}.corrupt');

    for (final (label, write) in <(String, void Function(File, String))>[
      ('bad UTF-8', (f, _) => f.writeAsBytesSync([0xff, 0xfe, 0x7b, 0x80])),
      ('a corrupt middle line',
          (f, good) => f.writeAsStringSync('garbage\n$good{"op":"commit"}\n')),
      ('a wrong-shape begin',
          (f, _) => f.writeAsStringSync('{"op":"begin","v":1,"plan":"x"}\n')),
      ('version 2',
          (f, good) => f.writeAsStringSync(good.replaceFirst('"v":1', '"v":2'))),
      ('an empty file', (f, _) => f.writeAsStringSync('')),
    ]) {
      test(label, () async {
        final zip = await standardSetup();
        await killAt(zip, 'db-aside');
        write(journalIn(live), journalIn(live).readAsStringSync());

        expect(await recoverLive(), RestoreRecovery.recoveredWithoutJournal);
        expect(await skuIn(live), 'SNAP'); // the missing DB came back
        expect(journalIn(live).existsSync(), isFalse);
        expect(corrupt().existsSync(), isTrue);
        corrupt().deleteSync();
        await expectLiveIsOriginal();

        // …and restore is not wedged afterwards.
        await svc.commit(await restoreLive(zip));
        expect(await skuIn(live), 'NEW');
      });
    }

    test('never discards data where both copies exist', () async {
      final zip = await standardSetup();
      await killAt(zip, 'photo-aside', n: 2);
      journalIn(live).writeAsStringSync('}{');
      expect(await recoverLive(), RestoreRecovery.recoveredWithoutJournal);
      // DB and boxes: live (restored) and .bak (original) both kept.
      expect(await skuIn(live), 'NEW');
      expect(File('${dbFileIn(live).path}.bak').existsSync(), isTrue);
      // Photos: receipts.bak only ever holds replaced originals → back.
      expect(tree(receiptsIn(live))['a.jpg'], 'live A');
      expect(Directory('${receiptsIn(live).path}.bak').existsSync(), isFalse);
      expect(Directory('${receiptsIn(live).path}.restore.tmp').existsSync(),
          isFalse);
    });
  });

  // ── Guards ────────────────────────────────────────────────────────────────

  test('foreign DB sidecars are removed when the DB is put back', () async {
    final zip = await standardSetup();
    await killAt(zip, 'db-placed');
    final db = dbFileIn(live).path;
    File('$db-wal').writeAsStringSync('junk'); // as if the new DB opened
    File('$db-shm').writeAsStringSync('junk');
    await recoverLive();
    for (final s in ['-wal', '-shm']) {
      final f = File('$db$s');
      // Gone, or the original's own sidecar put back from `.bak$s`.
      if (f.existsSync()) {
        expect(f.readAsBytesSync(), isNot(utf8.encode('junk')));
      }
    }
    await expectLiveIsOriginal();
  });

  test('a .bak whose live DB is missing is never deleted', () async {
    final zip = await standardSetup();
    final db = dbFileIn(live);
    db.renameSync('${db.path}.bak'); // the only copy of the shop's data
    final rescued = File('${db.path}.bak').readAsBytesSync();

    // A restore that fails…
    await expectLater(
      restoreLive(zip, pause: (at) async {
        if (at == 'db-placed') throw StateError('boom');
      }),
      throwsA(isA<StateError>()),
    );
    expect(File('${db.path}.bak').readAsBytesSync(), rescued);
    expect(db.existsSync(), isFalse);

    // …and one that succeeds both keep it.
    await svc.commit(await restoreLive(zip));
    expect(await skuIn(live), 'NEW');
    expect(File('${db.path}.bak').readAsBytesSync(), rescued);
  });

  test('startup removes staged leftovers when there is no journal',
      () async {
    await seed(live, 'SNAP', 'live');
    File('${dbFileIn(live).path}.restore.tmp').writeAsStringSync('x');
    File('${hivePathIn(live, 'settings')}.restore.tmp').writeAsStringSync('x');
    photo(Directory('${receiptsIn(live).path}.restore.tmp'), 'p.jpg', 'x');
    expect(await recoverLive(), RestoreRecovery.none);
    expect(leftovers(live), isEmpty);
    expect(await skuIn(live), 'SNAP');
  });

  test('a rollback that itself fails keeps the journal for a retry',
      () async {
    final zip = await standardSetup();
    final receipts = receiptsIn(live).path;
    addTearDown(() => Process.run('chmod', ['755', receipts]));
    var reopens = 0;
    await expectLater(
      svc.restoreWithRollback(
        swap: () => restoreLive(zip),
        reopen: () async {
          if (reopens++ > 0) return;
          // x.jpg can no longer be removed → the rollback throws.
          await Process.run('chmod', ['555', receipts]);
          throw StateError('migration blew up');
        },
        release: () async {},
      ),
      throwsA(isA<RestoreFatalException>()),
    );
    expect(journalIn(live).existsSync(), isTrue);
    // Startup recovery fails the same way → the app must not open.
    expect(await recoverInterruptedRestoreAtStartup(docsDir: live), isNull);

    await Process.run('chmod', ['755', receipts]);
    expect(await recoverInterruptedRestoreAtStartup(docsDir: live),
        RestoreRecovery.rolledBack);
    await expectLiveIsOriginal();
  }, skip: Platform.isWindows ? 'needs chmod' : false);

  // ── create() refuses what restore would reject ────────────────────────────

  test('create refuses photo names that clash by case', () async {
    await seed(live, 'SNAP', 'live');
    final raw = sql.sqlite3.open(dbFileIn(live).path);
    for (final (i, path) in [
      p.join(tmp.path, 'one', 'IMG.jpg'),
      p.join(tmp.path, 'two', 'img.JPG'),
    ].indexed) {
      photo(Directory(p.dirname(path)), p.basename(path), '$i');
      raw.execute(
          'INSERT INTO expenses (amount, date, category_id, '
          'receipt_image_path) VALUES (1, 0, 1, ?)',
          [path]);
    }
    raw.dispose();
    await expectLater(
      backupOf(live),
      throwsA(isA<StateError>()
          .having((e) => e.message, 'message', contains('letter case'))),
    );
  });

  test('create refuses data over the cap, in readable units', () async {
    await seed(live, 'SNAP', 'live');
    await expectLater(
      svc.create(
        dbFile: dbFileIn(live),
        hiveBoxFiles: hiveIn(live),
        outDir: Directory(p.join(tmp.path, 'out')),
        schemaVersion: schema,
        maxBackupBytes: 2048,
      ),
      throwsA(isA<StateError>().having(
          (e) => e.message, 'message', contains('the limit is 2.0 KB'))),
    );
    expect(SnapshotService.formatBytes(SnapshotService.defaultMaxStagedBytes),
        '4.0 GB');
  });

  // ── Startup ordering ──────────────────────────────────────────────────────

  group('startUp', () {
    test('recovers the original bug before Hive or the DB is touched',
        () async {
      final zip = await standardSetup();
      await killAt(zip, 'db-aside'); // live DB gone, data in .bak
      final order = <String>[];
      final r = await startUp(
        recover: () async {
          order.add('recover');
          return recoverInterruptedRestoreAtStartup(docsDir: live);
        },
        initHive: () async {
          order.add('initHive');
          expect(dbFileIn(live).existsSync(), isTrue);
          Hive.init(live.path);
        },
        openStores: () async => order.add('openStores'),
      );
      expect(order, ['recover', 'initHive', 'openStores']);
      expect(r.fatal, isNull);
      expect(r.notice, contains('put back'));
      await expectLiveIsOriginal();
    });

    test('a failed recovery opens nothing and reports a fatal error',
        () async {
      final order = <String>[];
      final r = await startUp(
        recover: () async {
          order.add('recover');
          return null;
        },
        initHive: () async => order.add('initHive'),
        openStores: () async => order.add('openStores'),
      );
      expect(order, ['recover', 'initHive']);
      expect(r.fatal, kRecoveryFailedMessage);
    });

    test('a clean launch has no notice', () async {
      final r = await startUp(
        recover: () async => RestoreRecovery.none,
        initHive: () async {},
        openStores: () async {},
      );
      expect((r.notice, r.fatal), (null, null));
    });
  });
}
