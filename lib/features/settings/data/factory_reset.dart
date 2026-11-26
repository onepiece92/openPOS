import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:pos_app/features/cart/data/ticket_sequence.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';

/// Factory Reset's confirm text: exactly what goes and what stays.
const kFactoryResetConfirmText =
    'This permanently deletes all products, orders, customers, expenses, '
    'held tickets, tables, receipt photos and settings. '
    'Automatic backups are kept.';

/// Shown on the reset's splash while the data is erased.
const kFactoryResetProgress = 'Resetting…';

/// Shown when the database could not be erased (nothing was changed).
const kFactoryResetFailedNotice =
    "Reset didn't work. Your data was not changed.";

/// Shown when the database was erased but some local files were not.
const kFactoryResetIncompleteNotice =
    "Reset didn't finish. Open Settings and run Factory Reset again.";

/// The Hive and file half of a factory reset (the database half is
/// `AppDatabase.eraseAllData`). Clears:
/// * [settings] (so onboarding shows again);
/// * every held ticket in [heldOrders], keeping its ticket counter so
///   numbers never repeat;
/// * [usage] — counts and flags, so the first-run usage notice shows again;
/// * the receipt photos folder [receipts].
///
/// Automatic backups (`backups/auto`) are not touched. Run with the app's
/// widget tree and providers torn down, so nothing writes back stale state.
Future<void> eraseLocalStores({
  required Box<dynamic> settings,
  required Box<dynamic> heldOrders,
  required Box<dynamic> usage,
  required Directory receipts,
}) async {
  await clearHeldTicketsKeepingCounter(heldOrders);
  await usage.clear();
  await settings.clear();
  if (receipts.existsSync()) await receipts.delete(recursive: true);
}

/// The usage box, opened beside the settings box when the usage counter
/// never opened it (it opens lazily).
Future<Box<dynamic>> usageBoxForReset() async {
  if (Hive.isBoxOpen(kUsageBoxName)) return Hive.box<dynamic>(kUsageBoxName);
  final settingsPath = Hive.box<dynamic>('settings').path;
  return Hive.openBox<dynamic>(kUsageBoxName,
      path: settingsPath == null ? null : p.dirname(settingsPath));
}
