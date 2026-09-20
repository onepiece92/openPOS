import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

import 'package:pos_app/features/printing/domain/receipt_printer.dart';
import 'package:pos_app/features/printing/domain/render_receipt.dart';

/// [ReceiptPrinter] backed by the `flutter_thermal_printer` plugin (BLE),
/// speaking ESC/POS. The only file in the app that imports the plugin.
class ThermalPluginPrinter implements ReceiptPrinter {
  final _ftp = FlutterThermalPrinter.instance;

  @override
  Stream<List<DiscoveredPrinter>> get devices =>
      _ftp.devicesStream.map((list) => [
            for (final d in list)
              if (d.address != null && d.address!.isNotEmpty)
                DiscoveredPrinter(
                  address: d.address!,
                  name: d.name ?? 'Unknown',
                  transport: d.connectionType == ConnectionType.USB
                      ? PrinterTransport.usb
                      : PrinterTransport.ble,
                  driver: PrinterDriver.escPos,
                ),
          ]);

  @override
  Future<void> startScan() =>
      _ftp.getPrinters(connectionTypes: const [ConnectionType.BLE]);

  @override
  Future<void> stopScan() => _ftp.stopScan();

  @override
  Future<void> printReceipt(PrinterTarget target, ReceiptPrintJob job) async {
    final bytes = await renderReceiptBytes(
      job.data,
      job.fmt,
      job.paperMm,
      isCopy: job.isCopy,
    );
    await _printBytes(target, bytes);
  }

  @override
  Future<void> printTestPage(
    PrinterTarget target, {
    required String storeName,
    required int paperMm,
  }) async {
    final bytes =
        await renderTestPageBytes(storeName: storeName, paperMm: paperMm);
    await _printBytes(target, bytes);
  }

  /// Sends raw ESC/POS [bytes]. Throws on connect/transmit failure.
  Future<void> _printBytes(PrinterTarget target, List<int> bytes) async {
    final device = Printer(
      address: target.address,
      name: target.name,
      connectionType: ConnectionType.BLE,
    );
    final connected = await _ftp.connect(device);
    if (!connected) {
      throw StateError(
          'Failed to connect to printer "${target.name}" (${target.address})');
    }
    await _ftp.printData(device, bytes, longData: true);
  }
}
