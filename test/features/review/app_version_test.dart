import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/review/domain/app_version.dart';

void main() {
  test('kAppVersion matches pubspec.yaml version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final m = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec);
    expect(m, isNotNull);
    expect(kAppVersion, m!.group(1),
        reason: 'bump lib/features/review/domain/app_version.dart with pubspec');
  });
}
