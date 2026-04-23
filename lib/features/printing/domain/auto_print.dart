import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/printing/domain/print_receipt.dart';
import 'package:pos_app/features/printing/domain/render_receipt.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';

/// Fire-and-forget print of a just-placed order. Resolves with `null` on
/// success, or a short error string on failure (so the caller can flash a
/// snackbar without blocking the post-checkout navigation).
///
/// Returns `null` if no printer is paired — that is not an error, the user
/// may genuinely be running paperless.
Future<String?> autoPrintOrder(WidgetRef ref, int orderId) async {
  final address = ref.read(printerDeviceAddressProvider);
  final name = ref.read(printerDeviceNameProvider);
  if (address == null || name == null) return null;

  try {
    final db = ref.read(databaseProvider);
    final paper = ref.read(printerPaperWidthProvider);
    final fmt = ref.read(currencyFormatterProvider);
    final box = ref.read(settingsBoxProvider);

    final order = await db.ordersDao.getById(orderId);
    if (order == null) return 'Order not found for printing';
    final items = await db.ordersDao.getItems(orderId);
    final taxes = await db.ordersDao.getTaxBreakdown(orderId);
    final businessName =
        box.get('business_name', defaultValue: 'My Store') as String;
    final customer = order.customerId == null
        ? null
        : await db.customersDao.getById(order.customerId!);

    final data = ReceiptBodyData(
      order: order,
      items: items,
      taxes: taxes,
      businessName: businessName,
      customer: customer,
    );

    final bytes = await renderReceiptBytes(data, fmt, paper);
    await printBytesToBleAddress(
      address: address,
      name: name,
      bytes: bytes,
    );
    return null;
  } catch (e) {
    return 'Printer: $e';
  }
}
