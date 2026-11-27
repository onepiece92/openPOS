import 'package:pos_app/features/cart/domain/cart_item.dart';

class HeldOrder {
  HeldOrder({
    required this.id,
    required this.ticketNumber,
    required this.label,
    required this.createdAt,
    required this.items,
    this.customerName,
    this.customerId,
    this.tableId,
    this.orderDiscount = 0.0,
    this.orderDiscountIsPercent = false,
    this.taxEnabled = true,
    this.taxRateIds,
    this.archivedAt,
  });

  final String id;

  /// Stable display number (`#0042`) from the persisted ticket counter. Set
  /// once when the ticket is first saved and never reassigned, so editing a
  /// ticket cannot renumber it.
  final String ticketNumber;

  final String label;
  final DateTime createdAt;
  final List<CartItem> items;
  final String? customerName;
  final int? customerId;
  final int? tableId;
  final double orderDiscount;
  final bool orderDiscountIsPercent;

  /// The cart's tax switch when the ticket was parked.
  final bool taxEnabled;

  /// Tax rate ids selected when the ticket was parked. Null for tickets
  /// saved before tax state was stored — those resume with the store's
  /// default rate, as they always did. An empty list means "none selected".
  final List<int>? taxRateIds;

  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  HeldOrder copyWith({DateTime? archivedAt, bool clearArchived = false}) =>
      HeldOrder(
        id: id,
        ticketNumber: ticketNumber,
        label: label,
        createdAt: createdAt,
        items: items,
        customerName: customerName,
        customerId: customerId,
        tableId: tableId,
        orderDiscount: orderDiscount,
        orderDiscountIsPercent: orderDiscountIsPercent,
        taxEnabled: taxEnabled,
        taxRateIds: taxRateIds,
        archivedAt: clearArchived ? null : (archivedAt ?? this.archivedAt),
      );

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);
  double get subtotal => items.fold(0.0, (s, i) => s + i.lineSubtotal);

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticketNumber': ticketNumber,
        'label': label,
        'createdAt': createdAt.toIso8601String(),
        if (customerName != null) 'customerName': customerName,
        if (customerId != null) 'customerId': customerId,
        if (tableId != null) 'tableId': tableId,
        if (orderDiscount != 0.0) 'orderDiscount': orderDiscount,
        if (orderDiscountIsPercent) 'orderDiscountIsPercent': true,
        if (!taxEnabled) 'taxEnabled': false,
        if (taxRateIds != null) 'taxRateIds': taxRateIds,
        if (archivedAt != null) 'archivedAt': archivedAt!.toIso8601String(),
        'items': items
            .map((i) => {
                  'productId': i.productId,
                  'name': i.name,
                  'unitPrice': i.unitPrice,
                  'quantity': i.quantity,
                  'isTaxable': i.isTaxable,
                  'lineDiscount': i.lineDiscount,
                  if (i.unitLabel.isNotEmpty) 'unitLabel': i.unitLabel,
                  if (i.unitsPerQty != 1.0) 'unitsPerQty': i.unitsPerQty,
                })
            .toList(),
      };

  factory HeldOrder.fromJson(Map<String, dynamic> json) => HeldOrder(
        id: json['id'] as String,
        ticketNumber: json['ticketNumber'] as String? ?? _legacyNumber(json),
        label: json['label'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        customerName: json['customerName'] as String?,
        customerId: json['customerId'] as int?,
        tableId: json['tableId'] as int?,
        orderDiscount: (json['orderDiscount'] as num?)?.toDouble() ?? 0.0,
        orderDiscountIsPercent:
            json['orderDiscountIsPercent'] as bool? ?? false,
        taxEnabled: json['taxEnabled'] as bool? ?? true,
        taxRateIds: (json['taxRateIds'] as List?)?.cast<int>().toList(),
        archivedAt: json['archivedAt'] != null
            ? DateTime.parse(json['archivedAt'] as String)
            : null,
        items: (json['items'] as List).map((i) {
          final m = i as Map<String, dynamic>;
          return CartItem(
            productId: m['productId'] as int,
            name: m['name'] as String,
            unitPrice: (m['unitPrice'] as num).toDouble(),
            quantity: m['quantity'] as int,
            isTaxable: m['isTaxable'] as bool,
            lineDiscount: (m['lineDiscount'] as num?)?.toDouble() ?? 0.0,
            unitLabel: m['unitLabel'] as String? ?? '',
            unitsPerQty: (m['unitsPerQty'] as num?)?.toDouble() ?? 1.0,
          );
        }).toList(),
      );
}

/// Tickets written before the counter existed carry no `ticketNumber`. Their
/// id was `DateTime.now().millisecondsSinceEpoch`, which is what the old cart
/// header derived its number from — so reproduce that rather than showing a
/// blank, and let the counter's high-water-mark scan pick it up.
String _legacyNumber(Map<String, dynamic> json) {
  final id = int.tryParse(json['id'] as String? ?? '') ?? 0;
  return '#${(id % 10000).toString().padLeft(4, '0')}';
}

/// A held ticket checked against the database before it is resumed.
class ResumeCheck {
  const ResumeCheck(this.ticket,
      {this.removedLines = 0,
      this.changed = false,
      this.taxRateRemoved = false,
      this.taxRateOff = false,
      this.paid = false,
      this.busy = false});

  /// The ticket was already paid (its sale is saved) and is gone: nothing
  /// to resume.
  final bool paid;

  /// The ticket is being paid, or a payment of it could not be checked:
  /// it is not resumed now.
  final bool busy;

  /// The ticket to resume: lines for products that no longer exist are
  /// dropped, and a customer or table that no longer exists is cleared.
  final HeldOrder ticket;

  /// How many lines were dropped.
  final int removedLines;

  /// Whether anything was dropped or cleared.
  final bool changed;

  /// Whether a tax rate on the ticket no longer exists (it was removed).
  final bool taxRateRemoved;

  /// Whether a tax rate on the ticket is switched off (it was removed: the
  /// cart only ever applies active rates).
  final bool taxRateOff;

  /// Every line is gone: nothing to resume. The ticket is kept as it was
  /// (a soft-deleted product can be reactivated) and the cashier may delete
  /// it; it is never loaded as an empty cart.
  bool get emptied => removedLines > 0 && ticket.items.isEmpty;

  /// What to tell the cashier, or null when nothing was removed.
  String? get message {
    if (paid) return kTicketPaidMessage;
    if (busy) return kTicketBusyMessage;
    if (emptied) return kTicketEmptyMessage;
    final parts = [
      removedLinesMessage(removedLines),
      if (taxRateRemoved) kTicketTaxRemovedMessage,
      if (taxRateOff) kTicketTaxOffMessage,
    ].whereType<String>();
    return parts.isEmpty ? null : parts.join('\n');
  }
}

const kTicketTaxRemovedMessage =
    'The tax on this ticket no longer exists and was removed.';
const kTicketTaxOffMessage =
    'A tax on this ticket is switched off and was removed.';
const kTicketPaidMessage = 'This ticket was already paid, so it was removed.';
const kTicketBusyMessage = 'This ticket is being paid. Try again in a moment.';
const kTicketEmptyMessage = 'None of the items on this ticket exist any more.';

/// "1 item no longer exists and was removed" / "N items no longer exist and
/// were removed"; null for none.
String? removedLinesMessage(int n) => switch (n) {
      0 => null,
      1 => '1 item no longer exists and was removed',
      _ => '$n items no longer exist and were removed',
    };

/// [ticket] without what is gone: lines whose product is not in
/// [liveProductIds], and the customer / table when they no longer exist.
/// Tickets can outlive their data (a factory reset, a backup restore, a
/// deleted product); resuming one must not carry dead ids into a sale.
ResumeCheck checkHeldOrder(
  HeldOrder ticket, {
  required Set<int> liveProductIds,
  required bool customerExists,
  required bool tableExists,
  Set<int>? liveTaxRateIds,
  Set<int> offTaxRateIds = const {},
}) {
  final items =
      ticket.items.where((i) => liveProductIds.contains(i.productId)).toList();
  final removed = ticket.items.length - items.length;
  final dropCustomer = ticket.customerId != null && !customerExists;
  final dropTable = ticket.tableId != null && !tableExists;
  // Null live set = not checked. Only the dead rates are dropped; the
  // others stay. [offTaxRateIds] exist but are switched off.
  final rates = ticket.taxRateIds;
  final goneRates = liveTaxRateIds == null || rates == null
      ? const <int>[]
      : [
          for (final id in rates)
            if (!liveTaxRateIds.contains(id) && !offTaxRateIds.contains(id)) id
        ];
  final offRates = liveTaxRateIds == null || rates == null
      ? const <int>[]
      : [
          for (final id in rates)
            if (offTaxRateIds.contains(id)) id
        ];
  final dropTax = goneRates.isNotEmpty || offRates.isNotEmpty;
  if (removed == 0 && !dropCustomer && !dropTable && !dropTax) {
    return ResumeCheck(ticket);
  }
  return ResumeCheck(
    HeldOrder(
      id: ticket.id,
      ticketNumber: ticket.ticketNumber,
      label: ticket.label,
      createdAt: ticket.createdAt,
      items: items,
      customerName: dropCustomer ? null : ticket.customerName,
      customerId: dropCustomer ? null : ticket.customerId,
      tableId: dropTable ? null : ticket.tableId,
      orderDiscount: ticket.orderDiscount,
      orderDiscountIsPercent: ticket.orderDiscountIsPercent,
      taxEnabled: ticket.taxEnabled,
      // Only the dead rates go. Empty = "none selected", not null (null
      // means the default rate).
      taxRateIds: dropTax
          ? [
              for (final id in rates!)
                if (!goneRates.contains(id) && !offRates.contains(id)) id
            ]
          : ticket.taxRateIds,
      archivedAt: ticket.archivedAt,
    ),
    removedLines: removed,
    changed: true,
    taxRateRemoved: goneRates.isNotEmpty,
    taxRateOff: offRates.isNotEmpty,
  );
}

/// How many held tickets (active or archived) have a line for [productId].
int heldTicketsWithProduct(Iterable<HeldOrder> tickets, int productId) =>
    tickets.where((t) => t.items.any((i) => i.productId == productId)).length;

/// Warning for deleting a product that is on held tickets; null for none.
String? productOnHeldTicketsWarning(int n) => switch (n) {
      0 => null,
      1 => 'This product is on 1 held ticket. It will be removed from it '
          'when it is resumed.',
      _ => 'This product is on $n held tickets. It will be removed from them '
          'when they are resumed.',
    };
