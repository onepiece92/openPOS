import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/printing/domain/receipt_printer.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';

/// Fire-and-forget print of a just-placed order. Resolves with `null` on
/// success, or a short error string on failure (so the caller can flash a
/// snackbar without blocking the post-checkout navigation).
///
/// Returns `null` if no printer is paired — that is not an error, the user
/// may genuinely be running paperless.
Future<String?> autoPrintOrder(WidgetRef ref, int orderId) =>
    ref.read(autoPrintServiceProvider).printOrder(orderId);

final autoPrintServiceProvider =
    Provider<AutoPrintService>((ref) => AutoPrintService(ref));

/// Loads an order + everything the receipt shows and hands it to the
/// [ReceiptPrinter] port, which renders it the way its own printer wants it
/// (ESC/POS text, or an image for graphics-only Star hardware). Kept off the
/// widget layer so it can be exercised in plain provider-container tests
/// with a fake printer.
class AutoPrintService {
  AutoPrintService(this._ref);
  final Ref _ref;

  Future<String?> printOrder(int orderId) async {
    final address = _ref.read(printerDeviceAddressProvider);
    final name = _ref.read(printerDeviceNameProvider);
    if (address == null || name == null) return null;

    try {
      final db = _ref.read(databaseProvider);
      final paper = _ref.read(printerPaperWidthProvider);
      final fmt = _ref.read(currencyFormatterProvider);

      final order = await db.ordersDao.getById(orderId);
      if (order == null) return 'Order not found for printing';
      final items = await db.ordersDao.getItems(orderId);
      final taxes = await db.ordersDao.getTaxBreakdown(orderId);
      final businessName = _ref.read(settingsProvider).businessNameOrDefault;
      final customer = order.customerId == null
          ? null
          : await db.customersDao.getById(order.customerId!);
      final table = order.tableId == null
          ? null
          : await db.tablesDao.getById(order.tableId!);

      final data = ReceiptBodyData(
        order: order,
        items: items,
        taxes: taxes,
        businessName: businessName,
        customer: customer,
        table: table,
      );

      // Count first: anything after the original is a marked copy, and a
      // print that fails half-way was still an issue attempt.
      final printsBefore = await db.ordersDao.incrementPrintCount(orderId);
      await _ref.read(receiptPrinterProvider).printReceipt(
            PrinterTarget(address: address, name: name),
            ReceiptPrintJob(
              data: data,
              fmt: fmt,
              paperMm: paper,
              isCopy: printsBefore > 0,
            ),
          );
      return null;
    } catch (e) {
      return 'Printer: $e';
    }
  }
}
