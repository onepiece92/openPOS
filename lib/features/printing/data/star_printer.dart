import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';

import 'package:pos_app/features/printing/domain/printer_errors.dart';
import 'package:pos_app/features/printing/domain/receipt_printer.dart';
import 'package:pos_app/features/printing/domain/render_receipt_image.dart';

/// [ReceiptPrinter] for Star TSP100III over classic Bluetooth, on top of
/// Star's own StarXpand SDK (see `android/app/.../StarPrinterChannel.kt`).
///
/// The TSP100III is a graphics-only printer: Star's SDK cannot send it text,
/// so the receipt is rasterised here and printed as an image. That is also
/// why this driver renders instead of taking ESC/POS bytes.
///
/// Implemented on Android and iOS; both talk to the same channel.
class StarBluetoothPrinter implements ReceiptPrinter {
  static const _methods = MethodChannel('pos_app/star_printer');
  static const _discovery = EventChannel('pos_app/star_printer/devices');

  /// Found devices, keyed by identifier so a re-announced printer doesn't
  /// show up twice.
  final _found = <String, DiscoveredPrinter>{};
  final _devices = StreamController<List<DiscoveredPrinter>>.broadcast();
  StreamSubscription<dynamic>? _events;

  @override
  Stream<List<DiscoveredPrinter>> get devices => _devices.stream;

  /// Releases the discovery subscription — wired to the provider's lifetime.
  Future<void> dispose() async {
    await _events?.cancel();
    _events = null;
    await _devices.close();
  }

  @override
  Future<void> startScan() async {
    _requireSupportedPlatform();
    _found.clear();
    _devices.add(const []);
    _events ??= _discovery.receiveBroadcastStream().listen(
      (event) {
        final map = (event as Map).cast<Object?, Object?>();
        final address = map['address'] as String?;
        if (address == null || address.isEmpty) return;
        _found[address] = DiscoveredPrinter(
          address: address,
          name: map['name'] as String? ?? 'Star printer',
          transport: PrinterTransport.bluetoothClassic,
          driver: PrinterDriver.star,
        );
        _devices.add(_found.values.toList());
      },
      onError: _devices.addError,
    );
    await _methods.invokeMethod<void>('startDiscovery');
  }

  @override
  Future<void> stopScan() async {
    if (!_isSupported) return;
    await _methods.invokeMethod<void>('stopDiscovery');
  }

  @override
  Future<void> printReceipt(PrinterTarget target, ReceiptPrintJob job) async {
    _requireSupportedPlatform();
    final images = await renderReceiptImages(
      job.data,
      job.fmt,
      widthDots: starPrintWidthDots(job.paperMm),
      isCopy: job.isCopy,
    );
    await _printImages(target, images, job.paperMm);
  }

  @override
  Future<void> printTestPage(
    PrinterTarget target, {
    required String storeName,
    required int paperMm,
  }) async {
    _requireSupportedPlatform();
    final images = await renderTestPageImages(
      storeName: storeName,
      paperMm: paperMm,
      widthDots: starPrintWidthDots(paperMm),
    );
    await _printImages(target, images, paperMm);
  }

  Future<void> _printImages(
    PrinterTarget target,
    List<Uint8List> images,
    int paperMm,
  ) async {
    try {
      await _methods.invokeMethod<void>('printImages', {
        'address': target.address,
        'images': images,
        'width': starPrintWidthDots(paperMm),
      });
    } on PlatformException catch (e) {
      throw StateError(friendlyPrinterError(e, printerName: target.name));
    }
  }

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  void _requireSupportedPlatform() {
    if (!_isSupported) {
      throw StateError('Star printers are supported on Android and iOS only');
    }
  }
}
