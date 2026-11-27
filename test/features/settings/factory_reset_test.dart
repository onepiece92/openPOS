import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/features/backup/data/temp_files.dart';
import 'package:pos_app/features/cart/data/ticket_sequence.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/settings/data/factory_reset.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';

import '../../_support/sales.dart';
import '../../_support/test_db.dart';

void main() {
  group('AppDatabase.eraseAllData', () {
    late AppDatabase db;
    setUp(() => db = openInMemoryDatabase());
    tearDown(() => db.close());

    Future<int> rows(String table) async => (await db
            .customSelect('SELECT COUNT(*) AS n FROM "$table"')
            .getSingle())
        .read<int>('n');

    test(
        'empties every table (restaurant tables too), FK-safe, and reseeds '
        'the first-run defaults', () async {
      final pid = await seedProduct(db, sku: 'A');
      final cid = await seedCustomer(db);
      final tid =
          await db.into(db.tables).insert(TablesCompanion.insert(name: 'T1'));
      final oid =
          await sell(db, AuditService(db), [line(pid)], customerId: cid);
      // An order seated at a table: tables can only go after orders.
      await (db.update(db.orders)..where((o) => o.id.equals(oid)))
          .write(OrdersCompanion(tableId: Value(tid)));
      final cat = (await db.select(db.expenseCategories).get()).first;
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
          categoryId: cat.id, amount: 3, date: DateTime(2026, 1, 1)));
      final seededCategories = await rows('expense_categories');

      final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(fk.data.values.single, 1, reason: 'FKs are enforced');

      await db.eraseAllData();

      for (final t in db.allTables) {
        final n = await rows(t.actualTableName);
        if (t.actualTableName == 'expense_categories') {
          expect(n, seededCategories, reason: 'defaults, like a first run');
        } else {
          expect(n, 0, reason: '${t.actualTableName} is emptied');
        }
      }
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    });
  });

  group('eraseLocalStores', () {
    late Directory docs;
    late Box<dynamic> settings, held, usage;

    setUp(() async {
      docs = Directory.systemTemp.createTempSync('pos_reset_');
      Hive.init(docs.path);
      settings = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
      held = await Hive.openBox<dynamic>('held_orders', bytes: Uint8List(0));
      usage = await Hive.openBox<dynamic>(kUsageBoxName, bytes: Uint8List(0));
    });
    tearDown(() async {
      await Hive.close();
      docs.deleteSync(recursive: true);
    });

    String ticket(String id, String number) => jsonEncode(HeldOrder(
          id: id,
          ticketNumber: number,
          label: number,
          createdAt: DateTime(2026, 1, 1),
          items: const [],
        ).toJson());

    test(
        'clears settings, held tickets, usage and receipt photos; keeps the '
        'ticket counter and automatic backups', () async {
      await settings.put('onboarding_complete', true);
      await held.put('t1', ticket('t1', '#0007'));
      await held.put(kTicketSeqKey, 7);
      await usage.put(kUsageDisclosureShownKey, true);
      await usage.put('e.saleCompleted', {'c': 3});
      final receipts = Directory(p.join(docs.path, 'receipts'))..createSync();
      File(p.join(receipts.path, 'a.jpg')).writeAsBytesSync([1, 2, 3]);
      final auto = Directory(p.join(docs.path, 'backups', 'auto'))
        ..createSync(recursive: true);
      final backup = File(p.join(auto.path, 'auto.zip'))..writeAsBytesSync([9]);

      await eraseLocalStores(
          settings: settings,
          heldOrders: held,
          usage: usage,
          receipts: receipts);

      expect(settings.isEmpty, isTrue);
      expect(held.keys, [kTicketSeqKey]);
      expect(held.get(kTicketSeqKey), 7);
      expect(TicketSequence(held).next(), '#0008', reason: 'never repeats');
      expect(usage.isEmpty, isTrue);
      expect(receipts.existsSync(), isFalse);
      expect(backup.existsSync(), isTrue);
    });

    test(
        'deletes shared exports and backup working files in temp; keeps '
        'every automatic backup and the pre-reset backup', () async {
      final temp = Directory(p.join(docs.path, 'tmp'))..createSync();
      final share = Directory(p.join(temp.path, kShareTempFolder))..createSync();
      final sharedZip = File(p.join(share.path, 'pos_snapshot_1.zip'))
        ..writeAsBytesSync([1]);
      File(p.join(share.path, 'sales_report.csv')).writeAsStringSync('x');
      final sharePlus = Directory(p.join(temp.path, kSharePlusTempFolder))
        ..createSync();
      File(p.join(sharePlus.path, 'copy.zip')).writeAsBytesSync([1]);
      final vacuum = File(p.join(temp.path, 'pos_snapshot_99.db'))
        ..writeAsBytesSync([1]);
      final settingsCopy = File(p.join(temp.path, 'settings_snapshot_99.hive'))
        ..writeAsBytesSync([1]);
      final unrelated = File(p.join(temp.path, 'other.txt'))
        ..writeAsStringSync('keep');
      final auto = Directory(p.join(docs.path, 'backups', 'auto'))
        ..createSync(recursive: true);
      final autoFiles = [
        for (final n in ['pos_snapshot_a.zip', 'pos_snapshot_b.zip'])
          File(p.join(auto.path, n))..writeAsBytesSync([9]),
      ];
      // The one backup the reset takes just before the erase.
      final preReset = File(p.join(auto.path, 'pos_snapshot_pre.zip'))
        ..writeAsBytesSync([8]);

      await eraseLocalStores(
          settings: settings,
          heldOrders: held,
          usage: usage,
          receipts: Directory(p.join(docs.path, 'receipts')),
          temp: temp);

      expect(share.existsSync(), isFalse);
      expect(sharedZip.existsSync(), isFalse);
      expect(sharePlus.existsSync(), isFalse);
      expect(vacuum.existsSync(), isFalse);
      expect(settingsCopy.existsSync(), isFalse);
      expect(unrelated.existsSync(), isTrue, reason: 'only our leftovers');
      for (final f in [...autoFiles, preReset]) {
        expect(f.existsSync(), isTrue, reason: '${f.path} is kept');
      }
    });

    test(
        'a box from before the counter: the high-water mark is pinned down '
        'before the tickets go', () async {
      await held.put('t1', ticket('t1', '#0042'));
      await eraseLocalStores(
          settings: settings,
          heldOrders: held,
          usage: usage,
          receipts: Directory(p.join(docs.path, 'receipts')));
      expect(held.keys, [kTicketSeqKey]);
      expect(TicketSequence(held).next(), '#0043');
    });
  });
}
