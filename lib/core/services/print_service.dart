/// ESC/POS receipt printing service.
/// Supports Bluetooth and USB/Network thermal printers.
///
/// Depends on: esc_pos_utils_plus, flutter_thermal_printer
library;

class PrintService {
  const PrintService();

  /// Print a receipt to the configured Bluetooth/USB printer.
  Future<void> printReceipt(ReceiptData data) async {
    // TODO: build ESC/POS byte sequence via esc_pos_utils_plus
    // and send via flutter_thermal_printer
    //
    // Example flow:
    //   final profile = await CapabilityProfile.load();
    //   final generator = Generator(PaperSize.mm80, profile);
    //   List<int> bytes = [];
    //   bytes += generator.text(data.storeName, styles: PosStyles(bold: true, align: PosAlign.center));
    //   bytes += generator.text('------------------------');
    //   for (final item in data.items) { ... }
    //   bytes += generator.cut();
    //   await FlutterThermalPrinter.instance.printData(bytes);
    throw UnimplementedError('Print not yet implemented');
  }

  /// Kick cash drawer via the RJ11 port (ESC/POS DLE EOT command).
  Future<void> kickCashDrawer() async {
    // TODO: send DLE EOT via printer port
    throw UnimplementedError('Cash drawer kick not yet implemented');
  }

  /// Print a test page to verify printer connection.
  Future<void> printTestPage() async {
    throw UnimplementedError('Test page not yet implemented');
  }
}

/// Data contract for receipt rendering. Populated from an Order + OrderItems.
class ReceiptData {
  const ReceiptData({
    required this.orderId,
    required this.storeName,
    required this.storeAddress,
    required this.taxNumber,
    required this.items,
    required this.subtotal,
    required this.taxLines,
    required this.total,
    required this.paymentMethod,
    this.tenderedAmount,
    this.changeAmount,
    this.footerMessage,
  });

  final int orderId;
  final String storeName;
  final String storeAddress;
  final String taxNumber;
  final List<ReceiptLineItem> items;
  final double subtotal;
  final List<ReceiptTaxLine> taxLines;
  final double total;
  final String paymentMethod;
  final double? tenderedAmount;
  final double? changeAmount;
  final String? footerMessage;
}

class ReceiptLineItem {
  const ReceiptLineItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
}

class ReceiptTaxLine {
  const ReceiptTaxLine({
    required this.name,
    required this.rate,
    required this.amount,
  });

  final String name;
  final double rate;
  final double amount;
}
