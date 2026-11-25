import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/utils/bundled_fonts.dart';
import 'package:pos_app/features/printing/domain/escpos_raster.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a bundled font is read from the bundle once', () async {
    final first = await bundledFontData(jetBrainsMonoRegular);
    final second = await bundledFontData(jetBrainsMonoRegular);

    expect(identical(first, second), isTrue);
    expect(first.lengthInBytes, greaterThan(0));
  });

  test('different fonts are cached separately', () async {
    final regular = await bundledFontData(jetBrainsMonoRegular);
    final bold = await bundledFontData(jetBrainsMonoBold);

    expect(identical(regular, bold), isFalse);
  });

  test('a missing font fails, and is retried rather than cached', () async {
    const missing = 'assets/fonts/does-not-exist.ttf';
    final first = bundledFontData(missing);
    await expectLater(first, throwsA(anything));

    final second = bundledFontData(missing);
    expect(identical(first, second), isFalse,
        reason: 'a failed load must not stick in the cache');
    await expectLater(second, throwsA(anything));
  });

  test('the ESC/POS capability profile is parsed once', () async {
    final first = await escPosProfile();
    final second = await escPosProfile();

    expect(identical(first, second), isTrue);
  });
}
