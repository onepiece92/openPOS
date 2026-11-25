import 'package:pos_app/core/database/app_database.dart' show OrderTaxe;
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
