import 'dart:typed_data';

import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

import 'package:pos_app/features/printing/domain/escpos_raster.dart';
import 'package:pos_app/features/printing/domain/printer_errors.dart';
import 'package:pos_app/features/printing/domain/receipt_printer.dart';
import 'package:pos_app/features/printing/domain/render_receipt_image.dart';

/// [ReceiptPrinter] for Bluetooth Low Energy ESC/POS printers, backed by the
/// `flutter_thermal_printer` plugin. The only file in the app that imports
/// that plugin.
///
/// Receipts go out as raster images rather than ESC/POS text so that any
/// script prints correctly and the output matches every other driver.
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
    final pages = await renderReceiptImages(
      job.data,
      job.fmt,
      widthDots: escPosPrintWidthDots(job.paperMm),
      isCopy: job.isCopy,
    );
    await _printPages(target, pages, job.paperMm);
  }

  @override
  Future<void> printTestPage(
    PrinterTarget target, {
    required String storeName,
    required int paperMm,
  }) async {
    final pages = await renderTestPageImages(
      storeName: storeName,
      paperMm: paperMm,
      widthDots: escPosPrintWidthDots(paperMm),
    );
    await _printPages(target, pages, paperMm);
  }

  Future<void> _printPages(
    PrinterTarget target,
    List<Uint8List> pages,
    int paperMm,
  ) async {
    final bytes = await escPosRasterBytes(pages, paperMm);
    final device = Printer(
      address: target.address,
      name: target.name,
      connectionType: ConnectionType.BLE,
    );
    final bool connected;
    try {
      connected = await _ftp.connect(device);
    } catch (e) {
      throw StateError(friendlyPrinterError(e, printerName: target.name));
    }
    if (!connected) {
      throw StateError('${target.name}: could not connect — check it is '
          'switched on and in range');
    }
    try {
      await _ftp.printData(device, bytes, longData: true);
    } catch (e) {
      throw StateError(friendlyPrinterError(e, printerName: target.name));
    }
  }
}
