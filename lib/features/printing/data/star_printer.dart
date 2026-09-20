import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';

import 'package:pos_app/features/printing/domain/receipt_printer.dart';
import 'package:pos_app/features/printing/domain/render_receipt_image.dart';

/// [ReceiptPrinter] for Star TSP100III over classic Bluetooth, on top of
/// Star's own StarXpand SDK (see `android/app/.../StarPrinterChannel.kt`).
///
/// The TSP100III is a graphics-only printer: Star's SDK cannot send it text,
/// so the receipt is rasterised here and printed as an image. That is also
/// why this driver renders instead of taking ESC/POS bytes.
///
/// Android only — the bridge exists there because that is where the POS runs.
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
    _requireAndroid();
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
    if (!_isAndroid) return;
    await _methods.invokeMethod<void>('stopDiscovery');
  }

  @override
  Future<void> printReceipt(PrinterTarget target, ReceiptPrintJob job) async {
    _requireAndroid();
    final images = await renderReceiptImages(
      job.data,
      job.fmt,
      job.paperMm,
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
    _requireAndroid();
    final images =
        await renderTestPageImages(storeName: storeName, paperMm: paperMm);
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
        'width': rollPrintWidthDots(paperMm),
      });
    } on PlatformException catch (e) {
      throw StateError(
          'Star printer "${target.name}": ${e.message ?? e.code}');
    }
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _requireAndroid() {
    if (!_isAndroid) {
      throw StateError('Star printers are supported on Android only');
    }
  }
}
