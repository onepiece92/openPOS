import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_app/features/printing/domain/receipt_printer.dart';
import 'package:pos_app/features/printing/domain/scan_permissions.dart';

void main() {
  const bluetooth = [Permission.bluetoothScan, Permission.bluetoothConnect];

  group('permissionsForScan', () {
    test('BLE on API 30 and older adds fine location', () {
      for (final sdk in [26, 29, 30]) {
        expect(
          permissionsForScan(sdk, PrinterDriver.escPos),
          [...bluetooth, Permission.locationWhenInUse],
          reason: 'sdk $sdk',
        );
      }
    });

    test('API 31+ never asks for location', () {
      for (final sdk in [31, 33, 35]) {
        expect(permissionsForScan(sdk, PrinterDriver.escPos), bluetooth,
            reason: 'sdk $sdk');
      }
    });

    test('off Android (null sdk) never asks for location', () {
      for (final driver in PrinterDriver.values) {
        expect(permissionsForScan(null, driver), bluetooth);
      }
    });

    test('SPP and Star are not gated on location, even on API 30', () {
      expect(permissionsForScan(30, PrinterDriver.spp), bluetooth);
      expect(permissionsForScan(30, PrinterDriver.star), bluetooth);
      expect(scanNeedsLocation(30, PrinterDriver.spp), isFalse);
      expect(scanNeedsLocation(30, PrinterDriver.star), isFalse);
    });
  });
}
