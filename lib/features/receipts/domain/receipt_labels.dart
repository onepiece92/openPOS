import 'package:pos_app/core/database/app_database.dart' show Order, OrderTaxe;
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

  /// The label of the closing total row: "Total Paid" once there is a tip,
  /// else [plain] ("Grand Total" on the page formats, "TOTAL" on the roll).
  /// [shout] upper-cases it for the roll and ESC/POS.
  String totalRowLabel(String plain, {bool shout = false}) {
    final label = hasTip ? 'Total Paid' : plain;
    return shout ? label.toUpperCase() : label;
  }
}
