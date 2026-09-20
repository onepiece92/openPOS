import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';

import 'package:pos_app/features/printing/domain/escpos_raster.dart';
import 'package:pos_app/features/printing/domain/printer_errors.dart';
import 'package:pos_app/features/printing/domain/receipt_printer.dart';
import 'package:pos_app/features/printing/domain/render_receipt_image.dart';

/// [ReceiptPrinter] for classic-Bluetooth (SPP) ESC/POS printers — the large
/// family of inexpensive thermal printers that never adopted BLE.
///
/// Android only, and not by choice: iOS refuses classic Bluetooth to
/// anything that is not an MFi accessory, so these printers cannot work on
/// an iPad no matter what the app does.
///
/// "Scanning" lists devices already paired in Android's Bluetooth settings.
/// Pairing needs a PIN prompt the system owns, so it belongs there rather
/// than in this app.
class SppPrinter implements ReceiptPrinter {
  static const _methods = MethodChannel('pos_app/spp_printer');

  final _devices = StreamController<List<DiscoveredPrinter>>.broadcast();

  @override
  Stream<List<DiscoveredPrinter>> get devices => _devices.stream;

  Future<void> dispose() => _devices.close();

  @override
  Future<void> startScan() async {
    _requireAndroid();
    try {
      final paired =
          await _methods.invokeListMethod<Object?>('pairedDevices') ?? const [];
      final found = <DiscoveredPrinter>[];
      for (final entry in paired) {
        final device = (entry as Map).cast<Object?, Object?>();
        final address = device['address'] as String?;
        if (address == null || address.isEmpty) continue;
        found.add(DiscoveredPrinter(
          address: address,
          name: device['name'] as String? ?? address,
          transport: PrinterTransport.bluetoothClassic,
          driver: PrinterDriver.spp,
          // Paired devices include phones and headsets; the bridge flags the
          // ones whose Bluetooth class says "printer" so they sort first.
          likelyPrinter: device['printerLike'] == true,
        ));
      }
      found.sort((a, b) {
        if (a.likelyPrinter == b.likelyPrinter) return a.name.compareTo(b.name);
        return a.likelyPrinter ? -1 : 1;
      });
      _devices.add(found);
    } on PlatformException catch (e) {
      throw StateError(friendlyPrinterError(e, printerName: 'Bluetooth'));
    }
  }

  /// Listing paired devices is instantaneous — there is nothing to stop.
  @override
  Future<void> stopScan() async {}

  @override
  Future<void> printReceipt(PrinterTarget target, ReceiptPrintJob job) async {
    _requireAndroid();
    final pages = await renderReceiptImages(
      job.data,
      job.fmt,
      widthDots: escPosPrintWidthDots(job.paperMm),
      isCopy: job.isCopy,
    );
    await _print(target, pages, job.paperMm);
  }

  @override
  Future<void> printTestPage(
    PrinterTarget target, {
    required String storeName,
    required int paperMm,
  }) async {
    _requireAndroid();
    final pages = await renderTestPageImages(
      storeName: storeName,
      paperMm: paperMm,
      widthDots: escPosPrintWidthDots(paperMm),
    );
    await _print(target, pages, paperMm);
  }

  Future<void> _print(
    PrinterTarget target,
    List<Uint8List> pages,
    int paperMm,
  ) async {
    final bytes = await escPosRasterBytes(pages, paperMm);
    try {
      await _methods.invokeMethod<void>('printBytes', {
        'address': target.address,
        'bytes': Uint8List.fromList(bytes),
      });
    } on PlatformException catch (e) {
      throw StateError(friendlyPrinterError(e, printerName: target.name));
    }
  }

  void _requireAndroid() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw StateError(
          'Classic Bluetooth printers are Android only — iOS allows classic '
          'Bluetooth to MFi accessories only');
    }
  }
}
