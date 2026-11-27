import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/features/backup/presentation/backup_screen.dart';

import '../../_support/test_db.dart';

/// After "Start fresh", the automatic backups made before it are the only
/// copies of the old shop: their pruning pauses until a restore or Dismiss.
void main() {
  late Directory tmp;
  late Directory auto;
  late Box<dynamic> settings;
  final pause = DateTime(2026, 11, 20, 12);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_prune_pause_');
    auto = Directory(p.join(tmp.path, 'backups', 'auto'))
      ..createSync(recursive: true);
    Hive.init(tmp.path);
    settings = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
  });
  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  File backup(String name, DateTime when) => File(p.join(auto.path,
      '${SnapshotService.filePrefix}$name${SnapshotService.fileSuffix}'))
    ..writeAsBytesSync([1])
    ..setLastModifiedSync(when);

  Set<String> names() => {
        for (final f in auto.listSync())
          p
              .basenameWithoutExtension(f.path)
              .substring(SnapshotService.filePrefix.length)
      };

  test('not paused: the newest $kAutoBackupKeep are kept', () async {
    for (var i = 0; i < 10; i++) {
      backup('b$i', DateTime(2026, 11, 1 + i));
    }
    final latest = backup('latest', DateTime(2026, 11, 25));
    expect(await pruneAutoBackups(auto, protect: latest), 4);
    expect(names(), hasLength(kAutoBackupKeep));
    expect(names(), contains('latest'));
  });

  test(
      'paused: older backups are never pruned; the newest '
      '$kAutoBackupKeep newer ones are kept', () async {
    await settings.put(kStartFreshAtKey, pause.toIso8601String());
    expect(autoBackupPrunePausedSince(), pause);
    for (var i = 0; i < 6; i++) {
      backup('old$i', pause.subtract(Duration(days: i + 1)));
    }
    for (var i = 0; i < 9; i++) {
      backup('new$i', pause.add(Duration(days: i + 1)));
    }
    final latest = backup('latest', pause.add(const Duration(days: 20)));
    expect(await pruneAutoBackups(auto, protect: latest), 3);
    final left = names();
    for (var i = 0; i < 6; i++) {
      expect(left, contains('old$i'), reason: 'from before Start fresh');
    }
    expect(left.where((n) => n.startsWith('new')).length + 1, kAutoBackupKeep);
    expect(left, containsAll(['latest', 'new8', 'new7']));
    expect(left, isNot(contains('new0')));
  });

  test('ending the pause lets pruning take the old ones again', () async {
    await settings.put(kStartFreshAtKey, pause.toIso8601String());
    await endAutoBackupPrunePause();
    expect(settings.containsKey(kStartFreshAtKey), isFalse);
    expect(autoBackupPrunePausedSince(), isNull);
  });

  testWidgets(
      'Backup & Restore shows the paused line once; Dismiss ends the pause',
      (tester) async {
    await settings.put(kStartFreshAtKey, pause.toIso8601String());
    final db = openInMemoryDatabase();
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        settingsBoxProvider.overrideWithValue(settings),
      ],
      child: const MaterialApp(home: BackupScreen()),
    ));
    await tester.pump();
    expect(
        find.text('Backups from before Start fresh are kept. Restore one, or '
            'dismiss to let new backups replace them.'),
        findsOneWidget);
    await tester.runAsync(() => tester.tap(find.text('Dismiss')));
    await tester.pump();
    expect(find.text(kPrunePausedNotice), findsNothing);
    expect(settings.containsKey(kStartFreshAtKey), isFalse);
  });

  testWidgets('no pause: no line', (tester) async {
    final db = openInMemoryDatabase();
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        settingsBoxProvider.overrideWithValue(settings),
      ],
      child: const MaterialApp(home: BackupScreen()),
    ));
    await tester.pump();
    expect(find.text(kPrunePausedNotice), findsNothing);
  });
}
