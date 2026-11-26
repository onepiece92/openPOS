import 'package:pos_app/core/database/tables/orders_table.dart'
    show kImportedInvoicePrefix;

/// Why [prefix] can't be the invoice prefix, or null if it can. "IMP" marks
/// CSV-imported orders (which never deducted stock, so a void or refund
/// restocks nothing): a shop's own sales must not share it.
String? invoicePrefixError(String prefix) =>
    prefix.trim().toUpperCase() == kImportedInvoicePrefix
        ? '$kImportedInvoicePrefix is reserved for imported orders.'
        : null;

/// One line shown when the shop's current prefix is already IMP.
const kReservedPrefixHint =
    'IMP is reserved for imported orders — choose another prefix for new sales';
