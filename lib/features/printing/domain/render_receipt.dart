import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';

/// Builds the ESC/POS byte stream for a sales receipt.
///
/// Pure function: takes data + format + paper width, returns the bytes.
/// Caller is responsible for transport (BT/USB/network).
///
/// `paperMm` must be 58 or 80. Other values fall back to 80mm.
Future<List<int>> renderReceiptBytes(
  ReceiptBodyData data,
  CurrencyFormatter fmt,
  int paperMm,
) async {
  final size = paperMm == 58 ? PaperSize.mm58 : PaperSize.mm80;
  final profile = await CapabilityProfile.load();
  final g = Generator(size, profile);
  final bytes = <int>[];

  bytes.addAll(g.reset());

  // ── Business name (centered, big) ──────────────────────────────────────
  bytes.addAll(g.text(
    data.businessName,
    styles: const PosStyles(
      align: PosAlign.center,
      bold: true,
      height: PosTextSize.size2,
      width: PosTextSize.size2,
    ),
  ));
  bytes.addAll(g.hr());

  // ── Customer + Bill no. ────────────────────────────────────────────────
  final customerName = data.customer?.name ?? 'Walk-in';
  bytes.addAll(g.row([
    PosColumn(text: customerName, width: 6),
    PosColumn(
      text: 'Bill #${data.order.id}',
      width: 6,
      styles: const PosStyles(align: PosAlign.right),
    ),
  ]));
  bytes.addAll(g.hr());

  // ── Items header ───────────────────────────────────────────────────────
  bytes.addAll(g.text('ITEMS', styles: const PosStyles(bold: true)));
  bytes.addAll(g.row([
    PosColumn(text: 'Name', width: 6, styles: const PosStyles(bold: true)),
    PosColumn(
      text: 'Qty',
      width: 2,
      styles: const PosStyles(bold: true, align: PosAlign.right),
    ),
    PosColumn(
      text: 'Total',
      width: 4,
      styles: const PosStyles(bold: true, align: PosAlign.right),
    ),
  ]));

  for (final item in data.items) {
    bytes.addAll(g.row([
      PosColumn(text: item.productName, width: 6),
      PosColumn(
        text: 'x${item.quantity}',
        width: 2,
        styles: const PosStyles(align: PosAlign.right),
      ),
      PosColumn(
        text: fmt.formatPlain(item.lineTotal),
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]));
  }

  bytes.addAll(g.hr());

  // ── Totals ─────────────────────────────────────────────────────────────
  bytes.addAll(_kv(g, 'Subtotal', fmt.format(data.order.subtotal)));
  if (data.order.discountTotal > 0) {
    bytes.addAll(
        _kv(g, 'Discount', '- ${fmt.format(data.order.discountTotal)}'));
  }
  for (final t in data.taxes) {
    final pct = (t.taxRatePercent * 100).toStringAsFixed(1);
    bytes.addAll(_kv(g, '${t.taxRateName} ($pct%)', fmt.format(t.taxAmount)));
  }
  bytes.addAll(g.hr(ch: '='));
  bytes.addAll(_kv(
    g,
    'TOTAL',
    fmt.format(data.order.total),
    bold: true,
  ));
  bytes.addAll(g.hr());

  // ── Payment ────────────────────────────────────────────────────────────
  final method = data.order.paymentMethod;
  final methodLabel = method.isEmpty
      ? method
      : '${method[0].toUpperCase()}${method.substring(1)}';
  bytes.addAll(_kv(g, 'Payment', methodLabel));
  if (data.order.tenderedAmount != null) {
    bytes.addAll(_kv(g, 'Tendered', fmt.format(data.order.tenderedAmount!)));
    bytes.addAll(_kv(g, 'Change', fmt.format(data.order.changeAmount ?? 0)));
  }

  // ── Loyalty (optional) ─────────────────────────────────────────────────
  if (data.customer != null) {
    bytes.addAll(g.hr());
    bytes.addAll(_kv(g, 'Loyalty Points', '${data.customer!.loyaltyPoints}'));
  }

  // ── Footer ─────────────────────────────────────────────────────────────
  bytes.addAll(g.feed(1));
  bytes.addAll(g.text(
    'Thank you!',
    styles: const PosStyles(align: PosAlign.center, bold: true),
  ));
  bytes.addAll(g.feed(2));
  bytes.addAll(g.cut());

  return bytes;
}

/// Builds the ESC/POS bytes for a small "test page" — used by the printer
/// setup screen to confirm a connection works without printing a real sale.
Future<List<int>> renderTestPageBytes({
  required String storeName,
  required int paperMm,
}) async {
  final size = paperMm == 58 ? PaperSize.mm58 : PaperSize.mm80;
  final profile = await CapabilityProfile.load();
  final g = Generator(size, profile);
  final bytes = <int>[];

  bytes.addAll(g.reset());
  bytes.addAll(g.text(
    storeName,
    styles: const PosStyles(
      align: PosAlign.center,
      bold: true,
      height: PosTextSize.size2,
      width: PosTextSize.size2,
    ),
  ));
  bytes.addAll(g.hr());
  bytes.addAll(g.text(
    'Printer Test',
    styles: const PosStyles(align: PosAlign.center),
  ));
  bytes.addAll(g.text(
    DateTime.now().toIso8601String(),
    styles: const PosStyles(align: PosAlign.center),
  ));
  bytes.addAll(g.text(
    'Paper: ${paperMm}mm',
    styles: const PosStyles(align: PosAlign.center),
  ));
  bytes.addAll(g.feed(1));
  bytes.addAll(g.text(
    'If you can read this clearly, your printer is ready.',
    styles: const PosStyles(align: PosAlign.center),
  ));
  bytes.addAll(g.feed(2));
  bytes.addAll(g.cut());

  return bytes;
}

List<int> _kv(Generator g, String label, String value, {bool bold = false}) {
  return g.row([
    PosColumn(text: label, width: 6, styles: PosStyles(bold: bold)),
    PosColumn(
      text: value,
      width: 6,
      styles: PosStyles(bold: bold, align: PosAlign.right),
    ),
  ]);
}
