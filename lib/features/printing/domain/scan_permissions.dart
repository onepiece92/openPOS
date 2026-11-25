import 'package:permission_handler/permission_handler.dart';

import 'package:pos_app/features/printing/domain/receipt_printer.dart';

/// Last Android API level on which BLE scan results are gated behind
/// location access. Android 12 (API 31) replaced that with BLUETOOTH_SCAN.
const int lastSdkNeedingLocationForBle = 30;

/// Whether a scan with [driver] on Android [sdkInt] needs fine location.
///
/// Only BLE scanning ([PrinterDriver.escPos]) does: SPP and Star list
/// already-paired devices, which never needed location. [sdkInt] is null
/// off Android, where location is never requested.
bool scanNeedsLocation(int? sdkInt, PrinterDriver driver) =>
    driver == PrinterDriver.escPos &&
    sdkInt != null &&
    sdkInt <= lastSdkNeedingLocationForBle;

/// Runtime permissions to request before scanning with [driver].
///
/// Bluetooth scan + connect always (permission_handler reports them as
/// granted below API 31, where they are install-time). Fine location is
/// added only for BLE on API 30 and older — see [scanNeedsLocation].
List<Permission> permissionsForScan(int? sdkInt, PrinterDriver driver) => [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      if (scanNeedsLocation(sdkInt, driver)) Permission.locationWhenInUse,
    ];
