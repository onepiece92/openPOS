import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/app_root.dart';
import 'package:pos_app/features/backup/data/snapshot_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open Hive boxes before the ProviderContainer exists so providers can
  // read synchronously. The DB itself is owned by databaseProvider.
  await Hive.initFlutter();
  await Future.wait([
    for (final name in kSnapshotHiveBoxes) Hive.openBox<dynamic>(name),
  ]);

  runApp(const AppRoot());
}
