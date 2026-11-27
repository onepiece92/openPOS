import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/presentation/providers/held_orders_notifier.dart';

const kCartClearedMessage = 'Cart cleared';
const kCartClearedUndo = 'Undo';

/// Undo was tapped but the cart has lines again: nothing is replaced.
const kCartUndoNotEmpty = "Cart isn't empty — can't undo";

/// How long "Undo" is offered after Clear cart.
const kCartClearedUndoFor = Duration(seconds: 5);

/// The Undo on screen, and a counter that [cancelCartUndo] moves on so an
/// Undo offered before a sale or a resume can never act after it.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _undoBar;
int _undoEpoch = 0;

/// Withdraws the Clear cart "Undo" (a sale completed, a ticket was
/// resumed): the bar is closed and a tap that still lands does nothing.
void cancelCartUndo() {
  _undoEpoch++;
  final bar = _undoBar;
  _undoBar = null;
  try {
    bar?.close();
  } catch (_) {/* already gone */}
}

/// The one way the cart is cleared by hand (the app bar icon, the menu item,
/// the cart screen's Clear and ⌘K): clears it, then shows "Cart cleared"
/// with "Undo", which puts back exactly the cart that was cleared — lines,
/// discount, customer, table, tax and ticket number — for
/// [kCartClearedUndoFor]. An empty cart is left alone. No confirm step: it
/// is on the hot path, and undo is quicker and just as safe.
///
/// Undo only fills an empty cart (lines added since are never replaced),
/// and drops the link to a held ticket that is gone or being paid by then,
/// so a restored cart cannot sell that ticket a second time.
void clearCartWithUndo(BuildContext context, WidgetRef ref) {
  if (ref.read(cartProvider).isEmpty) return;
  final cart = ref.read(cartProvider.notifier);
  final held = ref.read(heldOrdersProvider.notifier);
  final before = cart.snapshot();
  cart.clear();
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  cancelCartUndo();
  final epoch = _undoEpoch;
  messenger.hideCurrentSnackBar();
  _undoBar = messenger.showSnackBar(SnackBar(
    content: const Text(kCartClearedMessage),
    duration: kCartClearedUndoFor,
    // Undo is the point of the message: it must not stay up waiting for
    // a tap on platforms that keep action SnackBars open.
    persist: false,
    action: SnackBarAction(
      label: kCartClearedUndo,
      onPressed: () {
        if (epoch != _undoEpoch) return; // a sale or resume came between
        _undoBar = null;
        if (cart.itemCount > 0) {
          if (messenger.mounted) {
            messenger.showSnackBar(
                const SnackBar(content: Text(kCartUndoNotEmpty)));
          }
          return;
        }
        final ticket = before.session.heldTicketId;
        cart.restoreSnapshot(ticket == null || held.isResumable(ticket)
            ? before
            : before.withoutHeldTicket());
      },
    ),
  ));
}
