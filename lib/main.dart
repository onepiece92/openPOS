import 'package:flutter/material.dart';

import 'package:pos_app/app_root.dart';
import 'package:pos_app/core/utils/bundled_fonts.dart';
import 'package:pos_app/startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerBundledFontLicenses();

  // Recovers an interrupted restore before any store opens, then opens the
  // Hive boxes — or, if recovery failed, opens nothing and shows the error
  // screen (see startUp).
  final startup = await startUp();

  runApp(AppRoot(
    startupNotice: startup.notice,
    startupFatal: startup.fatal,
  ));
}
