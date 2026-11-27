import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/features/backup/data/temp_files.dart';
import 'package:pos_app/startup.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart'
    show RestoreRecovery;

/// The launch sweep removes the shared exports and the backup working files
/// a kill left in temp, and nothing else.
void main() {
  late Directory temp;
  setUp(() => temp = Directory.systemTemp.createTempSync('pos_temp_sweep_'));
  tearDown(() => temp.deleteSync(recursive: true));

  File put(String rel) => File(p.join(temp.path, rel))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(rel);

  test('the share folder and pos_snapshot_ / settings_snapshot_ files go; '
      'share_plus copies and other files stay', () async {
    final shared = [
      put('$kShareTempFolder/pos_snapshot_1.zip'),
      put('$kShareTempFolder/products_backup.csv'),
      put('$kShareTempFolder/end-of-day.txt'),
    ];
    final working = [
      put('pos_snapshot_123.db'),
      put('settings_snapshot_123.hive'),
      put('settings_snapshot_123.lock'),
    ];
    final kept = [
      put('$kSharePlusTempFolder/copy.zip'),
      put('other.txt'),
      put('nested/pos_snapshot_9.db'),
    ];

    await sweepTempLeftovers(temp);

    for (final f in [...shared, ...working]) {
      expect(f.existsSync(), isFalse, reason: f.path);
    }
    for (final f in kept) {
      expect(f.existsSync(), isTrue, reason: f.path);
    }

    await sweepTempLeftovers(temp, sharePlusCache: true);
    expect(kept.first.existsSync(), isFalse, reason: 'reset only');
  });

  test('a missing temp folder is not an error', () async {
    await sweepTempLeftovers(Directory(p.join(temp.path, 'none')));
  });

  test('shareTempDir is <temp>/openpos_share', () async {
    final d = await shareTempDir(temp: temp);
    expect(d.path, p.join(temp.path, kShareTempFolder));
    expect(d.existsSync(), isTrue);
  });

  test('startUp sweeps temp before the stores open', () async {
    final calls = <String>[];
    await startUp(
      recover: () async => RestoreRecovery.none,
      initHive: () async {},
      sweepTemp: () async => calls.add('sweep'),
      openStores: () async => calls.add('open'),
    );
    expect(calls, ['sweep', 'open']);
  });
}
