import 'package:flutter/material.dart';

// ─── Discount sheet ───────────────────────────────────────────────────────────

class DiscountSheet extends StatefulWidget {
  const DiscountSheet({super.key, 
    required this.currentDiscount,
    required this.isPercent,
    required this.subtotal,
    required this.onApply,
  });
  final double currentDiscount;
  final bool isPercent;
  final double subtotal;
  final void Function(double amount, bool isPercent) onApply;

  @override
  State<DiscountSheet> createState() => _DiscountSheetState();
}

class _DiscountSheetState extends State<DiscountSheet> {
  late bool _isPercent;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _isPercent = widget.isPercent;
    _ctrl = TextEditingController(
      text: widget.currentDiscount > 0
          ? widget.currentDiscount.toStringAsFixed(
              widget.isPercent ? 1 : 2)
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _parsed => double.tryParse(_ctrl.text) ?? 0.0;

  double get _preview {
    if (_isPercent) return widget.subtotal * (_parsed / 100);
    return _parsed.clamp(0.0, widget.subtotal);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Order Discount', style: tt.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Flat amount')),
              ButtonSegment(value: true, label: Text('Percentage (%)')),
            ],
            selected: {_isPercent},
            onSelectionChanged: (s) => setState(() {
              _isPercent = s.first;
              _ctrl.clear();
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _isPercent ? 'Discount %' : 'Discount amount',
              suffixText: _isPercent ? '%' : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_parsed > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text('Discount applied:',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  const Spacer(),
                  Text(
                    '− ${_preview.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: cs.error),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              if (widget.currentDiscount > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onApply(0, false);
                      Navigator.pop(context);
                    },
                    child: const Text('Remove'),
                  ),
                ),
              if (widget.currentDiscount > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _parsed <= 0
                      ? null
                      : () {
                          widget.onApply(_parsed, _isPercent);
                          Navigator.pop(context);
                        },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
