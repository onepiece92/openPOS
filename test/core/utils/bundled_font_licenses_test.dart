import 'package:flutter/foundation.dart' show LicenseRegistry;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/utils/bundled_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('both bundled font licences are registered', () async {
    registerBundledFontLicenses();
    final packages = <String>{};
    await for (final entry in LicenseRegistry.licenses) {
      packages.addAll(entry.packages);
    }
    expect(packages, contains('JetBrains Mono'));
    expect(packages, contains('OpenPOS Symbols (Noto subset)'));
  });
}
