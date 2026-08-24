import 'package:pos_app/core/utils/money.dart';

/// One cart line. A product sold in its main unit and the same product sold
/// in its secondary unit (e.g. pcs vs dozen) are *separate* lines — they have
/// different prices and different stock math — so line identity is
/// (productId, unitLabel), not productId alone.
class CartItem {
  CartItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.isTaxable,
    this.lineDiscount = 0.0,
    this.unitLabel = '',
    this.unitsPerQty = 1.0,
  });

  final int productId;
  final String name;

  /// Price per [unitLabel] unit (already × conversion for secondary units).
  final double unitPrice;
  final int quantity;
  final bool isTaxable;
  final double lineDiscount; // flat amount off the whole line

  /// '' = the product's main unit; otherwise the secondary unit's name
  /// (e.g. 'dozen') as it was when the line was added.
  final String unitLabel;

  /// How many main units one [quantity] step represents (1.0 for the main
  /// unit, the product's conversionRate for the secondary unit).
  final double unitsPerQty;

  bool get isSecondaryUnit => unitLabel.isNotEmpty;

  /// Stock impact of this line, in the product's main unit.
  /// Rounded because stock is tracked as whole main units.
  int get mainUnitQty => (quantity * unitsPerQty).round();

  /// True when [other] belongs to the same line (same product, same unit).
  bool sameLine(int productId, String unitLabel) =>
      this.productId == productId && this.unitLabel == unitLabel;

  double get lineSubtotal => roundMoney((unitPrice * quantity) - lineDiscount);

  CartItem copyWith({int? quantity, double? lineDiscount}) => CartItem(
        productId: productId,
        name: name,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        isTaxable: isTaxable,
        lineDiscount: lineDiscount ?? this.lineDiscount,
        unitLabel: unitLabel,
        unitsPerQty: unitsPerQty,
      );
}
