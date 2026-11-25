import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

import 'package:pos_app/features/printing/domain/render_receipt_image.dart';

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
    final dots = escPosPrintWidthDots(paperMm == 58 ? 58 : 80);
    bytes.addAll(
      generator.imageRaster(img.grayscale(fitToPrintHead(decoded, dots))),
    );
  }
  bytes.addAll(generator.feed(2));
  bytes.addAll(generator.cut());
  return bytes;
}

/// How far (in dots) a render may be off the head width and still be padded
/// or cropped rather than rescaled. Rasterising a `dots / 8` mm page at
/// 203 dpi lands a dot or two short (575 for 576), which is not worth a
/// blurring resample.
const int _maxPadOrCropDots = 8;

/// Returns [src] laid onto an opaque white canvas exactly [widthDots] wide.
///
/// Two things this guards against, both of which print as blank or garbage:
/// - esc_pos_utils_plus zeroes the pixel buffer when the width is not a
///   multiple of 8, so the width must already be the head's (576 / 384).
/// - A transparent background grayscales to black and the encoder's invert
///   then prints it solid, so alpha is flattened onto white first.
///
/// A render within [_maxPadOrCropDots] of the target is padded (or cropped)
/// on the right with white; anything further off is scaled to fit.
img.Image fitToPrintHead(img.Image src, int widthDots) {
  var source = src;
  if ((source.width - widthDots).abs() > _maxPadOrCropDots) {
    source = img.copyResize(
      source,
      width: widthDots,
      interpolation: img.Interpolation.average,
    );
  }
  final canvas = img.Image(width: widthDots, height: source.height);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(canvas, source, dstX: 0, dstY: 0);
  return canvas;
}
