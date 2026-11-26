import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/printing/data/star_printer.dart';
import 'package:pos_app/features/printing/domain/receipt_printer.dart';
import 'package:pos_app/features/printing/presentation/printer_setup_screen.dart';

/// Star (and Classic SPP) printing is Android only: on iOS and macOS the
/// drivers are hidden, saved keys fall back to BLE, and the Star channel —
/// not registered there — fails soft.
class _NoopPrinter implements ReceiptPrinter {
  @override
  Stream<List<DiscoveredPrinter>> get devices => const Stream.empty();
  @override
  Future<void> startScan() async {}
  @override
  Future<void> stopScan() async {}
  @override
  Future<void> printReceipt(PrinterTarget target, ReceiptPrintJob job) async {}
  @override
  Future<void> printTestPage(PrinterTarget target,
      {required String storeName, required int paperMm}) async {}
  @override
  Future<void> printTextSlip(PrinterTarget target, List<String> lines,
      {required int paperMm}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const apple = [TargetPlatform.iOS, TargetPlatform.macOS];

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('PrinterDriver.fromKey', () {
    test('Android keeps every saved driver', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(PrinterDriver.fromKey('escpos'), PrinterDriver.escPos);
      expect(PrinterDriver.fromKey('spp'), PrinterDriver.spp);
      expect(PrinterDriver.fromKey('star'), PrinterDriver.star);
      expect(PrinterDriver.fromKey(null), PrinterDriver.escPos);
      expect(PrinterDriver.fromKey('bogus'), PrinterDriver.escPos);
    });

    for (final p in apple) {
      test('$p maps star and spp to escPos', () {
        debugDefaultTargetPlatformOverride = p;
        expect(classicBluetoothDriversAvailable, isFalse);
        expect(PrinterDriver.fromKey('star'), PrinterDriver.escPos);
        expect(PrinterDriver.fromKey('spp'), PrinterDriver.escPos);
        expect(PrinterDriver.fromKey('escpos'), PrinterDriver.escPos);
      });
    }
  });

  group('StarBluetoothPrinter.isSupported', () {
    test('Android only', () {
      for (final p in TargetPlatform.values) {
        debugDefaultTargetPlatformOverride = p;
        expect(StarBluetoothPrinter.isSupported, p == TargetPlatform.android,
            reason: '$p');
      }
    });
  });

  group('Star channel fails soft', () {
    Matcher androidNote() => isA<StateError>()
        .having((e) => e.message, 'message', kStarUnsupportedNote);

    for (final p in apple) {
      test('$p: guarded before the channel is touched', () async {
        debugDefaultTargetPlatformOverride = p;
        final printer = StarBluetoothPrinter();
        addTearDown(printer.dispose);
        await expectLater(printer.startScan(), throwsA(androidNote()));
        await printer.stopScan(); // no-op, no throw
        await expectLater(
          printer.printTestPage(
            const PrinterTarget(address: 'x', name: 'Star'),
            storeName: 'S',
            paperMm: 80,
          ),
          throwsA(androidNote()),
        );
      });
    }

    test('MissingPluginException is caught as a backstop', () async {
      // Android passes the guard; no handler is registered in tests, so the
      // channel answers MissingPluginException.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final printer = StarBluetoothPrinter();
      addTearDown(printer.dispose);
      await printer.stopScan();
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (_) {}; // EventChannel reports its own miss
      addTearDown(() => FlutterError.onError = oldOnError);
      await expectLater(printer.startScan(), throwsA(androidNote()));
    });
  });

  group('PrinterSetupScreen printer type', () {
    late Box<dynamic> box;

    setUp(() async {
      Hive.init('.');
      box = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
      await box.put(kPrinterDriver, 'star');
    });
    tearDown(Hive.close);

    Future<void> pump(WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 2000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          settingsBoxProvider.overrideWithValue(box),
          escPosPrinterProvider.overrideWithValue(_NoopPrinter()),
          sppPrinterProvider.overrideWithValue(_NoopPrinter()),
          starPrinterProvider.overrideWithValue(_NoopPrinter()),
        ],
        child: const MaterialApp(home: PrinterSetupScreen()),
      ));
      await tester.pumpAndSettle();
    }

    for (final p in apple) {
      testWidgets('$p: BLE only, plus the Android note', (tester) async {
        debugDefaultTargetPlatformOverride = p;
        await pump(tester);
        expect(find.text('Bluetooth LE'), findsOneWidget);
        expect(find.text('Classic'), findsNothing);
        expect(find.text('Star'), findsNothing);
        expect(find.text(kStarUnsupportedNote), findsOneWidget);
        // A saved 'star' preselects BLE instead.
        expect(find.text('Nearby Bluetooth Printers'), findsOneWidget);
        debugDefaultTargetPlatformOverride = null;
      });
    }

    testWidgets('Android: all three segments, no note', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await pump(tester);
      expect(find.text('Bluetooth LE'), findsOneWidget);
      expect(find.text('Classic'), findsOneWidget);
      expect(find.text('Star'), findsOneWidget);
      expect(find.text(kStarUnsupportedNote), findsNothing);
      expect(find.text('Paired Star Printers'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
