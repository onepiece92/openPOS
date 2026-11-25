import 'package:intl/intl.dart';

import 'package:pos_app/features/receipts/domain/receipt_labels.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';
import 'package:pos_app/features/orders/domain/order_number.dart';

String buildReceiptText(ReceiptBodyData data, CurrencyFormatter fmt) {
  final dateFmt = DateFormat('d MMM h:mm a');
  final o = data.order;
  final lines = <String>[
    data.businessName,
    'Bill ${o.billNo} · ${dateFmt.format(o.createdAt)}',
    if (data.customer != null) data.customer!.name else 'Walk-in',
    '',
    for (final i in data.items)
      '${i.productName} x${i.quantity} @ ${fmt.formatPlain(i.unitPrice)} = ${fmt.formatPlain(i.lineTotal)}',
    '',
    'Subtotal: ${fmt.format(o.subtotal)}',
    if (o.discountTotal > 0) 'Discount: -${fmt.format(o.discountTotal)}',
    // One row per tax, labelled like the printed receipt (inclusive tax is
    // marked as such). Orders with a tax total but no breakdown — CSV
    // imports — fall back to the single figure.
    if (data.taxes.isNotEmpty)
      for (final t in data.taxes)
        '${taxLineLabel(t)}: ${fmt.format(t.taxAmount)}'
    else if (o.taxTotal > 0)
      'Tax: ${fmt.format(o.taxTotal)}',
    if (o.loyaltyDiscount > 0)
      'Loyalty (${o.pointsRedeemed} pts): -${fmt.format(o.loyaltyDiscount)}',
    'Total: ${fmt.format(o.total)}',
    'Paid: ${o.paymentMethod}',
  ];
  return lines.join('\n');
}
