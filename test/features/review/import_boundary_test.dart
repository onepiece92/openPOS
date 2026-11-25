import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The FOSS build swaps `in_app_review` for a stub; keeping the import in a
/// single file keeps that swap (and its API surface) small.
void main() {
  test('only store_review_prompter.dart imports in_app_review', () {
    final importers = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) =>
            f.readAsStringSync().contains("package:in_app_review/"))
        .map((f) => f.path.replaceAll(r'\', '/'))
        .toList();
    expect(importers, ['lib/features/review/data/store_review_prompter.dart']);
  });
}
