import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

const kFeaturesScreenIntro =
    "Switch off what your shop doesn't use. Nothing is deleted: switch a "
    'feature back on and its data is still there.';

const kTaxesOffTitle = 'Turn off Taxes?';
const kTaxesOffBody =
    "New sales won't add tax, and neither will held tickets when you finish "
    'them. Your tax rates and default rate are kept, so they come back when '
    'you turn Taxes on again.';

String _tickets(int n) => n == 1 ? '1 saved ticket' : '$n saved tickets';

/// What switching [f] off would hide that is in use right now, as the
/// confirm text — null when nothing is (then it switches off at once).
/// [heldTickets]: active held tickets; [tableTickets]: tickets (held or
/// the open cart) with a table; [cartCustomer]: the open cart has one.
String? hideConfirmBody(Feature f,
    {int heldTickets = 0, int tableTickets = 0, bool cartCustomer = false}) {
  return switch (f) {
    Feature.taxes => kTaxesOffBody,
    Feature.heldTickets when heldTickets > 0 =>
      '${_tickets(heldTickets)} will be hidden until you turn this back on. '
          'Nothing is deleted.',
    Feature.tables when tableTickets > 0 =>
      '${tableTickets == 1 ? '1 open ticket has' : '$tableTickets open tickets have'} '
          'a table. Tables will be hidden until you turn this back on. '
          'Nothing is deleted.',
    Feature.customers when cartCustomer =>
      'The customer on the current sale will be hidden until you turn this '
          'back on. It is still saved with the sale.',
    _ => null,
  };
}

/// "Needs Customers" under a child whose parent is off.
String needsLine(Feature parent) => 'Needs ${parent.label}';

/// The recount line shown once Stock tracking is back on.
String stockRecountText(DateTime since) =>
    "Stock wasn't tracked from ${DateFormat('d MMM yyyy').format(since)}. "
    'Recount your stock.';

/// Text-only list: a name, one line on what it does, and a switch.
class FeaturesScreen extends ConsumerStatefulWidget {
  const FeaturesScreen({super.key});

  @override
  ConsumerState<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends ConsumerState<FeaturesScreen> {
  @override
  void initState() {
    super.initState();
    // Opening Features is the intro line's job done.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !ref.read(featuresIntroSeenProvider)) {
        ref.read(settingsProvider.notifier).markFeaturesIntroSeen();
      }
    });
  }

  /// Asks first when switching [f] off would hide live data (or, for
  /// Taxes, change the next sales). Reads the held tickets and the open
  /// cart only at that moment, and never creates a cart session.
  String? _confirmBody(Feature f) {
    final flags = ref.read(featureFlagsProvider);
    final session =
        ref.exists(cartSessionProvider) ? ref.read(cartSessionProvider) : null;
    var held = 0, withTable = 0;
    if (flags.heldTickets &&
        (f == Feature.heldTickets || (f == Feature.tables && flags.tables))) {
      final tickets = ref.read(activeHeldOrdersProvider);
      held = tickets.length;
      withTable = tickets.where((t) => t.tableId != null).length;
    }
    if (session?.tableId != null && !session!.isEditingHeldTicket) {
      withTable++;
    }
    return hideConfirmBody(f,
        heldTickets: held,
        tableTickets: f == Feature.tables && flags.tables ? withTable : 0,
        cartCustomer: f == Feature.customers &&
            flags.customers &&
            session?.customerId != null);
  }

  Future<void> _set(Feature f, bool on) async {
    final body = on ? null : _confirmBody(f);
    if (body != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
              f == Feature.taxes ? kTaxesOffTitle : 'Turn off ${f.label}?'),
          content: Text(body),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                key: f == Feature.taxes
                    ? const ValueKey('taxes-off-confirm')
                    : const ValueKey('feature-off-confirm'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Turn off')),
          ],
        ),
      );
      if (ok != true) return;
    }
    await ref.read(settingsProvider.notifier).setFeature(f, on);
  }

  @override
  Widget build(BuildContext context) {
    final flags = ref.watch(featureFlagsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(title: const Text('Features')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(kFeaturesScreenIntro,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ),
          for (final f in Feature.values) ...[
            _FeatureRow(feature: f, flags: flags, onChanged: _set),
            if (f == Feature.stockTracking && flags.stockTracking)
              const StockRecountLine(indent: 32),
          ],
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(
      {required this.feature, required this.flags, required this.onChanged});
  final Feature feature;
  final FeatureFlags flags;
  final Future<void> Function(Feature, bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final parent = feature.parent;
    final blocked = parent != null && !flags.isOn(parent);
    return SwitchListTile(
      key: ValueKey('feature-${feature.name}'),
      contentPadding:
          EdgeInsets.only(left: parent == null ? 16 : 32, right: 16),
      title: Text(feature.label),
      subtitle: Text(blocked ? needsLine(parent) : feature.description),
      value: flags.stored(feature),
      onChanged: blocked ? null : (v) => onChanged(feature, v),
    );
  }
}

/// "Stock wasn't tracked from …" with a Done button. Builds nothing unless
/// Stock tracking was switched off at some point and the line has not been
/// dismissed. Also shown at the top of Inventory.
class StockRecountLine extends ConsumerWidget {
  const StockRecountLine({super.key, this.indent = 16});
  final double indent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final since = ref.watch(stockOffSinceProvider);
    if (since == null || !ref.watch(featureOnProvider(Feature.stockTracking))) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    return Padding(
      key: const ValueKey('stock-recount'),
      padding: EdgeInsets.fromLTRB(indent, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(stockRecountText(since),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.error)),
          ),
          TextButton(
            onPressed: () =>
                ref.read(settingsProvider.notifier).dismissStockRecount(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
