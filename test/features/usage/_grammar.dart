import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/domain/usage_summary.dart';

final _labels = FeatureArea.values.map((a) => RegExp.escape(a.label)).join('|');
final _events = UsageEvent.values.map((e) => e.name).join('|');
const _bucket = r'(0|1-10|11-50|51-200|200\+)';
const _month = r'\d{4}-\d{2}';

/// Every line a usage summary may contain outside the message section.
final kUsageLineGrammar = <RegExp>[
  RegExp('^${RegExp.escape(kUsageSummaryHeader)}\$'),
  RegExp('^Improve: ($_labels)(, ($_labels))*\$'),
  RegExp('^($_labels) usage:\$'),
  RegExp('^- ($_events): \\d+( \\($_month( to $_month)?\\))?\$'),
  RegExp(r'^App: Open POS (\d+(\.\d+)*(\+\d+)?|unknown), [a-z]{2,12}, '
      r'OS (\d{1,3}|unknown), locale ([A-Za-z]{2,3}(-[A-Za-z0-9]{2,8}){0,3}|unknown), '
      r'currency ([A-Z]{3}|other)$'),
  RegExp('^Shop size: products $_bucket, orders in last 7 days $_bucket, '
      'customers $_bucket\$'),
];

/// Splits [summary] into the fixed part and the shopkeeper's message (null
/// when there is none). The message is everything after the first
/// [kUsageMessageMarker] line.
({List<String> fixed, String? message}) splitSummary(String summary) {
  final lines = summary.split('\n');
  final i = lines.indexOf(kUsageMessageMarker);
  if (i < 0) return (fixed: lines, message: null);
  return (fixed: lines.sublist(0, i), message: lines.sublist(i + 1).join('\n'));
}

/// Every fixed line matches one grammar rule.
void expectGrammar(String summary) {
  final fixed = splitSummary(summary).fixed;
  expect(fixed.first, kUsageSummaryHeader);
  for (final line in fixed) {
    expect(kUsageLineGrammar.any((r) => r.hasMatch(line)), isTrue,
        reason: 'line not in the allow-list grammar: "$line"');
  }
}
