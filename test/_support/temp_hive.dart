import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Opens a fresh in-memory `settings` box (and any [more] boxes) and closes
/// them after the test. In memory, so writes from inside `testWidgets`'
/// fake clock never wait on real file I/O.
Future<Box<dynamic>> openTempSettingsBox({List<String> more = const []}) async {
  final tmp = await Directory.systemTemp.createTemp('pos_hive_');
  Hive.init(tmp.path);
  final box = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
  for (final name in more) {
    await Hive.openBox<dynamic>(name, bytes: Uint8List(0));
  }
  addTearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });
  return box;
}
