import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:pos_app/core/theme/tron_border.dart';
import 'package:pos_app/features/cart/domain/cart_notifier.dart';
import 'package:pos_app/features/cart/domain/held_order.dart';
import 'package:pos_app/features/cart/domain/held_orders_notifier.dart';
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
    final held = ref.watch(heldOrdersProvider);
    if (held.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final count = held.length;
    final dark = cs.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: InkWell(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
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

class _HeldTicketsSheet extends ConsumerWidget {
  const _HeldTicketsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final held = ref.watch(heldOrdersProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final currentCustomerName = ref.watch(cartCustomerNameProvider);
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMM  HH:mm');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Held Tickets',
                style: Theme.of(ctx).textTheme.titleLarge),
          ),
          Expanded(
            child: held.isEmpty
                ? Center(
                    child: Text('No held tickets',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  )
                : ListView.separated(
                    controller: scrollCtrl,
                    // +1 for the "Clear all" row at the end
                    itemCount: held.length + 1,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16),
                    itemBuilder: (_, i) {
                      // ── Clear all footer ───────────────────────────────
                      if (i == held.length) {
                        return ListTile(
                          leading: Icon(Icons.delete_sweep_rounded,
                              color: cs.error),
                          title: Text('Clear all tickets',
                              style: TextStyle(color: cs.error)),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: ctx,
                              builder: (dCtx) => AlertDialog(
                                title: const Text('Clear all tickets?'),
                                content: Text(
                                  'This will permanently delete all ${held.length} held ${held.length == 1 ? 'ticket' : 'tickets'}.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dCtx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: cs.error,
                                      foregroundColor: cs.onError,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(dCtx, true),
                                    child: const Text('Clear all'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              ref
                                  .read(heldOrdersProvider.notifier)
                                  .deleteAll();
                              // ignore: use_build_context_synchronously
                              Navigator.pop(ctx);
                            }
                          },
                        );
                      }
                      // ── Ticket row ─────────────────────────────────────
                      final ticket = held[i];
                      final initials = ticket.customerName
                          ?.trim()
                          .split(' ')
                          .where((s) => s.isNotEmpty)
                          .take(2)
                          .map((s) => s[0].toUpperCase())
                          .join();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ticket.customerName != null
                              ? cs.primaryContainer
                              : cs.secondaryContainer,
                          child: initials != null
                              ? Text(initials,
                                  style: TextStyle(
                                    color: cs.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ))
                              : Icon(Icons.pause_rounded,
                                  size: 18, color: cs.onSecondaryContainer),
                        ),
                        title: Text(ticket.label),
                        subtitle: Text(
                          '${ticket.itemCount} items · '
                          '$symbol ${ticket.subtotal.toStringAsFixed(2)} · '
                          '${dateFmt.format(ticket.createdAt)}',
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline_rounded,
                              color: cs.error),
                          onPressed: () => ref
                              .read(heldOrdersProvider.notifier)
                              .delete(ticket.id),
                        ),
                        onTap: () => _resume(ctx, ref, ticket,
                            currentCustomerName: currentCustomerName),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _resume(
    BuildContext context,
    WidgetRef ref,
    HeldOrder ticket, {
    String? currentCustomerName,
  }) {
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
          ref.read(heldOrdersProvider.notifier).hold(
                current,
                customerName: currentCustomerName,
              );
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
    ref.read(heldOrdersProvider.notifier).delete(ticket.id);
    nav.pop(); // close the sheet
    router.push('/cart'); // open cart detail
  }
}

