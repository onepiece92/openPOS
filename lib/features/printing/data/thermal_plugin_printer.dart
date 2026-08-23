import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

import 'package:pos_app/features/printing/domain/receipt_printer.dart';

/// [ReceiptPrinter] backed by the `flutter_thermal_printer` plugin (BLE).
/// The only file in the app that imports the plugin.
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
                ),
          ]);

  @override
  Future<void> startScan() =>
      _ftp.getPrinters(connectionTypes: const [ConnectionType.BLE]);

  @override
  Future<void> stopScan() => _ftp.stopScan();

  @override
  Future<void> printBytes({
    required String address,
    required String name,
    required List<int> bytes,
  }) async {
    final device = Printer(
      address: address,
      name: name,
      connectionType: ConnectionType.BLE,
    );
    final connected = await _ftp.connect(device);
    if (!connected) {
      throw StateError('Failed to connect to printer "$name" ($address)');
    }
    await _ftp.printData(device, bytes, longData: true);
  }
}
