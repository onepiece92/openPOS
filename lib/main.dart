import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/app_root.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/utils/bundled_fonts.dart';
import 'package:pos_app/startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerBundledFontLicenses();

  // Recovers an interrupted restore before any store opens, then opens the
  // Hive boxes — or, if recovery failed, opens nothing and shows the error
  // screen (see startUp). The first DB query runs here, on the container
  // the app then uses, so a database that cannot open lands on the error
  // screen instead of half-working screens.
  final container = ProviderContainer();
  final startup = await startUp(
    checkDatabase: () =>
        container.read(databaseProvider).customSelect('SELECT 1').get(),
  );

  runApp(AppRoot(
    container: container,
    startupNotice: startup.notice,
    startupFatal: startup.fatal,
    startupDbError: startup.dbError,
  ));
}
