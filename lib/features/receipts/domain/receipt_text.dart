import 'package:intl/intl.dart';

import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';

String buildReceiptText(ReceiptBodyData data, CurrencyFormatter fmt) {
  final dateFmt = DateFormat('d MMM h:mm a');
  final o = data.order;
  final lines = <String>[
    data.businessName,
    'Order #${o.id} · ${dateFmt.format(o.createdAt)}',
    if (data.customer != null) data.customer!.name else 'Walk-in',
    '',
    for (final i in data.items)
      '${i.productName} x${i.quantity} @ ${fmt.formatPlain(i.unitPrice)} = ${fmt.formatPlain(i.lineTotal)}',
    '',
    'Subtotal: ${fmt.format(o.subtotal)}',
    if (o.discountTotal > 0) 'Discount: -${fmt.format(o.discountTotal)}',
    if (o.taxTotal > 0) 'Tax: ${fmt.format(o.taxTotal)}',
    'Total: ${fmt.format(o.total)}',
    'Paid: ${o.paymentMethod}',
  ];
  return lines.join('\n');
}
