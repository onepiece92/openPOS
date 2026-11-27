import 'package:pos_app/core/database/app_database.dart'
    show Customer, Order, OrderTaxe;
import 'package:pos_app/features/tips/tip_math.dart';
import 'package:pos_app/core/utils/percent.dart';

/// The label of a tax row, shared by every receipt format (on screen, A4
/// PDF, roll PDF, ESC/POS text, share text) so they cannot drift apart.
///
///   VAT (13%)          tax added on top of the prices
///   VAT (13%, incl.)   tax already inside the prices — the total does not
///                      grow by it, and the row has to say so or the
///                      receipt does not add up
String taxLineLabel(OrderTaxe tax) =>
    '${tax.taxRateName} (${formatRatePercent(tax.taxRatePercent)}'
    '${tax.isInclusive ? ', incl.' : ''})';

/// Which optional sections a receipt prints, shared by every format (on
/// screen, A4 PDF, roll PDF, ESC/POS, share text). Decided by the ORDER's
/// own figures, so a past receipt stays true to its sale whatever the
/// customer or settings are today.
extension ReceiptSections on Order {
  /// The Discount row: only when the sale had an order discount.
  bool get showsDiscount => discountTotal > 0;

  /// The loyalty block: only when the sale earned or redeemed points — not
  /// merely because a customer is attached.
  bool get showsLoyalty => pointsEarned > 0 || pointsRedeemed > 0;
}

/// The customer line of a receipt: the customer's name when the sale had
/// one (and it is still known), else null — no line, never "Walk-in".
String? receiptCustomerName(Order order, Customer? customer) =>
    order.customerId == null ? null : customer?.name;

/// Tip lines of a receipt, shared by every format. A stored tip always
/// prints, even after tips are switched off; a receipt without one is
/// exactly as before.
///
///   Tip          the tip, a row before the total
///   Total paid   the sale plus the tip (replaces the plain total's label
///                only when there is a tip, so the rows above still add up)
extension ReceiptTip on Order {
  bool get hasTip => tipAmount > 0;

  /// What the customer paid: [total] plus [tipAmount].
  double get paidTotal => paidWithTip(total, tipAmount);

  /// The label of the closing total row: "Total paid" once there is a tip,
  /// else [plain] ("Grand Total" on the page formats, "TOTAL" on the roll).
  /// [shout] upper-cases it ("TOTAL PAID") for the roll and ESC/POS, where
  /// every total is in capitals; everywhere else it is "Total paid".
  String totalRowLabel(String plain, {bool shout = false}) {
    final label = hasTip ? 'Total paid' : plain;
    return shout ? label.toUpperCase() : label;
  }
}
