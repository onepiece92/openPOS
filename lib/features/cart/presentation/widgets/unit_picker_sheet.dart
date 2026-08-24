import 'package:flutter/material.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/core/utils/money.dart';

/// Bottom sheet shown on long-pressing a product that has a secondary unit:
/// "add 1 pc" vs "add 1 dozen (12 pcs)". Pops with the chosen unit label
/// ('' = main unit) or null when dismissed.
class UnitPickerSheet extends StatelessWidget {
  const UnitPickerSheet({super.key, required this.product, required this.fmt});
  final Product product;
  final CurrencyFormatter fmt;

  static String _fmtRate(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final secondary = product.secondaryUnit!;
    final secondaryPrice = roundMoney(product.price * product.conversionRate);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(product.name, style: tt.titleMedium),
            ),
          ),
          ListTile(
            leading: Icon(Icons.straighten_rounded, color: cs.primary),
            title: Text('1 ${product.unit}'),
            subtitle: Text(fmt.format(product.price)),
            onTap: () => Navigator.pop(context, ''),
          ),
          ListTile(
            leading: Icon(Icons.all_inbox_outlined, color: cs.primary),
            title: Text('1 $secondary'),
            subtitle: Text(
              '${fmt.format(secondaryPrice)} · '
              '${_fmtRate(product.conversionRate)} ${product.unit}',
            ),
            onTap: () => Navigator.pop(context, secondary),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
