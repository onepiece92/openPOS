import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/font/ttf_parser.dart';

/// Original entries whose symbols are missing from the bundled JetBrains Mono.
/// Frozen: new entries must never be added here.
const _knownMissingGlyphCodes = {'BD', 'GH', 'IN', 'KR', 'NG', 'PH', 'TH'};

List<Map<String, dynamic>> _load() => (jsonDecode(
      File('assets/locales/country_defaults.json').readAsStringSync(),
    ) as List)
    .cast<Map<String, dynamic>>();

Set<int> _cmap(String path) {
  final b = File(path).readAsBytesSync();
  final parser = TtfParser(ByteData.view(Uint8List.fromList(b).buffer));
  return parser.charToGlyphIndexMap.keys.toSet();
}

void main() {
  final entries = _load();

  test('codes are unique, 2 uppercase letters', () {
    final codes = entries.map((e) => e['code'] as String).toList();
    expect(codes.toSet().length, codes.length);
    for (final c in codes) {
      expect(RegExp(r'^[A-Z]{2}$').hasMatch(c), isTrue, reason: c);
    }
  });

  test('currency, symbol, name, tax name, timezone, rate are sane', () {
    for (final e in entries) {
      final c = e['code'];
      expect(RegExp(r'^[A-Z]{3}$').hasMatch(e['currency'] as String), isTrue,
          reason: '$c currency');
      expect((e['symbol'] as String).isNotEmpty, isTrue, reason: '$c symbol');
      expect((e['name'] as String).trim().isNotEmpty, isTrue, reason: '$c name');
      expect((e['taxName'] as String).trim().isNotEmpty, isTrue,
          reason: '$c taxName');
      expect(
        RegExp(r'^[A-Za-z_]+(/[A-Za-z_]+){1,2}$')
            .hasMatch(e['timezone'] as String),
        isTrue,
        reason: '$c timezone',
      );
      final r = (e['taxRate'] as num).toDouble();
      expect(r >= 0 && r <= 30, isTrue, reason: '$c taxRate $r');
    }
  });

  test('every symbol code point exists in the bundled fonts', () {
    final fonts = [
      'assets/fonts/JetBrainsMono-Regular.ttf',
      'assets/fonts/JetBrainsMono-Bold.ttf',
    ].map(_cmap).toList();
    for (final e in entries) {
      final code = e['code'] as String;
      if (_knownMissingGlyphCodes.contains(code)) continue;
      for (final cp in (e['symbol'] as String).runes) {
        for (final cmap in fonts) {
          expect(cmap.contains(cp), isTrue,
              reason: '$code symbol U+${cp.toRadixString(16)} not in font');
        }
      }
    }
  });

  test('known-missing allowlist is accurate and limited to original codes', () {
    final cmap = _cmap('assets/fonts/JetBrainsMono-Regular.ttf');
    for (final e in entries) {
      final code = e['code'] as String;
      final missing =
          (e['symbol'] as String).runes.any((r) => !cmap.contains(r));
      expect(missing, _knownMissingGlyphCodes.contains(code), reason: code);
    }
  });
}
