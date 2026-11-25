import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/app_root.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/review/data/review_state_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Before any store opens: a restore killed mid-swap would otherwise leave
  // Drift creating an empty DB while the real one sits in `.bak`.
  final recovery = await recoverInterruptedRestoreAtStartup();

  // Open Hive boxes before the ProviderContainer exists so providers can
  // read synchronously. The DB itself is owned by databaseProvider.
  await Hive.initFlutter();
  await Future.wait([
    for (final name in kSnapshotHiveBoxes) Hive.openBox<dynamic>(name),
  ]);
  // Starts the review-prompt clock (no-op after the first launch).
  await ReviewStateStore(Hive.box<dynamic>('settings'))
      .ensureFirstLaunch(DateTime.now());

  runApp(AppRoot(startupNotice: restoreRecoveryNotice(recovery)));
}
