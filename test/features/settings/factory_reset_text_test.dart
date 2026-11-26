import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/settings/data/factory_reset.dart';
import 'package:pos_app/features/settings/presentation/widgets/danger_section.dart';

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
    test('every table eraseAllData deletes from is mapped and named',
        () async {
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

    Future<List<String>> open(WidgetTester tester, List<String> erased) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: DangerSection(onErase: (_) async => erased.add('erase')),
          ),
        ),
      ));
      // Step one: the tile.
      await tester.tap(find.text('Factory Reset'));
      await pumpUntil(
          tester, () => find.text(kFactoryResetTitle).evaluate().isNotEmpty);
      await tester.pumpAndSettle();
      return erased;
    }

    testWidgets('with an automatic backup: says they are kept',
        (tester) async {
      final auto = Directory(p.join(docs.path, 'backups', 'auto'))
        ..createSync(recursive: true);
      File(p.join(auto.path, 'pos_backup_20261101_120000.zip'))
          .writeAsBytesSync([1]);
      await open(tester, []);
      expect(find.text(factoryResetConfirmText(hasAutoBackups: true)),
          findsOneWidget);
      expect(find.textContaining(kFactoryResetBackupsKept), findsOneWidget);
      expect(find.textContaining(kFactoryResetNoBackups), findsNothing);
    });

    testWidgets('with none: says it cannot be undone', (tester) async {
      await open(tester, []);
      expect(find.textContaining(kFactoryResetBody), findsOneWidget);
      expect(find.textContaining(kFactoryResetNoBackups), findsOneWidget);
      expect(find.textContaining(kFactoryResetBackupsKept), findsNothing);
    });

    testWidgets('Cancel erases nothing; Erase everything erases',
        (tester) async {
      final erased = await open(tester, []);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Erase everything'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text(kFactoryResetTitle), findsNothing);
      expect(erased, isEmpty);

      await tester.tap(find.text('Factory Reset'));
      await pumpUntil(
          tester, () => find.text(kFactoryResetTitle).evaluate().isNotEmpty);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Erase everything'));
      await tester.pumpAndSettle();
      expect(erased, ['erase']);
    });
  });
}
