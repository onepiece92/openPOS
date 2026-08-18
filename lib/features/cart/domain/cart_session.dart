/// Ticket-level metadata for the cart currently being built
/// (customer, table, order discount, tax toggle, loyalty redemption).
class CartSession {
  const CartSession({
    required this.ticketNumber,
    required this.openedAt,
    this.customerId,
    this.tableId,
    this.orderDiscount = 0.0,
    this.orderDiscountIsPercent = false,
    this.taxEnabled = true,
    this.loyaltyPointsToRedeem = 0,
  });

  final String ticketNumber;
  final DateTime openedAt;
  final int? customerId;
  final int? tableId;
  final double orderDiscount;
  final bool orderDiscountIsPercent;
  final bool taxEnabled;
  final int loyaltyPointsToRedeem;

  CartSession copyWith({
    int? customerId,
    int? tableId,
    double? orderDiscount,
    bool? orderDiscountIsPercent,
    bool? taxEnabled,
    int? loyaltyPointsToRedeem,
    bool clearCustomer = false,
    bool clearTable = false,
  }) =>
      CartSession(
        ticketNumber: ticketNumber,
        openedAt: openedAt,
        customerId: clearCustomer ? null : (customerId ?? this.customerId),
        tableId: clearTable ? null : (tableId ?? this.tableId),
        orderDiscount: orderDiscount ?? this.orderDiscount,
        orderDiscountIsPercent:
            orderDiscountIsPercent ?? this.orderDiscountIsPercent,
        taxEnabled: taxEnabled ?? this.taxEnabled,
        loyaltyPointsToRedeem:
            loyaltyPointsToRedeem ?? this.loyaltyPointsToRedeem,
      );

  static CartSession fresh() {
    final now = DateTime.now();
    final seq = now.millisecondsSinceEpoch % 10000;
    return CartSession(
      ticketNumber: '#${seq.toString().padLeft(4, '0')}',
      openedAt: now,
    );
  }
}
