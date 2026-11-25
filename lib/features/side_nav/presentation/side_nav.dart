import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/providers/hive_provider.dart';

/// One drawer destination. [feature] set = shown only while it is on.
class NavEntry {
  const NavEntry(this.group, this.route, this.label, this.icon, [this.feature]);
  final String group;
  final String route;
  final String label;
  final IconData icon;
  final Feature? feature;
}

/// THE drawer: every destination once, in order. The drawer filters it
/// once per build and both draws and routes from the filtered list, so a
/// hidden item can never shift a tap onto the wrong route.
const kNavEntries = <NavEntry>[
  NavEntry('Sell', '/pos', 'POS', Icons.grid_view_rounded),
  NavEntry('Sell', '/orders', 'Orders', Icons.receipt_long_rounded),
  NavEntry('Sell', '/customers', 'Customers', Icons.people_rounded,
      Feature.customers),
  NavEntry('Sell', '/tables', 'Tables', Icons.table_restaurant_rounded,
      Feature.tables),
  NavEntry('Catalogue', '/products', 'Products', Icons.inventory_2_rounded),
  NavEntry('Catalogue', '/categories', 'Categories', Icons.category_rounded),
  NavEntry('Catalogue', '/inventory', 'Inventory', Icons.warehouse_rounded,
      Feature.stockTracking),
  NavEntry('Finance', '/reports', 'Reports', Icons.bar_chart_rounded),
  NavEntry('Finance', '/expenses', 'Expenses',
      Icons.account_balance_wallet_rounded, Feature.expenses),
  NavEntry('Finance', '/tax', 'Tax', Icons.percent_rounded, Feature.taxes),
  NavEntry('System', '/features', 'Features', Icons.toggle_on_outlined),
  NavEntry('System', '/settings', 'Settings', Icons.settings_rounded),
  NavEntry('System', '/audit', 'Audit Log', Icons.policy_rounded),
  NavEntry('Help', '/help/support', 'Support', Icons.headset_mic_outlined),
  NavEntry('Help', '/help/learn', 'Learn', Icons.school_outlined),
  NavEntry('Help', '/help/shortcuts', 'Shortcuts', Icons.keyboard_outlined),
];

/// The drawer destinations for [flags], in order.
List<NavEntry> visibleNavEntries(FeatureFlags flags) => [
      for (final e in kNavEntries)
        if (e.feature == null || flags.isOn(e.feature!)) e,
    ];

/// The feature a location belongs to, if it is one that can be switched
/// off (the router sends those to /pos while off).
Feature? featureForLocation(String path) {
  for (final e in kNavEntries) {
    final f = e.feature;
    if (f != null && (path == e.route || path.startsWith('${e.route}/'))) {
      return f;
    }
  }
  return null;
}

/// Where the router sends [location] under [flags]: /pos for a
/// switched-off feature's screen, otherwise nowhere (null).
String? featureRedirect(FeatureFlags flags, String location) {
  final f = featureForLocation(location);
  return f != null && !flags.isOn(f) ? '/pos' : null;
}

/// Index in [entries] of the destination [location] is on, if any.
int? selectedNavIndex(List<NavEntry> entries, String location) {
  for (var i = 0; i < entries.length; i++) {
    final r = entries[i].route;
    if (location == r || location.startsWith('$r/')) return i;
  }
  return null;
}

/// Text of the one-time drawer line shown after an upgrade.
const kFeaturesIntroText = 'New: turn features on or off in Features';

/// The same line for a fresh install that skipped setup's suggestions.
const kFeaturesIntroFreshText = 'Turn features on or off any time in Features';

class PosDrawer extends ConsumerWidget {
  const PosDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final location = GoRouterState.of(context).uri.path;
    final entries = visibleNavEntries(ref.watch(featureFlagsProvider));
    final introSeen = ref.watch(featuresIntroSeenProvider);

    final children = <Widget>[
      // ── Header ──────────────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                context.go('/pos');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.point_of_sale_rounded,
                    color: cs.onPrimaryContainer, size: 24),
              ),
            ),
            const SizedBox(height: 12),
            Text('POS',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text('Point of Sale',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
      if (!introSeen) const _FeaturesIntroLine(),
    ];

    String? group;
    for (final e in entries) {
      if (e.group != group) {
        const divider = Divider(indent: 20, endIndent: 20, height: 8);
        const gap = SizedBox(height: 4);
        children
          ..addAll(group == null ? const [divider, gap] : const [gap, divider])
          ..add(_label(e.group, tt, cs));
        group = e.group;
      }
      children.add(NavigationDrawerDestination(
        key: ValueKey('nav-${e.route}'),
        icon: Icon(e.icon),
        label: Text(e.label),
      ));
    }
    children.add(const SizedBox(height: 16));

    return NavigationDrawer(
      onDestinationSelected: (i) {
        Navigator.of(context).pop(); // close drawer
        context.go(entries[i].route);
      },
      selectedIndex: selectedNavIndex(entries, location),
      children: children,
    );
  }
}

class _FeaturesIntroLine extends ConsumerWidget {
  const _FeaturesIntroLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final fresh = ref.watch(featuresIntroFreshProvider);
    void seen() => ref.read(settingsProvider.notifier).markFeaturesIntroSeen();
    return Padding(
      key: const ValueKey('features-intro'),
      padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                seen();
                Navigator.of(context).pop();
                context.go('/features');
              },
              child: Text(fresh ? kFeaturesIntroFreshText : kFeaturesIntroText,
                  style: tt.bodyMedium),
            ),
          ),
          TextButton(
            key: const ValueKey('features-intro-dismiss'),
            onPressed: seen,
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}

Widget _label(String text, TextTheme tt, ColorScheme cs) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        text.toUpperCase(),
        style: tt.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
