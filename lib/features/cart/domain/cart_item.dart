class CartItem {
  CartItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.isTaxable,
    this.lineDiscount = 0.0,
  });

  final int productId;
  final String name;
  final double unitPrice;
  final int quantity;
  final bool isTaxable;
  final double lineDiscount; // flat amount off the whole line

  double get lineSubtotal => (unitPrice * quantity) - lineDiscount;

  CartItem copyWith({int? quantity, double? lineDiscount}) => CartItem(
        productId: productId,
        name: name,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        isTaxable: isTaxable,
        lineDiscount: lineDiscount ?? this.lineDiscount,
      );
}
