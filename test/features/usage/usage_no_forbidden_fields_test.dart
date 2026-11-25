import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/data/usage_inputs.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/domain/usage_summary.dart';

import '../../_support/test_db.dart';
import '_grammar.dart';

/// Seeds every text column of every table (and every store-profile setting)
/// with a sentinel, builds the summary the way the screen does, and checks
/// that no sentinel — and no seeded amount — reaches it.
void main() {
  late AppDatabase db;
  late Directory tmp;
  late Box<dynamic> settings;
  late Box<dynamic> usageBox;
  const sentinel = 'ZQXSENT';
  const amount = 98765.4321;

  setUp(() async {
    db = openInMemoryDatabase();
    tmp = await Directory.systemTemp.createTemp('pos_usage_sentinel_');
    Hive.init(tmp.path);
    settings = await Hive.openBox<dynamic>('settings');
    usageBox = await Hive.openBox<dynamic>(kUsageBoxName);
  });
  tearDown(() async {
    await db.close();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  Future<List<String>> seed() async {
    final cat = await db
        .into(db.categories)
        .insert(CategoriesCompanion.insert(name: '${sentinel}_category'));
    final expCat = await db
        .into(db.expenseCategories)
        .insert(ExpenseCategoriesCompanion.insert(name: '${sentinel}_expcat'));
    final products = <int>[];
    for (var i = 0; i < 3; i++) {
      products.add(await db.into(db.products).insert(ProductsCompanion.insert(
            sku: '${sentinel}_sku$i',
            name: '${sentinel}_product$i',
            price: amount,
            categoryId: Value(cat),
          )));
    }
    final customer = await db.into(db.customers).insert(
        CustomersCompanion.insert(
            name: '${sentinel}_Jane Smith',
            phone: const Value('${sentinel}_555'),
            email: const Value('$sentinel@example.com'),
            address: const Value('${sentinel}_address')));
    final table = await db
        .into(db.tables)
        .insert(TablesCompanion.insert(name: '${sentinel}_table'));
    final order = await db.ordersDao.insertOrder(OrdersCompanion.insert(
      subtotal: amount,
      total: amount,
      paymentMethod: 'cash',
      customerId: Value(customer),
      tableId: Value(table),
      notes: const Value('${sentinel}_order note'),
    ));
    await db.into(db.orderItems).insert(OrderItemsCompanion.insert(
          orderId: order,
          productId: products.first,
          productName: '${sentinel}_snapshot',
          unitPrice: amount,
          quantity: 1,
          lineTotal: amount,
        ));
    await db.ordersDao.insertReturn(ReturnsCompanion.insert(
        orderId: order,
        amount: amount,
        reason: const Value('${sentinel}_why')));
    await db.into(db.expenses).insert(ExpensesCompanion.insert(
          amount: amount,
          date: DateTime.now(),
          categoryId: expCat,
          notes: const Value('${sentinel}_expense note'),
        ));

    // Then overwrite EVERY text column of EVERY table with a sentinel and
    // every real column with the distinctive amount (columns whose
    // constraints refuse it are reported and left as seeded).
    final skipped = <String>[];
    for (final t in db.allTables) {
      for (final c in t.$columns) {
        final name = '${t.actualTableName}.${c.name}';
        try {
          if (c.type == DriftSqlType.string) {
            await db.customStatement(
                'UPDATE "${t.actualTableName}" SET "${c.name}" = '
                "'${sentinel}_${t.actualTableName}_${c.name}_' || rowid");
          } else if (c.type == DriftSqlType.double) {
            await db.customStatement(
                'UPDATE "${t.actualTableName}" SET "${c.name}" = $amount');
          }
        } catch (_) {
          skipped.add(name);
        }
      }
    }

    for (final k in [
      kBusinessName,
      kBusinessTagline,
      kBusinessPhone,
      kBusinessAddress,
      kBusinessPan,
      kCurrencySymbol,
      kCountryCode,
      kInvoicePrefix,
      kTimezone,
      kPrinterDeviceName,
      kPrinterDeviceAddress,
    ]) {
      await settings.put(k, '${sentinel}_$k');
    }
    await settings.put(kCurrencyCode, 'USD');
    return skipped;
  }

  test('no sentinel and no amount reaches the summary', () async {
    final skipped = await seed();
    // ignore: avoid_print
    if (skipped.isNotEmpty) print('columns not overwritten: $skipped');

    final counter = UsageCounter(openBox: () async => usageBox);
    await counter.ensureLoaded();
    for (final e in UsageEvent.values) {
      counter.record(e);
    }

    // Exactly what UsageScreen does.
    var selection = const UsageSelection().withAppInfo(true).withShopSize(true);
    for (final a in FeatureArea.values) {
      selection = selection.togglePicked(a);
    }
    final shop = await readShopSizeCounts(db);
    final text = buildUsageSummary(
      selection: selection,
      message: '',
      counts: counter.counts,
      env: currentUsageEnvironment(
          currencyCode: AppSettings.fromBox(settings).currencyCode),
      shop: shop,
    );

    expect(shop.products, 3);
    expect(
        text,
        contains('Shop size: products 1-10, orders in last 7 days '
            '1-10, customers 1-10'));
    expect(text, isNot(contains(sentinel)));
    expect(text, isNot(contains('98765')));
    expect(text, isNot(contains('Jane')));
    expect(text, isNot(contains('@')));
    expectGrammar(text);

    // The shopkeeper's own words are the only way in — and only inside
    // the message section.
    final typed = buildUsageSummary(
      selection: selection,
      message: 'My shop is ${sentinel}_shop',
      counts: counter.counts,
      env: currentUsageEnvironment(currencyCode: 'USD'),
      shop: shop,
    );
    final parts = splitSummary(typed);
    expect(parts.fixed.join('\n'), isNot(contains(sentinel)));
    expect(parts.message, 'My shop is ${sentinel}_shop');
  });
}
