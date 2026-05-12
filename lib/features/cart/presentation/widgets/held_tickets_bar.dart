import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:pos_app/core/theme/tron_border.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/shared/widgets/app_sheet.dart';
import 'package:pos_app/shared/widgets/customer_avatar.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';
import 'package:pos_app/features/customers/domain/customers_provider.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';

enum _ResumeAction { cancel, save, discard }

// ─── Held tickets bar (bottomNavigationBar slot) ──────────────────────────────

class HeldTicketsBar extends ConsumerStatefulWidget {
  const HeldTicketsBar({super.key});

  @override
  ConsumerState<HeldTicketsBar> createState() => _HeldTicketsBarState();
}

class _HeldTicketsBarState extends ConsumerState<HeldTicketsBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeHeldOrdersProvider);
    if (active.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final count = active.length;
    final dark = cs.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: InkWell(
          onTap: () => showAppSheet(
            context: context,
            draggable: true,
            initialSize: 0.5,
            builder: (_) => const _HeldTicketsSheet(),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: dark
                      ? cs.secondary.withValues(alpha: 0.12)
                      : cs.secondary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pause_circle_rounded,
                        size: 18, color: cs.secondary),
                    const SizedBox(width: 8),
                    Text(
                      '$count held ${count == 1 ? 'ticket' : 'tickets'}',
                      style: tt.labelMedium?.copyWith(
                        color: cs.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Tap to resume →',
                      style: tt.labelSmall?.copyWith(
                        color: cs.secondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => CustomPaint(
                    painter: TronBorderPainter(_ctrl.value),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Held tickets sheet ───────────────────────────────────────────────────────

class _HeldTicketsSheet extends ConsumerStatefulWidget {
  const _HeldTicketsSheet();

  @override
  ConsumerState<_HeldTicketsSheet> createState() => _HeldTicketsSheetState();
}

class _HeldTicketsSheetState extends ConsumerState<_HeldTicketsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeHeldOrdersProvider);
    final archived = ref.watch(archivedHeldOrdersProvider);
    final fmt = ref.watch(currencyFormatterProvider);
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMM  HH:mm');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text('Held Tickets',
              style: Theme.of(context).textTheme.titleLarge),
        ),
        TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(text: 'Active (${active.length})'),
            Tab(text: 'Archived (${archived.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              // ── Active tab ──────────────────────────────────────
              _buildActiveList(context, active, fmt, cs, dateFmt),
              // ── Archived tab ────────────────────────────────────
              _buildArchivedList(context, archived, fmt, cs, dateFmt),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveList(BuildContext ctx, List<HeldOrder> active,
      CurrencyFormatter fmt, ColorScheme cs, DateFormat dateFmt) {
    if (active.isEmpty) {
      return Center(
        child: Text('No held tickets',
            style: TextStyle(color: cs.onSurfaceVariant)),
      );
    }
    return ListView.separated(
      itemCount: active.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (_, i) {
        // ── Archive all footer ──────────────────────────────
        if (i == active.length) {
          return ListTile(
            leading:
                Icon(Icons.archive_rounded, color: cs.onSurfaceVariant),
            title: Text('Archive all tickets',
                style: TextStyle(color: cs.onSurfaceVariant)),
            onTap: () {
              ref.read(heldOrdersProvider.notifier).archiveAll();
            },
          );
        }
        final ticket = active[i];
        return ListTile(
          leading: CustomerAvatar(
            name: ticket.customerName,
            fallbackIcon: Icons.pause_rounded,
          ),
          title: Text(ticket.label),
          subtitle: Text(
            '${ticket.itemCount} items · '
            '${fmt.format(ticket.subtotal)} · '
            '${dateFmt.format(ticket.createdAt)}',
          ),
          trailing: IconButton(
            icon: Icon(Icons.archive_outlined, color: cs.onSurfaceVariant),
            tooltip: 'Archive',
            onPressed: () =>
                ref.read(heldOrdersProvider.notifier).archive(ticket.id),
          ),
          onTap: () => _resume(ctx, ref, ticket),
        );
      },
    );
  }

  Widget _buildArchivedList(BuildContext ctx, List<HeldOrder> archived,
      CurrencyFormatter fmt, ColorScheme cs, DateFormat dateFmt) {
    if (archived.isEmpty) {
      return Center(
        child: Text('No archived tickets',
            style: TextStyle(color: cs.onSurfaceVariant)),
      );
    }
    return ListView.separated(
      itemCount: archived.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (_, i) {
        // ── Clear all archived footer ───────────────────────
        if (i == archived.length) {
          return ListTile(
            leading:
                Icon(Icons.delete_sweep_rounded, color: cs.error),
            title: Text('Delete all archived',
                style: TextStyle(color: cs.error)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: ctx,
                builder: (dCtx) => AlertDialog(
                  title: const Text('Delete all archived?'),
                  content: Text(
                    'This will permanently delete ${archived.length} archived ${archived.length == 1 ? 'ticket' : 'tickets'}.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dCtx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.error,
                        foregroundColor: cs.onError,
                      ),
                      onPressed: () => Navigator.pop(dCtx, true),
                      child: const Text('Delete all'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(heldOrdersProvider.notifier).deleteAllArchived();
              }
            },
          );
        }
        final ticket = archived[i];
        return ListTile(
          leading: CustomerAvatar(
            name: ticket.customerName,
            fallbackIcon: Icons.archive_rounded,
          ),
          title: Text(ticket.label),
          subtitle: Text(
            '${ticket.itemCount} items · '
            '${fmt.format(ticket.subtotal)} · '
            '${dateFmt.format(ticket.createdAt)}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.unarchive_outlined, color: cs.primary),
                tooltip: 'Restore',
                onPressed: () => ref
                    .read(heldOrdersProvider.notifier)
                    .unarchive(ticket.id),
              ),
              IconButton(
                icon:
                    Icon(Icons.delete_outline_rounded, color: cs.error),
                tooltip: 'Delete',
                onPressed: () => ref
                    .read(heldOrdersProvider.notifier)
                    .delete(ticket.id),
              ),
            ],
          ),
          onTap: () => _resume(ctx, ref, ticket),
        );
      },
    );
  }

  void _resume(
    BuildContext context,
    WidgetRef ref,
    HeldOrder ticket,
  ) {
    final current = ref.read(cartProvider);
    if (current.isNotEmpty) {
      final nav = Navigator.of(context);
      final router = GoRouter.of(context);
      showDialog<_ResumeAction>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Save current cart?'),
          content: const Text(
              'You have items in your cart. Save them as a ticket or discard before resuming.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, _ResumeAction.cancel),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, _ResumeAction.discard),
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, _ResumeAction.save),
              child: const Text('Save & Resume'),
            ),
          ],
        ),
      ).then((action) {
        if (action == null || action == _ResumeAction.cancel) return;
        if (action == _ResumeAction.save) {
          ref.read(heldOrdersProvider.notifier).holdCurrentCart();
        }
        _loadTicket(nav, router, ref, ticket);
      });
    } else {
      _loadTicket(Navigator.of(context), GoRouter.of(context), ref, ticket);
    }
  }

  void _loadTicket(
      NavigatorState nav, GoRouter router, WidgetRef ref, HeldOrder ticket) {
    final notifier = ref.read(cartProvider.notifier);
    notifier.clear();
    for (final item in ticket.items) {
      notifier.addItem(item);
    }
    final sessionNotifier = ref.read(cartSessionProvider.notifier);
    if (ticket.customerId != null) {
      sessionNotifier.setCustomer(ticket.customerId);
    }
    if (ticket.tableId != null) {
      sessionNotifier.setTable(ticket.tableId);
    }
    if (ticket.orderDiscount > 0) {
      sessionNotifier.setOrderDiscount(
        ticket.orderDiscount,
        isPercent: ticket.orderDiscountIsPercent,
      );
    } else if (ticket.customerId != null) {
      final customers =
          ref.read(customersStreamProvider).valueOrNull ?? [];
      try {
        final c = customers.firstWhere((c) => c.id == ticket.customerId);
        if (c.defaultDiscount > 0) {
          sessionNotifier.setOrderDiscount(
            c.defaultDiscount,
            isPercent: c.defaultDiscountIsPercent,
          );
        }
      } catch (_) {}
    }
    ref.read(heldOrdersProvider.notifier).delete(ticket.id);
    nav.pop(); // close the sheet
    router.push('/cart'); // open cart detail
  }
}

