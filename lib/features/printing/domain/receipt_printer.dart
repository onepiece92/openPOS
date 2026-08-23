import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/features/printing/data/thermal_plugin_printer.dart';

/// How a discovered printer is reachable.
enum PrinterTransport { ble, usb, network }

/// A printer found during a scan, in app terms — no plugin types leak out.
class DiscoveredPrinter {
  const DiscoveredPrinter({
    required this.address,
    required this.name,
    required this.transport,
  });

  /// BLE MAC / USB id — what gets persisted in settings.
  final String address;
  final String name;
  final PrinterTransport transport;
}

/// Port for thermal-receipt printing. The app talks only to this interface;
/// the plugin lives behind [ThermalPluginPrinter] so a driver swap (or the
/// next 0.0.x breaking change in `flutter_thermal_printer`) touches one file,
/// and tests can print into a fake.
abstract interface class ReceiptPrinter {
  /// Devices found by the current/most recent scan.
  Stream<List<DiscoveredPrinter>> get devices;

  /// Begins a BLE scan; results arrive on [devices]. Throws if the scan
  /// cannot start (Bluetooth off, permission missing).
  Future<void> startScan();

  Future<void> stopScan();

  /// Sends raw ESC/POS [bytes] to the printer at [address].
  /// Throws on connect/transmit failure.
  Future<void> printBytes({
    required String address,
    required String name,
    required List<int> bytes,
  });
}

/// The production implementation. Override in tests with a fake.
final receiptPrinterProvider =
    Provider<ReceiptPrinter>((ref) => ThermalPluginPrinter());
