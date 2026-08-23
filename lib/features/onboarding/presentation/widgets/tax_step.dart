import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TaxStep extends StatelessWidget {
  const TaxStep({
    super.key,
    required this.nameController,
    required this.rateController,
    required this.currencySymbol,
  });

  final TextEditingController nameController;
  final TextEditingController rateController;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.percent_rounded,
                size: 44,
                color: cs.onTertiaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Set up your tax rate',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ve pre-filled values from your selected country. You can customise them here.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Tax name',
              hintText: 'e.g. VAT, GST, Sales Tax',
              prefixIcon: Icon(Icons.label_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: rateController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Tax rate (%)',
              hintText: '13.0',
              prefixIcon: Icon(Icons.percent_rounded),
              border: OutlineInputBorder(),
              suffixText: '%',
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tax is calculated as exclusive — added on top of the item price.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 3: Confirm ──────────────────────────────────────────────────────────
