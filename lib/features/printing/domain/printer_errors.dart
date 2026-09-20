import 'package:flutter/services.dart' show PlatformException;

/// Turns a driver failure into something a shopkeeper can act on.
///
/// The platform channels hand back SDK error names and Java/Swift exception
/// text, which says nothing useful behind a counter. Anything unrecognised
/// falls through with its original text rather than being swallowed.
String friendlyPrinterError(Object error, {required String printerName}) {
  final raw = error is PlatformException
      ? '${error.code} ${error.message ?? ''}'
      : error.toString();

  final known = _match(raw);
  if (known != null) return '$printerName: $known';
  return '$printerName: ${error is PlatformException ? error.message ?? error.code : error}';
}

String? _match(String raw) {
  // Channel-level failures raised by our own bridges.
  if (raw.contains('bluetooth_off')) {
    return 'Bluetooth is switched off';
  }
  if (raw.contains('permission_denied')) {
    return 'Bluetooth permission is not granted';
  }
  if (raw.contains('bluetooth_unavailable')) {
    return 'This device has no Bluetooth';
  }

  // Star StarXpand SDK error types (same names on Android and iOS).
  if (raw.contains('NotFound')) {
    return 'Printer not found — check it is switched on, paired and in range';
  }
  if (raw.contains('InUse')) {
    return 'Printer is busy — another device or app is connected to it';
  }
  if (raw.contains('Communication') || raw.contains('IOException')) {
    return 'Lost connection to the printer — move closer and try again';
  }
  if (raw.contains('Unprintable')) {
    return 'Printer cannot print — check the paper roll and that the cover is shut';
  }
  if (raw.contains('DeviceHasError')) {
    return 'Printer reports an error — check paper, cover and any jam';
  }
  if (raw.contains('Unsupported')) {
    return 'This printer model is not supported by the Star driver';
  }

  // Classic-Bluetooth socket failures surface as plain IO text.
  if (raw.contains('read failed') ||
      raw.contains('socket might closed') ||
      raw.contains('Connection refused')) {
    return 'Could not open the printer connection — switch the printer off and on, then retry';
  }
  return null;
}
