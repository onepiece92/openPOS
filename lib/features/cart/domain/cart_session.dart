/// Ticket-level metadata for the cart currently being built
/// (customer, table, order discount, tax toggle, loyalty redemption).
class CartSession {
  const CartSession({
    required this.ticketNumber,
    required this.openedAt,
    this.heldTicketId,
    this.customerId,
    this.tableId,
    this.orderDiscount = 0.0,
    this.orderDiscountIsPercent = false,
    this.taxEnabled = true,
    this.loyaltyPointsToRedeem = 0,
  });

  /// Stable display number (`#0042`), assigned once when the session opens and
  /// carried through hold → resume → save. Editing a held ticket keeps it.
  final String ticketNumber;
  final DateTime openedAt;

  /// Hive id of the held ticket this cart was resumed from, if any. Non-null
  /// means "Save" updates that ticket in place instead of creating a new one.
  final String? heldTicketId;

  final int? customerId;
  final int? tableId;
  final double orderDiscount;
  final bool orderDiscountIsPercent;
  final bool taxEnabled;
  final int loyaltyPointsToRedeem;

  /// True when this cart is editing a ticket that already exists on disk.
  bool get isEditingHeldTicket => heldTicketId != null;

  CartSession copyWith({
    String? heldTicketId,
    int? customerId,
    int? tableId,
    double? orderDiscount,
    bool? orderDiscountIsPercent,
    bool? taxEnabled,
    int? loyaltyPointsToRedeem,
    bool clearHeldTicket = false,
    bool clearCustomer = false,
    bool clearTable = false,
  }) =>
      CartSession(
        ticketNumber: ticketNumber,
        openedAt: openedAt,
        heldTicketId:
            clearHeldTicket ? null : (heldTicketId ?? this.heldTicketId),
        customerId: clearCustomer ? null : (customerId ?? this.customerId),
        tableId: clearTable ? null : (tableId ?? this.tableId),
        orderDiscount: orderDiscount ?? this.orderDiscount,
        orderDiscountIsPercent:
            orderDiscountIsPercent ?? this.orderDiscountIsPercent,
        taxEnabled: taxEnabled ?? this.taxEnabled,
        loyaltyPointsToRedeem:
            loyaltyPointsToRedeem ?? this.loyaltyPointsToRedeem,
      );

  /// A new, unsaved cart. [ticketNumber] comes from the persisted counter so
  /// the number on screen is the number the ticket keeps once it is saved.
  static CartSession fresh(String ticketNumber) => CartSession(
        ticketNumber: ticketNumber,
        openedAt: DateTime.now(),
      );
}
