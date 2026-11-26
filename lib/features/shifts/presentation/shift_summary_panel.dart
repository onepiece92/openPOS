import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' show XFile;

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/theme/tokens.dart';
import 'package:pos_app/core/utils/async_feedback.dart';
import 'package:pos_app/core/utils/bundled_fonts.dart';
import 'package:pos_app/core/utils/link_uris.dart';
import 'package:pos_app/core/utils/share_origin.dart';
import 'package:pos_app/features/backup/data/share_files.dart';
import 'package:pos_app/features/printing/domain/receipt_printer.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/usage/usage_providers.dart';

/// Shown when Print is tapped with no printer saved. Names the real row:
/// Settings → Hardware → Thermal Printer.
const kNoPrinterMessage = 'No printer is set up. Go to Settings, then '
    'Thermal Printer under Hardware, to add one.';

/// The currency symbol the frozen [text] was written with, read back from
/// its "Opening cash" line (always present, always money), or null.
String? frozenSummarySymbol(String text) {
  for (final line in text.split('\n')) {
    if (!line.startsWith('Opening cash')) continue;
    final value = line.substring('Opening cash'.length).trim();
    final symbol = value
        .replaceFirst(RegExp(r'^-'), '')
        .replaceFirst(RegExp(r'[\d.,]+$'), '')
        .trim();
    return symbol.isEmpty ? null : symbol;
  }
  return null;
}

/// The paper width the frozen [text] was laid out for: its `====` rule.
int frozenSummaryColumns(String text) {
  var cols = 0;
  for (final line in text.split('\n')) {
    if (line.isNotEmpty && RegExp(r'^=+$').hasMatch(line)) {
      cols = line.length > cols ? line.length : cols;
    }
  }
  return cols == 0 ? 32 : cols;
}

/// The lines of the frozen summary [text] to print.
///
/// The symbol is the one stored in the summary ([frozenSummarySymbol]),
/// not today's setting. When the receipt fonts can't draw it it is
/// swapped for [currencyCode] (the receipt rule, [receiptCurrencySymbol]),
/// and every money line is padded again to the summary's own width, so
/// the right edges stay aligned and no line grows past the paper (which
/// would shrink the font). The stored text is never changed.
Future<List<String>> summaryPrintLines(String text,
    {String? currencyCode}) async {
  final lines = text.split('\n');
  final symbol = frozenSummarySymbol(text);
  if (symbol == null) return lines;
  final printable = await receiptCurrencySymbol(symbol, currencyCode);
  if (printable == symbol) return lines;

  final columns = frozenSummaryColumns(text);
  final money = RegExp(
      '^(.*?) +(-?${RegExp.escape(symbol)}\\s?[\\d.,]+)\$');
  return [
    for (final line in lines)
      if (!line.contains(symbol))
        line
      else if (money.firstMatch(line) case final m?)
        _padRow(m.group(1)!, m.group(2)!.replaceFirst(symbol, printable),
            columns)
      else
        line.replaceAll(symbol, printable),
  ];
}

/// [label] and [value] across [columns], the value flush right; the label
/// is cut if both don't fit (as `buildShiftSummary` does).
String _padRow(String label, String value, int columns) {
  final room = columns - value.length - 1;
  var l = label;
  if (l.length > room) l = room > 0 ? l.substring(0, room) : '';
  final pad = columns - l.length - value.length;
  return '$l${' ' * (pad < 1 ? 1 : pad)}$value';
}

/// The frozen summary text in monospace, with Print, Share, Email and Copy.
/// Nothing prints by itself.
class ShiftSummaryPanel extends ConsumerWidget {
  const ShiftSummaryPanel(
      {super.key, required this.text, required this.subject});

  final String text;

  /// Subject line for Share and Email, e.g. "End of day, 10 Jun 2026".
  final String subject;

  Future<void> _print(BuildContext context, WidgetRef ref) async {
    final address = ref.read(printerDeviceAddressProvider);
    final name = ref.read(printerDeviceNameProvider);
    final paper = ref.read(printerPaperWidthProvider);
    final printer = ref.read(receiptPrinterProvider);
    final code = ref.read(currencyFormatterProvider).currencyCode;
    if (address == null || name == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(kNoPrinterMessage)));
      return;
    }
    await withErrorSnackbar(
      context,
      () async {
        await printer.printTextSlip(
          PrinterTarget(address: address, name: name),
          await summaryPrintLines(text, currencyCode: code),
          paperMm: paper,
        );
        return true;
      },
      successMessage: 'Sent to $name',
      failurePrefix: 'Print failed',
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final origin = shareOriginFor(context);
    final share = ref.read(shareFilesProvider);
    final tempDir = ref.read(usageTempDirProvider);
    await withErrorSnackbar(
      context,
      () async {
        final dir = await tempDir();
        final file = File('${dir.path}/end-of-day.txt');
        file.writeAsBytesSync(utf8.encode(text), flush: true);
        await share([XFile(file.path, mimeType: 'text/plain')],
            subject: subject, sharePositionOrigin: origin);
        return true;
      },
      failurePrefix: 'Share failed',
    );
  }

  Future<void> _email(BuildContext context, WidgetRef ref) async {
    final launch = ref.read(linkLauncherProvider);
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok =
          await launch(Uri.parse(mailtoLink('', subject: subject, body: text)));
    } catch (_) {}
    if (!ok) {
      await Clipboard.setData(ClipboardData(text: text));
      messenger.showSnackBar(const SnackBar(
          content: Text('No email app found. The summary was copied.')));
    }
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Summary copied')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              text,
              key: const ValueKey('summary-text'),
              style: const TextStyle(
                  fontFamily: AppFonts.mono,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: 11),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const ValueKey('summary-print'),
              icon: const Icon(Icons.print_rounded),
              label: const Text('Print'),
              onPressed: () => _print(context, ref),
            ),
            Builder(
              builder: (bctx) => OutlinedButton.icon(
                key: const ValueKey('summary-share'),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Share'),
                onPressed: () => _share(bctx, ref),
              ),
            ),
            OutlinedButton.icon(
              key: const ValueKey('summary-email'),
              icon: const Icon(Icons.email_outlined),
              label: const Text('Email'),
              onPressed: () => _email(context, ref),
            ),
            OutlinedButton.icon(
              key: const ValueKey('summary-copy'),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy'),
              onPressed: () => _copy(context),
            ),
          ],
        ),
      ],
    );
  }
}
