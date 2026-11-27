import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/settings/presentation/widgets/backup_section.dart';

void main() {
  testWidgets('the Backup & Restore row says what it does', (tester) async {
    final tmp = Directory.systemTemp.createTempSync('pos_backup_section_');
    Hive.init(tmp.path);
    final settings = (await tester.runAsync(() =>
        Hive.openBox<dynamic>('settings', bytes: Uint8List(0))))!;
    addTearDown(() async {
      await Hive.close();
      tmp.deleteSync(recursive: true);
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [settingsBoxProvider.overrideWithValue(settings)],
      child: const MaterialApp(home: Scaffold(body: BackupSection())),
    ));
    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(
        find.text(
            'Back up everything, restore, or export and import CSV files'),
        findsOneWidget);
    expect(find.textContaining('via CSV'), findsNothing);
    // The Automatic backups row sits right below it.
    expect(
        tester.getTopLeft(find.text('Automatic backups')).dy,
        greaterThan(tester.getTopLeft(find.text('Backup & Restore')).dy));
  });
}
