import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/presentation/backup_screen.dart';
import 'package:pos_app/features/settings/presentation/widgets/backup_section.dart';

import '../../_support/test_db.dart';

class _FakeCoordinator extends SnapshotCoordinator {
  _FakeCoordinator(super.ref, this.log);
  final List<String> log;

  @override
  Future<List<File>> localSnapshots() async {
    log.add('list');
    return const [];
  }

  @override
  Future<File?> runAutoBackupIfDue({DateTime? now}) async {
    log.add('run');
    return null;
  }
}

/// Settings › Data Management › "Automatic backups": the Backup screen's
/// switch, one tap away.
void main() {
  late Directory tmp;
  late Box<dynamic> settingsBox;
  late AppDatabase db;
  late List<String> log;
  late ProviderContainer c;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_auto_row_');
    Hive.init(tmp.path);
    settingsBox = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
    db = openInMemoryDatabase();
    log = [];
    autoBackupLastError.value = null;
    c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      settingsBoxProvider.overrideWithValue(settingsBox),
      snapshotCoordinatorProvider
          .overrideWith((ref) => _FakeCoordinator(ref, log)),
    ]);
  });
  tearDown(() async {
    autoBackupLastError.value = null;
    c.dispose();
    await db.close();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  /// The row on a settings page and the Backup screen on the same route
  /// shape as the app (`/settings/backup?show=device`).
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: BackupSection()),
        routes: [
          GoRoute(
            path: 'settings/backup',
            builder: (_, s) => BackupScreen(
                openDeviceBackups:
                    s.uri.queryParameters['show'] == kShowDeviceBackupsQuery),
          ),
        ],
      ),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  Finder row() => find.byKey(const ValueKey('settings-auto-backups'));
  Switch rowSwitch(WidgetTester tester) => tester.widget<Switch>(
      find.descendant(of: row(), matching: find.byType(Switch)));

  test('the subtitle', () {
    expect(autoBackupRowSubtitle(enabled: false), 'Off');
    expect(autoBackupRowSubtitle(enabled: true), 'Daily · no backup yet');
    final t = DateTime(2026, 11, 2, 9, 5);
    expect(autoBackupRowSubtitle(enabled: true, lastAt: t),
        'Daily · last backup ${autoBackupTimeText(t)} · keeps 7');
    expect(autoBackupRowSubtitle(enabled: false, lastAt: t), 'Off');
  });

  testWidgets('shows Off, Daily with no backup yet, and Daily with a time',
      (tester) async {
    await c.read(settingsProvider.notifier).setAutoBackupEnabled(false);
    await pump(tester);
    expect(find.text('Automatic backups'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    expect(tester.getSize(row()).height, greaterThanOrEqualTo(48));

    await c.read(settingsProvider.notifier).setAutoBackupEnabled(true);
    await tester.pumpAndSettle();
    expect(find.text('Daily · no backup yet'), findsOneWidget);

    final t = DateTime(2026, 11, 2, 9, 5);
    await c.read(settingsProvider.notifier).markAutoBackupRun(t);
    await tester.pumpAndSettle();
    expect(find.text('Daily · last backup ${autoBackupTimeText(t)} · keeps 7'),
        findsOneWidget);
  });

  testWidgets('the row switch is the setting: off, then on runs a backup',
      (tester) async {
    await pump(tester);
    expect(rowSwitch(tester).value, isTrue, reason: 'on by default');
    await tester.tap(find.descendant(of: row(), matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(c.read(autoBackupEnabledProvider), isFalse);
    expect(find.text('Off'), findsOneWidget);
    expect(log, isEmpty, reason: 'the row tap is not the switch');

    await tester.tap(find.descendant(of: row(), matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(c.read(autoBackupEnabledProvider), isTrue);
    expect(log, ['run'], reason: 'switching on backs up, like the tile');
  });

  testWidgets('the row and the Backup screen tile always agree',
      (tester) async {
    await pump(tester);
    // Tap the row: the Backup screen opens on its device backups list.
    await tester.tap(find.text('Automatic backups'));
    await tester.pumpAndSettle();
    expect(log, ['list'], reason: 'the list opened');
    expect(find.text('No automatic backups yet.\nOne is taken on first '
        'launch each day.'), findsOneWidget);
    Navigator.of(tester.element(find.text('No automatic backups yet.\nOne is '
            'taken on first launch each day.')))
        .pop();
    await tester.pumpAndSettle();

    // The tile's switch off …
    final tile = find.ancestor(
        of: find.text('Device backups'), matching: find.byType(Card));
    await tester.tap(find.descendant(of: tile, matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(c.read(autoBackupEnabledProvider), isFalse);
    // … and the row shows it.
    GoRouter.of(tester.element(tile)).pop();
    await tester.pumpAndSettle();
    expect(rowSwitch(tester).value, isFalse);
    expect(find.text('Off'), findsOneWidget);

    // The row's switch on, and the tile shows it.
    await tester.tap(find.descendant(of: row(), matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backup & Restore'));
    await tester.pumpAndSettle();
    final tileSwitch = tester.widget<Switch>(find.descendant(
        of: find.ancestor(
            of: find.text('Device backups'), matching: find.byType(Card)),
        matching: find.byType(Switch)));
    expect(tileSwitch.value, isTrue);
  });

  testWidgets('the last error shows as a second line in the error colour',
      (tester) async {
    await pump(tester);
    expect(find.textContaining('Last auto-backup failed'), findsNothing);
    autoBackupLastError.value = 'disk full';
    await tester.pumpAndSettle();
    final err = find.text('Last auto-backup failed: disk full');
    expect(find.descendant(of: row(), matching: err), findsOneWidget);
    final ctx = tester.element(err);
    expect(tester.widget<Text>(err).style?.color,
        Theme.of(ctx).colorScheme.error);
  });

  testWidgets('semantics: the row and its switch are labelled',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(
        find.bySemanticsLabel(RegExp('Automatic backups. Opens the list')),
        findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Automatic backups switch')),
        findsOneWidget);
    handle.dispose();
  });
}
