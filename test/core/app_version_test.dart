import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/app_version.dart';

/// The Support screen shows [kAppVersion] and [kAppBuildNumber]; the stores
/// see pubspec.yaml. They must be the same thing.
void main() {
  test('the version shown in the app is the one in pubspec.yaml', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .singleWhere((l) => l.startsWith('version:'));
    expect(line, 'version: $kAppVersion+$kAppBuildNumber',
        reason: 'update lib/core/app_version.dart with pubspec.yaml');
  });

  test('the iOS project takes its version from pubspec.yaml', () {
    // A FLUTTER_BUILD_NAME / FLUTTER_BUILD_NUMBER build setting on the
    // Runner target overrides the value Flutter generates from pubspec.yaml,
    // so the app would ship under the hard-coded version instead.
    final project =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(project, isNot(contains(RegExp(r'FLUTTER_BUILD_NAME\s*='))));
    expect(project, isNot(contains(RegExp(r'FLUTTER_BUILD_NUMBER\s*='))));

    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains(r'<string>$(FLUTTER_BUILD_NAME)</string>'));
    expect(plist, contains(r'<string>$(FLUTTER_BUILD_NUMBER)</string>'));
  });
}
