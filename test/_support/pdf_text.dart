import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// The text runs of a PDF made by the `pdf` package, in drawing order.
///
/// The package draws TrueType text as glyph ids, so the text is not in the
/// file as characters. Each font does carry a /ToUnicode map, so this reads
/// the objects, inflates the streams, maps every `<glyphs> Tj` / `TJ` run
/// back through its font's map and returns one string per run.
List<String> pdfTextRuns(List<int> bytes) {
  final raw = latin1.decode(bytes);
  final objects = <int, ({String dict, List<int>? data})>{};
  final objRe = RegExp(r'(\d+) 0 obj(.*?)endobj', dotAll: true);
  for (final m in objRe.allMatches(raw)) {
    final id = int.parse(m.group(1)!);
    final body = m.group(2)!;
    final s = body.indexOf('stream');
    if (s < 0) {
      objects[id] = (dict: body, data: null);
      continue;
    }
    final dict = body.substring(0, s);
    var from = s + 'stream'.length;
    if (body.startsWith('\r\n', from)) {
      from += 2;
    } else if (body.startsWith('\n', from)) {
      from += 1;
    }
    final end = body.lastIndexOf('endstream');
    var data = Uint8List.fromList(
        latin1.encode(body.substring(from, end < from ? from : end)));
    if (dict.contains('FlateDecode')) {
      try {
        data = Uint8List.fromList(zlib.decode(data));
      } on FormatException {
        // Trailing newline before endstream: retry without it.
        data = Uint8List.fromList(zlib.decode(data.sublist(0, data.length - 1)));
      }
    }
    objects[id] = (dict: dict, data: data);
  }

  // glyph id -> text, per font object.
  final cmaps = <int, Map<int, String>>{};
  for (final e in objects.entries) {
    if (!e.value.dict.contains('/Type0')) continue;
    final ref = RegExp(r'/ToUnicode (\d+) 0 R').firstMatch(e.value.dict);
    if (ref == null) continue;
    final cm = objects[int.parse(ref.group(1)!)];
    if (cm?.data == null) continue;
    cmaps[e.key] = _parseCmap(latin1.decode(cm!.data!));
  }

  // /F12 -> font object, from the resource dictionaries.
  final fontOf = <String, int>{};
  for (final e in objects.entries) {
    for (final m in RegExp(r'/(F\d+) (\d+) 0 R').allMatches(e.value.dict)) {
      fontOf[m.group(1)!] = int.parse(m.group(2)!);
    }
  }

  final runs = <String>[];
  final tokenRe = RegExp(r'/(F\d+) [\d.]+ Tf|\[((?:<[0-9A-Fa-f]*>|[-\d. ])*)\]\s*TJ|<([0-9A-Fa-f]*)>\s*Tj');
  for (final e in objects.entries) {
    final d = e.value.data;
    if (d == null || e.value.dict.contains('/Type0')) continue;
    final text = latin1.decode(d, allowInvalid: true);
    if (!text.contains(' Tf')) continue;
    Map<int, String>? map;
    for (final m in tokenRe.allMatches(text)) {
      if (m.group(1) != null) {
        map = cmaps[fontOf[m.group(1)!]];
        continue;
      }
      final hexes = m.group(2) != null
          ? RegExp(r'<([0-9A-Fa-f]*)>')
              .allMatches(m.group(2)!)
              .map((x) => x.group(1)!)
          : [m.group(3)!];
      final out = StringBuffer();
      for (final h in hexes) {
        for (var i = 0; i + 4 <= h.length; i += 4) {
          final gid = int.parse(h.substring(i, i + 4), radix: 16);
          out.write(map?[gid] ?? '?');
        }
      }
      runs.add(out.toString());
    }
  }
  return runs;
}

Map<int, String> _parseCmap(String cmap) {
  final map = <int, String>{};
  String uni(String hex) {
    final units = <int>[
      for (var i = 0; i + 4 <= hex.length; i += 4)
        int.parse(hex.substring(i, i + 4), radix: 16)
    ];
    return String.fromCharCodes(units);
  }

  for (final block in RegExp(r'beginbfchar(.*?)endbfchar', dotAll: true)
      .allMatches(cmap)) {
    for (final m in RegExp(r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>')
        .allMatches(block.group(1)!)) {
      map[int.parse(m.group(1)!, radix: 16)] = uni(m.group(2)!);
    }
  }
  for (final block in RegExp(r'beginbfrange(.*?)endbfrange', dotAll: true)
      .allMatches(cmap)) {
    for (final m in RegExp(r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>')
        .allMatches(block.group(1)!)) {
      final lo = int.parse(m.group(1)!, radix: 16);
      final hi = int.parse(m.group(2)!, radix: 16);
      final base = int.parse(m.group(3)!, radix: 16);
      for (var g = lo; g <= hi; g++) {
        map[g] = String.fromCharCode(base + g - lo);
      }
    }
  }
  return map;
}
