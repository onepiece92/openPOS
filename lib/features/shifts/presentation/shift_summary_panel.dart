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
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/core/utils/link_uris.dart';
import 'package:pos_app/core/utils/share_origin.dart';
import 'package:pos_app/features/backup/data/share_files.dart';
import 'package:pos_app/features/printing/domain/receipt_printer.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/usage/usage_providers.dart';

/// Shown when Print is tapped with no printer saved.
const kNoPrinterMessage =
    'No printer is set up. Go to Settings, then Printer, to add one.';

/// The lines of [text] to print, with the shop's currency symbol swapped
/// for its code when the receipt fonts can't draw it (the same rule as the
/// receipt: [receiptCurrencySymbol]). The stored text is never changed.
Future<List<String>> summaryPrintLines(
    String text, CurrencyFormatter fmt) async {
  final symbol = fmt.symbol.trim();
  final printable = await receiptCurrencySymbol(symbol, fmt.currencyCode);
  final out = symbol.isEmpty || printable == symbol
      ? text
      : text.replaceAll(symbol, printable);
  return out.split('\n');
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
    final fmt = ref.read(currencyFormatterProvider);
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
          await summaryPrintLines(text, fmt),
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
