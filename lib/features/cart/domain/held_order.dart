import 'package:pos_app/features/cart/domain/cart_item.dart';

class HeldOrder {
  HeldOrder({
    required this.id,
    required this.label,
    required this.createdAt,
    required this.items,
    this.customerName,
    this.customerId,
    this.tableId,
    this.orderDiscount = 0.0,
    this.orderDiscountIsPercent = false,
    this.archivedAt,
  });

  final String id;
  final String label;
  final DateTime createdAt;
  final List<CartItem> items;
  final String? customerName;
  final int? customerId;
  final int? tableId;
  final double orderDiscount;
  final bool orderDiscountIsPercent;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  HeldOrder copyWith({DateTime? archivedAt, bool clearArchived = false}) =>
      HeldOrder(
        id: id,
        label: label,
        createdAt: createdAt,
        items: items,
        customerName: customerName,
        customerId: customerId,
        tableId: tableId,
        orderDiscount: orderDiscount,
        orderDiscountIsPercent: orderDiscountIsPercent,
        archivedAt: clearArchived ? null : (archivedAt ?? this.archivedAt),
      );

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);
  double get subtotal => items.fold(0.0, (s, i) => s + i.lineSubtotal);

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'createdAt': createdAt.toIso8601String(),
        if (customerName != null) 'customerName': customerName,
        if (customerId != null) 'customerId': customerId,
        if (tableId != null) 'tableId': tableId,
        if (orderDiscount != 0.0) 'orderDiscount': orderDiscount,
        if (orderDiscountIsPercent) 'orderDiscountIsPercent': true,
        if (archivedAt != null) 'archivedAt': archivedAt!.toIso8601String(),
        'items': items
            .map((i) => {
                  'productId': i.productId,
                  'name': i.name,
                  'unitPrice': i.unitPrice,
                  'quantity': i.quantity,
                  'isTaxable': i.isTaxable,
                  'lineDiscount': i.lineDiscount,
                })
            .toList(),
      };

  factory HeldOrder.fromJson(Map<String, dynamic> json) => HeldOrder(
        id: json['id'] as String,
        label: json['label'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        customerName: json['customerName'] as String?,
        customerId: json['customerId'] as int?,
        tableId: json['tableId'] as int?,
        orderDiscount: (json['orderDiscount'] as num?)?.toDouble() ?? 0.0,
        orderDiscountIsPercent:
            json['orderDiscountIsPercent'] as bool? ?? false,
        archivedAt: json['archivedAt'] != null
            ? DateTime.parse(json['archivedAt'] as String)
            : null,
        items: (json['items'] as List)
            .map((i) {
              final m = i as Map<String, dynamic>;
              return CartItem(
                productId: m['productId'] as int,
                name: m['name'] as String,
                unitPrice: (m['unitPrice'] as num).toDouble(),
                quantity: m['quantity'] as int,
                isTaxable: m['isTaxable'] as bool,
                lineDiscount: (m['lineDiscount'] as num?)?.toDouble() ?? 0.0,
              );
            })
            .toList(),
      );
}
