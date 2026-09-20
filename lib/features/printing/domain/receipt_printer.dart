import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/printing/data/spp_printer.dart';
import 'package:pos_app/features/printing/data/star_printer.dart';
import 'package:pos_app/features/printing/data/thermal_plugin_printer.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';

/// How a discovered printer is reachable.
enum PrinterTransport { ble, bluetoothClassic, usb, network }

/// Which driver speaks to a printer.
///
/// The two are not interchangeable: an ESC/POS printer wants text commands,
/// while a Star TSP100III is graphics-only and wants a rendered image. The
/// driver that discovered a device is saved alongside it in settings.
enum PrinterDriver {
  /// Bluetooth Low Energy ESC/POS printers, via `flutter_thermal_printer`.
  escPos('escpos'),

  /// Classic-Bluetooth (SPP) ESC/POS printers — the cheap, common kind.
  /// Android only; iOS forbids classic Bluetooth to non-MFi devices.
  spp('spp'),

  /// Star TSP100III over classic Bluetooth, via Star's StarXpand SDK.
  star('star');

  const PrinterDriver(this.key);

  /// Value persisted in settings — see [printerDriverProvider].
  final String key;

  static PrinterDriver fromKey(String? key) =>
      values.firstWhere((d) => d.key == key, orElse: () => escPos);
}

/// A printer found during a scan, in app terms — no plugin types leak out.
class DiscoveredPrinter {
  const DiscoveredPrinter({
    required this.address,
    required this.name,
    required this.transport,
    required this.driver,
    this.likelyPrinter = false,
  });

  /// BLE MAC / USB id / Star device identifier — persisted in settings.
  final String address;
  final String name;
  final PrinterTransport transport;
  final PrinterDriver driver;

  /// The device advertises itself as a printer. Paired classic-Bluetooth
  /// lists are full of phones and headsets, so this sorts the real
  /// candidates to the top.
  final bool likelyPrinter;
}

/// Where to print: the saved device's address plus its display name.
class PrinterTarget {
  const PrinterTarget({required this.address, required this.name});
  final String address;
  final String name;
}

/// Everything a driver needs to produce a sales receipt.
///
/// The job is data, not bytes: each driver encodes it its own way — ESC/POS
/// text for generic printers, a rendered raster image for Star.
class ReceiptPrintJob {
  const ReceiptPrintJob({
    required this.data,
    required this.fmt,
    required this.paperMm,
    this.isCopy = false,
  });

  final ReceiptBodyData data;
  final CurrencyFormatter fmt;

  /// 58 or 80. Other values fall back to 80mm.
  final int paperMm;

  /// Prints a "COPY OF ORIGINAL" banner — set for every reprint so the first
  /// bill stays the only original.
  final bool isCopy;
}

/// Port for thermal-receipt printing. The app talks only to this interface;
/// each driver lives behind its own implementation so a swap (or the next
/// 0.0.x breaking change in `flutter_thermal_printer`) touches one file, and
/// tests can print into a fake.
abstract interface class ReceiptPrinter {
  /// Devices found by the current/most recent scan.
  Stream<List<DiscoveredPrinter>> get devices;

  /// Begins a scan; results arrive on [devices]. Throws if the scan cannot
  /// start (Bluetooth off, permission missing).
  Future<void> startScan();

  Future<void> stopScan();

  /// Renders [job] and sends it to [target]. Throws on connect/transmit
  /// failure.
  Future<void> printReceipt(PrinterTarget target, ReceiptPrintJob job);

  /// Prints a short "this printer works" page — used by printer setup.
  Future<void> printTestPage(
    PrinterTarget target, {
    required String storeName,
    required int paperMm,
  });
}

/// Bluetooth Low Energy ESC/POS driver.
final escPosPrinterProvider =
    Provider<ReceiptPrinter>((ref) => ThermalPluginPrinter());

/// Classic-Bluetooth (SPP) ESC/POS driver.
final sppPrinterProvider = Provider<ReceiptPrinter>((ref) {
  final printer = SppPrinter();
  ref.onDispose(printer.dispose);
  return printer;
});

/// Star TSP100III driver (classic Bluetooth, graphics-only).
final starPrinterProvider = Provider<ReceiptPrinter>((ref) {
  final printer = StarBluetoothPrinter();
  ref.onDispose(printer.dispose);
  return printer;
});

/// The driver for an explicit [PrinterDriver] — used by printer setup, which
/// scans with one driver before anything is saved.
final printerForDriverProvider =
    Provider.family<ReceiptPrinter, PrinterDriver>((ref, driver) =>
        switch (driver) {
          PrinterDriver.escPos => ref.watch(escPosPrinterProvider),
          PrinterDriver.spp => ref.watch(sppPrinterProvider),
          PrinterDriver.star => ref.watch(starPrinterProvider),
        });

/// The driver for the currently saved printer. Override in tests with a fake.
final receiptPrinterProvider = Provider<ReceiptPrinter>((ref) {
  final driver = PrinterDriver.fromKey(ref.watch(printerDriverProvider));
  return ref.watch(printerForDriverProvider(driver));
});
