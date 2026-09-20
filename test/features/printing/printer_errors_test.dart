import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/printing/domain/printer_errors.dart';

/// Printer failures are read standing at a counter mid-sale, so they have to
/// say what to do, not which SDK class threw.

void main() {
  test('Star SDK error types become an instruction', () {
    final notFound = friendlyPrinterError(
      PlatformException(code: 'print_failed', message: 'StarIO10NotFoundError'),
      printerName: 'TSP100III',
    );
    expect(notFound, startsWith('TSP100III: '));
    expect(notFound, contains('paired'));
    expect(notFound, isNot(contains('StarIO10')),
        reason: 'the SDK class name helps nobody behind a counter');

    expect(
      friendlyPrinterError(
        PlatformException(code: 'print_failed', message: 'StarIO10InUseError'),
        printerName: 'TSP100III',
      ),
      contains('busy'),
    );
    expect(
      friendlyPrinterError(
        PlatformException(
            code: 'print_failed', message: 'StarIO10UnprintableError'),
        printerName: 'TSP100III',
      ),
      contains('paper'),
    );
  });

  test('bridge-level codes become plain English', () {
    expect(
      friendlyPrinterError(
        PlatformException(code: 'bluetooth_off', message: 'Bluetooth is off'),
        printerName: 'Rongta',
      ),
      'Rongta: Bluetooth is switched off',
    );
    expect(
      friendlyPrinterError(
        PlatformException(code: 'permission_denied', message: 'denied'),
        printerName: 'Rongta',
      ),
      contains('permission'),
    );
  });

  test('a dropped classic-Bluetooth socket suggests the fix', () {
    final message = friendlyPrinterError(
      PlatformException(
          code: 'print_failed', message: 'java.io.IOException: read failed'),
      printerName: 'XP-58',
    );
    expect(message, contains('XP-58'));
    expect(message, anyOf(contains('switch the printer off'), contains('closer')));
  });

  test('an unrecognised failure keeps its original text', () {
    expect(
      friendlyPrinterError(StateError('kaboom'), printerName: 'Rongta'),
      contains('kaboom'),
    );
    expect(
      friendlyPrinterError(
        PlatformException(code: 'weird', message: 'something odd happened'),
        printerName: 'Rongta',
      ),
      'Rongta: something odd happened',
    );
  });
}
