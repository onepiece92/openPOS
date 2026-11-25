import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:pos_app/core/app_version.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/features/usage/domain/usage_summary.dart';

/// The three COUNTs behind the shop-size ranges. Run only when the feedback
/// & usage screen opens — never at startup or on the sell screen. Each is a
/// single `COUNT(*)`; the orders one uses `idx_orders_created_at`.
Future<ShopSizeCounts> readShopSizeCounts(AppDatabase db,
    {DateTime? now}) async {
  Future<int> countOf(TableInfo<Table, Object?> t) async {
    final c = countAll();
    final row = await (db.selectOnly(t)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }

  final t = now ?? DateTime.now();
  return ShopSizeCounts(
    products: await countOf(db.products),
    ordersLast7Days: await db.ordersDao
        .orderCountForPeriod(t.subtract(const Duration(days: 7)), t),
    customers: await countOf(db.customers),
  );
}

/// App version, platform, OS major version and locale of this device, plus
/// the store's [currencyCode]. Read at render time; nothing is stored.
UsageEnvironment currentUsageEnvironment({required String currencyCode}) =>
    UsageEnvironment(
      appVersion: kAppVersionFull,
      platform: kIsWeb ? 'web' : Platform.operatingSystem,
      osMajorVersion:
          kIsWeb ? null : parseOsMajorVersion(Platform.operatingSystemVersion),
      locale: PlatformDispatcher.instance.locale.toLanguageTag(),
      currencyCode: currencyCode,
    );
