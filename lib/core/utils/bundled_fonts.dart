import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:pdf/widgets.dart' as pw;

const jetBrainsMonoRegular = 'assets/fonts/JetBrainsMono-Regular.ttf';
const jetBrainsMonoBold = 'assets/fonts/JetBrainsMono-Bold.ttf';
const jetBrainsMonoItalic = 'assets/fonts/JetBrainsMono-Italic.ttf';

final Map<String, Future<ByteData>> _fontData = {};

/// The bytes of the bundled font at [asset], read from the bundle once.
///
/// `rootBundle.load` does not cache, and every receipt used to read each
/// font file again. A failed load is dropped from the cache so the next
/// receipt retries instead of failing forever.
Future<ByteData> bundledFontData(String asset) {
  final cached = _fontData[asset];
  if (cached != null) return cached;
  // Future.sync: a missing asset can throw before a future exists.
  final future = Future.sync(() => rootBundle.load(asset));
  _fontData[asset] = future;
  future.then<void>((_) {}, onError: (Object _) {
    if (identical(_fontData[asset], future)) _fontData.remove(asset);
  });
  return future;
}

/// A PDF font for the bundled [asset].
///
/// Only the bytes are shared. A fresh [pw.Font] is made per call because a
/// font object remembers the last document it was embedded in, and two
/// receipts built at once would otherwise trade embeddings mid-layout.
Future<pw.Font> bundledPdfFont(String asset) async =>
    pw.Font.ttf(await bundledFontData(asset));
