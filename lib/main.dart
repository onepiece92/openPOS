import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/app_root.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';
import 'package:pos_app/features/review/data/review_state_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open Hive boxes before the ProviderContainer exists so providers can
  // read synchronously. The DB itself is owned by databaseProvider.
  await Hive.initFlutter();
  for (final name in kSnapshotHiveBoxes) {
    await Hive.openBox<dynamic>(name);
  }
  // Starts the review-prompt clock (no-op after the first launch).
  await ReviewStateStore(Hive.box<dynamic>('settings'))
      .ensureFirstLaunch(DateTime.now());

  runApp(const AppRoot());
}
