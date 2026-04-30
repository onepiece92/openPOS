import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/theme/tokens.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';

// ─── Data bundle (public) ─────────────────────────────────────────────────────

class ReceiptBodyData {
  const ReceiptBodyData({
    required this.order,
    required this.items,
    required this.taxes,
    required this.businessName,
    this.customer,
    this.table,
  });
  final Order order;
  final List<OrderItem> items;
  final List<OrderTaxe> taxes;
  final String businessName;
  final Customer? customer;
  final PosTable? table;
}

// ─── Reusable receipt body ────────────────────────────────────────────────────

class ReceiptBody extends StatelessWidget {
  const ReceiptBody({super.key, required this.data, required this.fmt});
  final ReceiptBodyData data;
  final CurrencyFormatter fmt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final order = data.order;
    final dateFmt = DateFormat('MM/dd/yyyy hh:mm:ss a');
    final customerName = data.customer?.name ?? 'Walk-in';
    final symbolLabel = fmt.symbol.trim();

    const bodyStyle = TextStyle(fontSize: 13.5, height: 1.5, fontFamily: AppFonts.mono);
    const labelStyle = TextStyle(
        fontSize: 13.5, height: 1.5, color: Color(0xFF666666), fontFamily: AppFonts.mono);
    const boldStyle = TextStyle(
        fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w700, fontFamily: AppFonts.mono);
    const headerStyle = TextStyle(
        fontSize: 14, fontWeight: FontWeight.w700, height: 1.6, fontFamily: AppFonts.mono);

    final divider = Divider(height: 20, thickness: 0.8, color: cs.outlineVariant);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: DefaultTextStyle(
            style: bodyStyle.copyWith(color: cs.onSurface),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Business name ─────────────────────────────────────────
                Text(
                  'Business Name: ${data.businessName}',
                  textAlign: TextAlign.center,
                  style: boldStyle.copyWith(fontSize: 16, color: cs.onSurface),
                ),
                const SizedBox(height: 14),
                divider,

                // ── Customer + Bill number ────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(customerName,
                          style: bodyStyle.copyWith(color: cs.onSurface)),
                    ),
                    Text(
                      'Paid Bill No.: ${order.id}',
                      style: bodyStyle.copyWith(color: cs.onSurface),
                    ),
                  ],
                ),
                if (data.table != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Table: ${data.table!.name}',
                      style: bodyStyle.copyWith(color: cs.onSurface),
                    ),
                  ),
                divider,

                // ── Items section ─────────────────────────────────────────
                Text('Items Ordered',
                    style: headerStyle.copyWith(color: cs.onSurface)),
                const SizedBox(height: 6),

                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text('Name',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              color: cs.onSurface)),
                    ),
                    _HeaderCell('Qty'),
                    _HeaderCell('Rate ($symbolLabel)'),
                    _HeaderCell('Amt ($symbolLabel)'),
                  ],
                ),
                const SizedBox(height: 4),

                ...data.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(item.productName,
                                style: bodyStyle.copyWith(color: cs.onSurface)),
                          ),
                          _DataCell('x ${item.quantity}'),
                          _DataCell(fmt.formatPlain(item.unitPrice)),
                          _DataCell(fmt.formatPlain(item.lineTotal)),
                        ],
                      ),
                    )),

                divider,

                // ── Subtotals block ───────────────────────────────────────
                _BillRow(
                  label: 'Total',
                  value: fmt.format(order.subtotal),
                  labelStyle: labelStyle.copyWith(color: cs.onSurface),
                  valueStyle: bodyStyle.copyWith(color: cs.onSurface),
                ),
                _BillRow(
                  label: 'Discount',
                  value: fmt.format(order.discountTotal),
                  labelStyle: labelStyle.copyWith(color: cs.onSurface),
                  valueStyle: bodyStyle.copyWith(color: cs.onSurface),
                ),
                if (data.taxes.isNotEmpty) ...[
                  ...data.taxes.map((t) => _BillRow(
                        label:
                            '${t.taxRateName} (${(t.taxRatePercent * 100).toStringAsFixed(1)}%)',
                        value: fmt.format(t.taxAmount),
                        labelStyle: labelStyle.copyWith(color: cs.onSurface),
                        valueStyle: bodyStyle.copyWith(color: cs.onSurface),
                      )),
                ],
                divider,

                // ── Grand total ───────────────────────────────────────────
                _BillRow(
                  label: 'Grand Total',
                  value: fmt.format(order.total),
                  labelStyle: boldStyle.copyWith(color: cs.onSurface),
                  valueStyle: boldStyle.copyWith(color: cs.onSurface),
                ),
                divider,

                // ── Payment info ──────────────────────────────────────────
                Text('Payment',
                    style: headerStyle.copyWith(color: cs.onSurface)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Payment Mode: ${order.paymentMethod[0].toUpperCase()}${order.paymentMethod.substring(1)}',
                        style: bodyStyle.copyWith(color: cs.onSurface),
                      ),
                    ),
                    Text(
                      dateFmt.format(order.createdAt),
                      style: labelStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                if (order.tenderedAmount != null) ...[
                  const SizedBox(height: 4),
                  _BillRow(
                    label: 'Cash Tendered',
                    value: fmt.format(order.tenderedAmount!),
                    labelStyle: labelStyle.copyWith(color: cs.onSurface),
                    valueStyle: bodyStyle.copyWith(color: cs.onSurface),
                  ),
                  _BillRow(
                    label: 'Change',
                    value: fmt.format(order.changeAmount ?? 0),
                    labelStyle: labelStyle.copyWith(color: cs.onSurface),
                    valueStyle: bodyStyle.copyWith(color: cs.onSurface),
                  ),
                ],
                divider,

                // ── Loyalty points ────────────────────────────────────────
                if (data.customer != null) ...[
                  Text('Loyalty Points',
                      style: headerStyle.copyWith(color: cs.onSurface)),
                  const SizedBox(height: 6),
                  _BillRow(
                    label: 'Current',
                    value: '${data.customer!.loyaltyPoints}',
                    labelStyle: labelStyle.copyWith(color: cs.onSurface),
                    valueStyle: bodyStyle.copyWith(color: cs.onSurface),
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  const SizedBox(height: 16),
                ],

                Center(
                  child: Text(
                    'Thank you for your purchase!',
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Private helpers ──────────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 72,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: AppFonts.mono,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          color: cs.onSurface,
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 72,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(fontFamily: AppFonts.mono, fontSize: 13.5, color: cs.onSurface),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(label, style: labelStyle),
            const Spacer(),
            Text(value, style: valueStyle),
          ],
        ),
      );
}
