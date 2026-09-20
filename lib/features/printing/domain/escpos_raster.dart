import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

/// Wraps rendered receipt [pages] in an ESC/POS raster job (`GS v 0`).
///
/// ESC/POS text mode can only print the characters baked into the printer's
/// firmware, which is why receipts are rendered to an image first and sent
/// as dots: the same bill prints identically on every printer, in any
/// script, with no code-page guessing.
///
/// [paperMm] must be 58 or 80; anything else is treated as 80mm.
Future<List<int>> escPosRasterBytes(
  List<Uint8List> pages,
  int paperMm,
) async {
  final profile = await CapabilityProfile.load();
  final generator = Generator(
    paperMm == 58 ? PaperSize.mm58 : PaperSize.mm80,
    profile,
  );

  final bytes = <int>[...generator.reset()];
  for (final page in pages) {
    final decoded = img.decodePng(page);
    if (decoded == null) {
      throw StateError('Receipt image could not be decoded');
    }
    // Grayscale first: the raster encoder thresholds per pixel, and an
    // anti-aliased PDF render otherwise speckles thin glyph strokes.
    bytes.addAll(generator.imageRaster(img.grayscale(decoded)));
  }
  bytes.addAll(generator.feed(2));
  bytes.addAll(generator.cut());
  return bytes;
}
