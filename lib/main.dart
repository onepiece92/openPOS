import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/app_root.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/utils/bundled_fonts.dart';
import 'package:pos_app/features/settings/data/factory_reset.dart';
import 'package:pos_app/startup.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerBundledFontLicenses();

  // The first frame goes up straight away: AppRoot shows a plain surface
  // (the launch screen's colour) until startUp resolves. startUp recovers
  // an interrupted restore before any store opens, opens the Hive boxes,
  // then runs the database's first query on the container the app goes on
  // to use — so the DB open (and any migration) happens after the first
  // frame, and a database that cannot open lands on the error screen
  // instead of half-working screens. An unexpected throw is routed there
  // too ("Something went wrong", with Try again).
  final container = ProviderContainer();
  final startup = startUp(
    checkDatabase: () async {
      await checkDatabaseFileBeforeOpen();
      await container.read(databaseProvider).customSelect('SELECT 1').get();
    },
    finishFactoryReset: () => finishPendingFactoryResetOnLaunch(
        () => container.read(databaseProvider)),
  ).catchError((Object e) => StartupResult(dbError: e));

  runApp(AppRoot(container: container, startup: startup));
}
