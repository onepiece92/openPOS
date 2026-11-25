import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
      await _write(target, bytes);
    } on StateError {
      rethrow;
    } catch (e) {
      throw StateError(friendlyPrinterError(e, printerName: target.name));
    } finally {
      // Leaving the link open holds the printer: most BLE heads take one
      // central at a time, so the next print (or another till) cannot reach
      // it. The plugin's disconnect already swallows its own errors.
      try {
        await _ftp.disconnect(device);
      } catch (_) {}
    }
  }

  /// Sends [bytes] over BLE, failing loudly.
  ///
  /// The plugin's own `printData` logs and returns on every failure — not
  /// connected, no writable characteristic, a write error — so a print that
  /// never reached the printer would be reported (and counted) as done.
  Future<void> _write(PrinterTarget target, List<int> bytes) async {
    if (Platform.isWindows) {
      // flutter_blue_plus does not run on Windows; the plugin has its own
      // transport there, so fall back to it.
      final device = Printer(
        address: target.address,
        name: target.name,
        connectionType: ConnectionType.BLE,
      );
      await _ftp.printData(device, bytes, longData: true);
      return;
    }
    final bt = BluetoothDevice.fromId(target.address);
    if (!bt.isConnected) {
      throw StateError('${target.name}: not connected — check it is '
          'switched on and in range');
    }
    BluetoothCharacteristic? out;
    for (final service in await bt.discoverServices()) {
      for (final c in service.characteristics) {
        if (c.properties.write || c.properties.writeWithoutResponse) {
          out = c;
          break;
        }
      }
      if (out != null) break;
    }
    if (out == null) {
      throw StateError('${target.name}: does not accept print data over '
          'Bluetooth — is it an ESC/POS printer?');
    }
    final withResponse = out.properties.write;
    // 3 bytes of ATT header per write; keep a margin like the plugin does.
    final chunk = (bt.mtuNow - 30).clamp(20, 512);
    for (var i = 0; i < bytes.length; i += chunk) {
      final end = i + chunk > bytes.length ? bytes.length : i + chunk;
      await out.write(bytes.sublist(i, end), withoutResponse: !withResponse);
    }
  }
}
