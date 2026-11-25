import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The shop's database and settings must not be copied off the device by
/// Android itself (Auto Backup to the Google account, device-to-device
/// transfer), and the app must stay unable to reach the network.
void main() {
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final rules = File('android/app/src/main/res/xml/data_extraction_rules.xml')
      .readAsStringSync();

  test('OS backup is switched off on <application>', () {
    final application =
        RegExp(r'<application\b[^>]*>', dotAll: true).firstMatch(manifest)![0]!;
    expect(application, contains('android:allowBackup="false"'));
    expect(application, contains('android:fullBackupContent="false"'));
    expect(application,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
  });

  test('Android 12+ rules exclude every domain from cloud backup and '
      'device transfer', () {
    const domains = [
      'root', 'file', 'database', 'sharedpref', 'external', //
      'device_root', 'device_file', 'device_database', 'device_sharedpref',
    ];
    for (final section in ['cloud-backup', 'device-transfer']) {
      final body = RegExp('<$section>(.*?)</$section>', dotAll: true)
          .firstMatch(rules)![1]!;
      expect(body, isNot(contains('<include')));
      for (final domain in domains) {
        expect(body, contains('<exclude domain="$domain" path="." />'),
            reason: '$section must exclude $domain');
      }
    }
  });

  test('the manifest still declares no INTERNET permission', () {
    expect(manifest, isNot(contains('android.permission.INTERNET')));
  });
}
