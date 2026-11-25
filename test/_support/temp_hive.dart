import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Opens a fresh `settings` box (and any [more] boxes) in a temp folder and
/// closes and deletes them after the test.
Future<Box<dynamic>> openTempSettingsBox({List<String> more = const []}) async {
  final tmp = await Directory.systemTemp.createTemp('pos_hive_');
  Hive.init(tmp.path);
  final box = await Hive.openBox<dynamic>('settings');
  for (final name in more) {
    await Hive.openBox<dynamic>(name);
  }
  addTearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });
  return box;
}
