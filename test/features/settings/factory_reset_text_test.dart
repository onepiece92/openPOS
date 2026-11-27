import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/connection/native.dart'
    show kDatabaseFileName;
import 'package:pos_app/features/backup/data/open_failure_recovery.dart'
    show kBrokenCopyInfix;
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/cart/data/ticket_sequence.dart'
    show kTicketSeqKey;
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/backup/data/snapshot_service.dart';
import 'package:pos_app/features/settings/data/factory_reset.dart';
import 'package:pos_app/features/settings/presentation/widgets/danger_section.dart';

import '../../_support/sales.dart';
import '../../app_root_retry_test.dart' show pumpUntil;

/// What each thing the factory reset erases is called in the confirm text.
/// Every table `eraseAllData` deletes from, every Hive box and the receipts
/// folder must be a key here, and its words must be in [kFactoryResetBody].
const kErasedToWords = {
  // Drift tables (AppDatabase.eraseAllData).
  'orders': 'sales',
  'order_items': 'sales',
  'order_taxes': 'sales',
  'order_tax_overrides': 'sales',
  'returns': 'refunds',
  'shifts': 'day closes',
  'products': 'products',
  'product_components': 'products',
  'product_taxes': 'products',
  'categories': 'categories',
  'customers': 'customers',
  'expenses': 'expenses',
  'expense_categories': 'expense categories',
  'tax_rates': 'tax rates',
  'tax_groups': 'tax rates',
  'tax_group_members': 'tax rates',
  'stock_adjustments': 'stock history',
  'tables': 'tables',
  'audit_log': 'activity log',
  // Hive boxes (eraseLocalStores).
  'hive:settings': 'your settings',
  'hive:held_orders': 'held tickets',
  'hive:usage': 'usage counts',
  // Folders.
  'dir:receipts': 'receipt photos',
  // Files: copies of a damaged database that "Start fresh" set aside hold
  // the shop's old sales.
  'file:$kDatabaseFileName$kBrokenCopyInfix*': 'sales',
};

class _DeleteRecorder extends QueryInterceptor {
  final deleted = <String>[];
  bool recording = false;

  @override
  Future<int> runDelete(
      QueryExecutor executor, String statement, List<Object?> args) {
    if (recording) {
      final m = RegExp(r'DELETE FROM "?(\w+)"?').firstMatch(statement);
      if (m != null) deleted.add(m.group(1)!);
    }
    return super.runDelete(executor, statement, args);
  }
}

void main() {
  group('the confirm text names everything the reset erases', () {
    test('every table eraseAllData deletes from is mapped and named', () async {
      final rec = _DeleteRecorder();
      final db = AppDatabase(NativeDatabase.memory().interceptWith(rec));
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get(); // open first
      rec.recording = true;
      await db.eraseAllData();
      rec.recording = false;

      final erased = rec.deleted.toSet();
      expect(erased, isNotEmpty);
      for (final t in erased) {
        expect(kErasedToWords.containsKey(t), isTrue,
            reason: 'eraseAllData deletes "$t": add it to kErasedToWords and '
                'name it in kFactoryResetBody');
      }
      // And nothing in the database is left out of the reset.
      expect(erased, {for (final t in db.allTables) t.actualTableName});
    });

    test('every Hive box and the receipts folder are mapped', () {
      for (final box in kSnapshotHiveBoxes) {
        expect(kErasedToWords.containsKey('hive:$box'), isTrue,
            reason: 'Hive box "$box"');
      }
      expect(kErasedToWords.containsKey('dir:$kReceiptsDirName'), isTrue);
    });

    // The app's source, so a box or folder added anywhere — not only to
    // the lists above — fails here until the confirm text names it.
    final sources = {
      for (final f in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')))
        f.path: f.readAsStringSync(),
    };
    Set<String> found(List<String> patterns) => {
          for (final src in sources.values)
            for (final pat in patterns)
              for (final m in RegExp(pat).allMatches(src)) m.group(1)!,
        };

    test('every Hive box the app opens, by any name, is mapped', () {
      final boxes = {
        ...kSnapshotHiveBoxes,
        ...kStartupHiveBoxes,
        ...found([
          r"Hive\.(?:openBox|box|isBoxOpen|openLazyBox)(?:<[^>]*>)?\(\s*'(\w+)'",
          r"const k\w*Box(?:Name)?\s*=\s*'(\w+)'",
        ]),
      };
      expect(boxes, containsAll(['settings', 'held_orders', 'usage']));
      for (final b in boxes) {
        expect(kErasedToWords.containsKey('hive:$b'), isTrue,
            reason: 'the app opens Hive box "$b": erase it in the reset, '
                'add it to kErasedToWords and name it in kFactoryResetBody');
      }
    });

    test('every data folder in the documents folder is mapped or kept', () {
      // Kept on purpose: the automatic backups are how a reset is undone.
      const kept = {'backups'};
      final dirs = found([
        // A folder: the name ends the string or another '/' follows
        // (not a file such as end-of-day.txt).
        r"(?:docs|dir)\.path\}/(\w+)(?=['/])",
        r"p\.join\(\s*(?:docs|dir)\.path,\s*'(\w+)'",
        r"const k\w*DirName\s*=\s*'(\w+)'",
      ]);
      expect(dirs, containsAll(['receipts', 'backups']));
      for (final d in dirs) {
        expect(kErasedToWords.containsKey('dir:$d') || kept.contains(d), isTrue,
            reason: 'folder "$d": erase it in the reset and name it in '
                'kFactoryResetBody, or keep it on purpose');
      }
      // A new place that writes into the documents folder must be looked
      // at too (it may hold data the reset should erase).
      final docUsers = {
        for (final e in sources.entries)
          if (e.value.contains('getApplicationDocumentsDirectory'))
            e.key.replaceAll(r'\', '/'),
      };
      expect(
          docUsers,
          {
            'lib/core/database/connection/native.dart',
            'lib/features/backup/data/snapshot_providers.dart',
            'lib/features/expenses/presentation/expenses_screen.dart',
          },
          reason: 'a new user of the documents folder: if it stores data, '
              'erase it in the reset and map it in kErasedToWords');
    });

    test('the reset deletes every set-aside damaged database copy', () async {
      final dir = Directory.systemTemp.createTempSync('pos_broken_reset_');
      addTearDown(() async {
        await Hive.close();
        dir.deleteSync(recursive: true);
      });
      Hive.init(dir.path);
      final db = File(p.join(dir.path, kDatabaseFileName))
        ..writeAsStringSync('new');
      for (final s in ['', '-wal', '-shm']) {
        File('${db.path}${kBrokenCopyInfix}20261101-090000$s')
            .writeAsStringSync('old');
      }
      final auto = Directory(p.join(dir.path, 'backups', 'auto'))
        ..createSync(recursive: true);
      await eraseLocalStores(
        settings: await Hive.openBox<dynamic>('settings'),
        heldOrders: await Hive.openBox<dynamic>('held_orders'),
        usage: await Hive.openBox<dynamic>('usage'),
        receipts: Directory(p.join(dir.path, 'receipts')),
        database: db,
      );
      expect(
          dir
              .listSync()
              .where((e) => p.basename(e.path).contains(kBrokenCopyInfix)),
          isEmpty,
          reason: kErasedToWords.keys.firstWhere((k) => k.startsWith('file:')));
      expect(db.existsSync(), isTrue, reason: 'not the live database');
      expect(auto.existsSync(), isTrue, reason: 'automatic backups are kept');
    });

    test('each mapped phrase appears in the body', () {
      for (final e in kErasedToWords.entries) {
        expect(kFactoryResetBody, contains(e.value),
            reason: '${e.key} is called "${e.value}"');
      }
    });

    test('exact wording', () {
      expect(kFactoryResetTitle, 'Erase everything?');
      expect(
          kFactoryResetBody,
          'This permanently deletes everything in Open POS on this device: '
          'sales, refunds and day closes, products and categories, '
          'customers, expenses and expense categories, tax rates, stock '
          'history, held tickets, tables, receipt photos, usage counts, the '
          'activity log and your settings.');
      expect(
          kFactoryResetBackupsKept,
          "Automatic backups already saved on this device are kept; they "
          "don't include receipt photos. You can restore one from "
          'Settings › Backup & Restore.');
      expect(kFactoryResetNoBackups,
          'There are no automatic backups on this device, so this cannot be undone.');
      expect(kFactoryResetConfirmButton, 'Erase everything');
      expect(kFactoryResetWillBackUp,
          "A backup will be saved first; it doesn't include receipt photos.");
    });
  });

  group('the confirm dialog', () {
    late Directory docs;
    const channel = MethodChannel('plugins.flutter.io/path_provider');

    setUp(() {
      docs = Directory.systemTemp.createTempSync('pos_reset_text_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => docs.path);
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      docs.deleteSync(recursive: true);
    });

    /// Pumps the section with a fake pre-reset backup ([backup] runs it).
    Future<void> pump(WidgetTester tester, List<String> log,
        {Future<File?> Function()? backup, bool shopHasData = false}) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          preResetBackupNeededProvider
              .overrideWithValue(() async => shopHasData),
          preResetBackupProvider.overrideWithValue(() async {
            log.add('backup');
            return backup == null ? null : await backup();
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DangerSection(onErase: (_) async => log.add('erase')),
          ),
        ),
      ));
    }

    /// Step one: the tile; then waits for the dialog.
    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.text('Factory Reset'));
      await pumpUntil(
          tester, () => find.text(kFactoryResetTitle).evaluate().isNotEmpty);
      await tester.pumpAndSettle();
    }

    Future<void> tapAndSettle(WidgetTester tester, String label) async {
      await tester.tap(find.text(label));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();
    }

    testWidgets('with an automatic backup: says they are kept, and its date',
        (tester) async {
      final auto = Directory(p.join(docs.path, 'backups', 'auto'))
        ..createSync(recursive: true);
      final when = DateTime(2026, 11, 1, 9, 30);
      File(p.join(auto.path, 'pos_backup_20261101_093000.zip'))
        ..writeAsBytesSync([1])
        ..setLastModifiedSync(when);
      await pump(tester, []);
      await openDialog(tester);
      expect(find.text(factoryResetConfirmText(latestBackup: when)),
          findsOneWidget);
      expect(find.textContaining(kFactoryResetBackupsKept), findsOneWidget);
      expect(find.textContaining(kFactoryResetNoBackups), findsNothing);
      expect(find.textContaining('Latest automatic backup: Nov 1, 2026'),
          findsOneWidget);
    });

    testWidgets(
        'a shop with data and no backups: promises the backup it takes, '
        'never "cannot be undone"', (tester) async {
      await pump(tester, [], shopHasData: true);
      await openDialog(tester);
      expect(find.textContaining(kFactoryResetWillBackUp), findsOneWidget);
      expect(
          find.textContaining(
              "A backup will be saved first; it doesn't include receipt photos."),
          findsOneWidget);
      expect(find.textContaining(kFactoryResetNoBackups), findsNothing);
      expect(find.textContaining(kFactoryResetBackupsKept), findsNothing);
      expect(
          find.textContaining('Latest automatic backup: none'), findsOneWidget);
    });

    testWidgets('with none: says it cannot be undone, latest none',
        (tester) async {
      await pump(tester, []);
      await openDialog(tester);
      expect(find.textContaining(kFactoryResetBody), findsOneWidget);
      expect(find.textContaining(kFactoryResetNoBackups), findsOneWidget);
      expect(find.textContaining(kFactoryResetBackupsKept), findsNothing);
      expect(
          find.textContaining('Latest automatic backup: none'), findsOneWidget);
    });

    testWidgets(
        'Cancel erases nothing (no backup either); Erase everything backs '
        'up first, then erases', (tester) async {
      final log = <String>[];
      await pump(tester, log, backup: () async => File('x.zip'));
      await openDialog(tester);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Erase everything'), findsOneWidget);
      await tapAndSettle(tester, 'Cancel');
      expect(find.text(kFactoryResetTitle), findsNothing);
      expect(log, isEmpty);

      await openDialog(tester);
      await tapAndSettle(tester, 'Erase everything');
      expect(log, ['backup', 'erase']);
      expect(find.text(kSavingBackupFirst), findsNothing);
      expect(find.text(kBackupFirstFailed), findsNothing);
    });

    testWidgets('a failed backup asks again; Cancel there keeps the shop',
        (tester) async {
      final log = <String>[];
      await pump(tester, log, backup: () async => throw StateError('disk'));
      await openDialog(tester);
      await tapAndSettle(tester, 'Erase everything');
      expect(find.text(kBackupFirstFailed), findsOneWidget);
      await tapAndSettle(tester, 'Cancel');
      expect(log, ['backup'], reason: 'not erased');

      await openDialog(tester);
      await tapAndSettle(tester, 'Erase everything');
      expect(find.text("Couldn't save a backup first. Erase anyway?"),
          findsOneWidget);
      await tapAndSettle(tester, 'Erase everything');
      expect(log, ['backup', 'backup', 'erase']);
    });
  });

  group('what counts as shop data for a reset', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('a fresh database (seeded expense categories only) has none',
        () async {
      expect(await hasShopData(db), isFalse);
    });

    for (final (name, insert) in <(String, Future<void> Function(AppDatabase))>[
      (
        'a restaurant table',
        (d) => d.into(d.tables).insert(TablesCompanion.insert(name: 'T1'))
      ),
      (
        'a tax rate',
        (d) => d.taxDao
            .upsertRate(TaxRatesCompanion.insert(name: 'VAT', rate: 0.13))
            .then((_) {})
      ),
      (
        'a category',
        (d) => d
            .into(d.categories)
            .insert(CategoriesCompanion.insert(name: 'Drinks'))
      ),
      ('a product', (d) => seedProduct(d, sku: 'A')),
      ('a customer', (d) => seedCustomer(d)),
    ]) {
      test('$name counts', () async {
        await insert(db);
        expect(await hasShopData(db), isTrue);
      });
    }

    test('a held ticket counts; the ticket counter alone does not', () async {
      final dir = Directory.systemTemp.createTempSync('pos_held_');
      addTearDown(() async {
        await Hive.close();
        dir.deleteSync(recursive: true);
      });
      Hive.init(dir.path);
      final held = await Hive.openBox<dynamic>('held_orders');
      await held.put(kTicketSeqKey, 4);
      expect(hasHeldTickets(held), isFalse);
      await held.put('t1', '{}');
      expect(hasHeldTickets(held), isTrue);
    });
  });

  group('the pre-reset backup', () {
    late Directory docs;
    const channel = MethodChannel('plugins.flutter.io/path_provider');

    setUp(() {
      docs = Directory.systemTemp.createTempSync('pos_prereset_');
      Hive.init(docs.path);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => docs.path);
    });
    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await Hive.close();
      docs.deleteSync(recursive: true);
    });

    ProviderContainer containerWith(AppDatabase db) {
      final c = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)]);
      addTearDown(c.dispose);
      return c;
    }

    Future<void> openBoxes() async {
      for (final b in kSnapshotHiveBoxes) {
        await Hive.openBox<dynamic>(b);
      }
    }

    test('an empty shop: nothing written', () async {
      await openBoxes();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final made = await containerWith(db).read(preResetBackupProvider)();
      expect(made, isNull);
      expect(Directory(p.join(docs.path, 'backups', 'auto')).existsSync(),
          isFalse);
    });

    test('a shop with data: one automatic backup in backups/auto', () async {
      await openBoxes();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await seedProduct(db, sku: 'A');
      final made = await containerWith(db).read(preResetBackupProvider)();
      expect(made, isNotNull);
      expect(made!.existsSync(), isTrue);
      expect(p.dirname(made.path), p.join(docs.path, 'backups', 'auto'));
      final listed = await const SnapshotService()
          .listLocal(Directory(p.join(docs.path, 'backups', 'auto')));
      expect(listed.map((f) => f.path), [made.path]);
    });
  });
}
