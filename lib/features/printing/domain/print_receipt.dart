import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

/// Send raw ESC/POS bytes to a Bluetooth thermal printer at [address].
///
/// Connects (no-op if already connected), sends, returns. Throws on any
/// failure — caller decides whether to surface a snackbar or swallow it.
///
/// USB and network connection types are not handled here yet — see Phase 4
/// follow-ups. For now any non-BLE device address will throw.
Future<void> printBytesToBleAddress({
  required String address,
  required String name,
  required List<int> bytes,
}) async {
  final ftp = FlutterThermalPrinter.instance;
  final device = Printer(
    address: address,
    name: name,
    connectionType: ConnectionType.BLE,
  );

  final connected = await ftp.connect(device);
  if (!connected) {
    throw StateError('Failed to connect to printer "$name" ($address)');
  }
  await ftp.printData(device, bytes, longData: true);
}
