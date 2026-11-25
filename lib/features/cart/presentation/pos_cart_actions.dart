import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart' show Product;
import 'package:pos_app/features/cart/domain/pos_catalog_provider.dart';
import 'package:pos_app/features/cart/domain/stock_cap.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:pos_app/features/cart/presentation/widgets/unit_picker_sheet.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/shared/widgets/app_sheet.dart';

/// What a product tile's taps do on the sell screen.
///
/// Built inside the tap handler, so every decision reads the cart as it is
/// at that moment — tiles hold no per-build snapshot of the cart and need
/// not be rebuilt just to keep their callbacks current.
///
/// The cart notifier enforces the stock cap on every path; the checks here
/// exist to tell the cashier why the tap did nothing.
class PosCartActions {
  PosCartActions.of(BuildContext context)
      : _container = ProviderScope.containerOf(context, listen: false),
        _messenger = ScaffoldMessenger.of(context);

  final ProviderContainer _container;
  final ScaffoldMessengerState _messenger;

  CartNotifier get _cart => _container.read(cartProvider.notifier);

  /// Main units of [p] already in the cart, across all of its lines.
  int _committed(Product p) =>
      committedMainUnits(_container.read(cartProvider), p.id);

  /// Cap cart qty at stock for tracked products. Unlimited (qty=0) passes;
  /// [desiredMainUnits] counts every line of the product (pcs + boxes).
  bool _allowQty(Product p, int desiredMainUnits) {
    final cap = stockCapFor(p);
    if (cap == null || desiredMainUnits <= cap) return true;
    _messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(cap == 0
            ? '${p.name} is out of stock'
            : 'Only $cap in stock for ${p.name}'),
        duration: const Duration(seconds: 2),
      ));
    return false;
  }

  /// Adds one main unit of [p].
  void add(Product p) {
    if (!_allowQty(p, _committed(p) + 1)) return;
    _cart.addProduct(p);
  }

  /// Moves [p]'s main-unit line by [delta] (the tile stepper: +1 / -1).
  /// Reaching zero removes the line. Only a raise is checked against stock:
  /// a line already above it (stock sold since, a resumed ticket) can always
  /// be lowered.
  void step(Product p, int delta) {
    final current = _container.read(cartMainUnitQtyProvider)[p.id] ?? 0;
    final qty = current + delta;
    if (delta > 0) {
      final otherLines = _committed(p) - current;
      if (!_allowQty(p, otherLines + qty)) return;
    }
    _cart.setQuantity(p.id, qty);
  }

  /// Long-press on a product with a second unit: ask which unit, then add.
  Future<void> pickUnit(BuildContext context, Product p) async {
    final unit = await showAppSheet<String>(
      context: context,
      builder: (_) => UnitPickerSheet(
        product: p,
        fmt: _container.read(currencyFormatterProvider),
      ),
    );
    if (unit == null) return;
    if (unit.isEmpty) {
      add(p);
      return;
    }
    if (!_allowQty(p, _committed(p) + p.conversionRate.round())) return;
    _cart.addProductInSecondaryUnit(p);
  }
}
