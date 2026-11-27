import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';

const kCartClearedMessage = 'Cart cleared';
const kCartClearedUndo = 'Undo';

/// How long "Undo" is offered after Clear cart.
const kCartClearedUndoFor = Duration(seconds: 5);

/// The one way the cart is cleared by hand (the app bar icon, the menu item,
/// the cart screen's Clear and ⌘K): clears it, then shows "Cart cleared"
/// with "Undo", which puts back exactly the cart that was cleared — lines,
/// discount, customer, table, tax and ticket number — for
/// [kCartClearedUndoFor]. An empty cart is left alone. No confirm step: it
/// is on the hot path, and undo is quicker and just as safe.
void clearCartWithUndo(BuildContext context, WidgetRef ref) {
  if (ref.read(cartProvider).isEmpty) return;
  final cart = ref.read(cartProvider.notifier);
  final before = cart.snapshot();
  cart.clear();
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: const Text(kCartClearedMessage),
      duration: kCartClearedUndoFor,
      // Undo is the point of the message: it must not stay up waiting for
      // a tap on platforms that keep action SnackBars open.
      persist: false,
      action: SnackBarAction(
        label: kCartClearedUndo,
        onPressed: () => cart.restoreSnapshot(before),
      ),
    ));
}
