import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:pos_app/features/printing/domain/escpos_raster.dart';

/// Receipts reach ESC/POS printers as dots, not text, so that any script
/// prints. These tests pin the command framing that carries them.

Uint8List _pngPage({int width = 576, int height = 24}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  img.drawLine(image,
      x1: 0, y1: 0, x2: width - 1, y2: height - 1, color: img.ColorRgb8(0, 0, 0));
  return Uint8List.fromList(img.encodePng(image));
}

int _countSequence(List<int> haystack, List<int> needle) {
  var found = 0;
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    var match = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        match = false;
        break;
      }
    }
    if (match) found++;
  }
  return found;
}

/// The first `GS v 0` raster in [bytes]: its width in dots and its bitmap.
({int widthDots, int height, List<int> data}) _firstRaster(List<int> bytes) {
  for (var i = 0; i + 8 <= bytes.length; i++) {
    if (bytes[i] == 0x1D && bytes[i + 1] == 0x76 && bytes[i + 2] == 0x30) {
      final widthBytes = bytes[i + 4] | (bytes[i + 5] << 8);
      final height = bytes[i + 6] | (bytes[i + 7] << 8);
      final start = i + 8;
      return (
        widthDots: widthBytes * 8,
        height: height,
        data: bytes.sublist(start, start + widthBytes * height),
      );
    }
  }
  throw StateError('no raster in job');
}

/// A white page [width] wide with a solid black block at the top-left.
Uint8List _blockPage(int width, {bool transparent = false}) {
  final image = img.Image(width: width, height: 16, numChannels: 4);
  img.fill(image,
      color: transparent
          ? img.ColorRgba8(0, 0, 0, 0)
          : img.ColorRgba8(255, 255, 255, 255));
  img.fillRect(image,
      x1: 0, y1: 0, x2: 15, y2: 7, color: img.ColorRgba8(0, 0, 0, 255));
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  // CapabilityProfile.load() reads its profile from rootBundle.
  TestWidgetsFlutterBinding.ensureInitialized();

  /// GS v 0 — the raster bitmap command every ESC/POS printer implements.
  const gsV0 = [0x1D, 0x76, 0x30];

  /// GS V — paper cut.
  const gsV = [0x1D, 0x56];

  test('wraps a rendered page in a raster bitmap command', () async {
    final bytes = await escPosRasterBytes([_pngPage()], 80);

    expect(bytes, isNotEmpty);
    expect(_countSequence(bytes, gsV0), 1);
  });

  test('a long bill sends one raster per page, then a single cut', () async {
    final bytes = await escPosRasterBytes(
      [_pngPage(), _pngPage(), _pngPage()],
      80,
    );

    expect(_countSequence(bytes, gsV0), 3);
    expect(_countSequence(bytes, gsV), 1,
        reason: 'the roll is cut once, after the last page');
  });

  test('58mm and 80mm both produce a printable job', () async {
    final narrow = await escPosRasterBytes([_pngPage(width: 384)], 58);
    final wide = await escPosRasterBytes([_pngPage()], 80);

    expect(_countSequence(narrow, gsV0), 1);
    expect(_countSequence(wide, gsV0), 1);
    expect(wide.length, greaterThan(narrow.length),
        reason: 'a wider head means more dots per line');
  });

  test('undecodable page data fails loudly rather than printing noise',
      () async {
    expect(
      () => escPosRasterBytes([Uint8List.fromList([1, 2, 3])], 80),
      throwsA(isA<StateError>()),
    );
  });

  group('render width is fitted to the print head', () {
    for (final (src, paper, dots) in [
      (575, 80, 576),
      (577, 80, 576),
      (383, 58, 384),
      (720, 80, 576),
    ]) {
      test('$src px on ${paper}mm prints $dots dots with the ink intact',
          () async {
        final raster =
            _firstRaster(await escPosRasterBytes([_blockPage(src)], paper));

        expect(raster.widthDots, dots);
        final rowBytes = dots ~/ 8;
        expect(raster.data[0], 0xFF,
            reason: 'the black block must print as set dots, not zeros');
        expect(raster.data[rowBytes - 1], 0x00,
            reason: 'the padded right edge is white');
        expect(raster.data.last, 0x00,
            reason: 'the white background prints nothing');
      });
    }
  });

  test('a transparent background prints as white paper, not solid black',
      () async {
    final raster = _firstRaster(
        await escPosRasterBytes([_blockPage(575, transparent: true)], 80));

    expect(raster.widthDots, 576);
    expect(raster.data[0], 0xFF, reason: 'the opaque black block prints');
    final setBytes = raster.data.where((b) => b != 0).length;
    expect(setBytes, lessThanOrEqualTo(2 * 8),
        reason: 'only the 16x8 block is inked');
  });
}
