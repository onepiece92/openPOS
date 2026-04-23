import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/providers/database_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open Hive boxes before ProviderScope so providers can read synchronously
  await Hive.initFlutter();
  await Hive.openBox<dynamic>('settings');
  await Hive.openBox<dynamic>('held_orders');

  final database = AppDatabase();

  runApp(
    ProviderScope(
      overrides: [
        // Override so the DB singleton is shared app-wide
        databaseProvider.overrideWithValue(database),
      ],
      child: const POSApp(),
    ),
  );
}
