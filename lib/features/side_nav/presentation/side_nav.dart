import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PosDrawer extends StatelessWidget {
  const PosDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final location = GoRouterState.of(context).uri.path;

    return NavigationDrawer(
      onDestinationSelected: (i) {
        Navigator.of(context).pop(); // close drawer
        context.go(_routes[i]);
      },
      selectedIndex: _indexFor(location),
      children: [
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
                  style: tt.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text('Point of Sale',
                  style: tt.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        const Divider(indent: 20, endIndent: 20, height: 8),
        const SizedBox(height: 4),

        // ── Sell ────────────────────────────────────────────────────────────
        _label('Sell', tt, cs),
        const NavigationDrawerDestination(
          icon: Icon(Icons.grid_view_rounded),
          label: Text('POS'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.receipt_long_rounded),
          label: Text('Orders'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.people_rounded),
          label: Text('Customers'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.table_restaurant_rounded),
          label: Text('Tables'),
        ),

        const SizedBox(height: 4),
        const Divider(indent: 20, endIndent: 20, height: 8),

        // ── Catalogue ───────────────────────────────────────────────────────
        _label('Catalogue', tt, cs),
        const NavigationDrawerDestination(
          icon: Icon(Icons.inventory_2_rounded),
          label: Text('Products'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.category_rounded),
          label: Text('Categories'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.warehouse_rounded),
          label: Text('Inventory'),
        ),

        const SizedBox(height: 4),
        const Divider(indent: 20, endIndent: 20, height: 8),

        // ── Finance ─────────────────────────────────────────────────────────
        _label('Finance', tt, cs),
        const NavigationDrawerDestination(
          icon: Icon(Icons.bar_chart_rounded),
          label: Text('Reports'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.account_balance_wallet_rounded),
          label: Text('Expenses'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.percent_rounded),
          label: Text('Tax'),
        ),

        const SizedBox(height: 4),
        const Divider(indent: 20, endIndent: 20, height: 8),

        // ── System ──────────────────────────────────────────────────────────
        _label('System', tt, cs),
        const NavigationDrawerDestination(
          icon: Icon(Icons.settings_rounded),
          label: Text('Settings'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.policy_rounded),
          label: Text('Audit Log'),
        ),

        const SizedBox(height: 4),
        const Divider(indent: 20, endIndent: 20, height: 8),

        // ── Help ────────────────────────────────────────────────────────────
        _label('Help', tt, cs),
        const NavigationDrawerDestination(
          icon: Icon(Icons.headset_mic_outlined),
          label: Text('Support'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.school_outlined),
          label: Text('Learn'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.keyboard_outlined),
          label: Text('Shortcuts'),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

const List<String> _routes = [
  '/pos',
  '/orders',
  '/customers',
  '/tables',
  '/products',
  '/categories',
  '/inventory',
  '/reports',
  '/expenses',
  '/tax',
  '/settings',
  '/audit',
  '/help/support',
  '/help/learn',
  '/help/shortcuts',
];

int? _indexFor(String location) {
  final i = _routes.indexWhere((r) => location.startsWith(r));
  return i >= 0 ? i : null;
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
