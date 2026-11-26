import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/utils/async_feedback.dart';
import 'package:pos_app/features/printing/data/android_sdk.dart';
import 'package:pos_app/features/printing/domain/receipt_printer.dart';
import 'package:pos_app/features/printing/domain/scan_permissions.dart';

class PrinterSetupScreen extends ConsumerStatefulWidget {
  const PrinterSetupScreen({super.key});

  @override
  ConsumerState<PrinterSetupScreen> createState() => _PrinterSetupScreenState();
}

class _PrinterSetupScreenState extends ConsumerState<PrinterSetupScreen> {
  /// Driver used for scanning. Starts on whatever the saved printer uses.
  late PrinterDriver _driver =
      PrinterDriver.fromKey(ref.read(printerDriverProvider));

  /// Held directly rather than read through `ref` on demand: [dispose] has
  /// to stop the scan, and `ref` is already unusable by then.
  late ReceiptPrinter _printer = ref.read(printerForDriverProvider(_driver));
  StreamSubscription<List<DiscoveredPrinter>>? _devicesSub;
  List<DiscoveredPrinter> _devices = [];
  bool _scanning = false;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _listenForDevices();
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    // Fire-and-forget: the widget is going away either way, and a failure
    // here must not take the frame down with it.
    unawaited(_printer.stopScan().catchError((_) {}));
    super.dispose();
  }

  void _listenForDevices() {
    _devicesSub?.cancel();
    _devicesSub = _printer.devices.listen((list) {
      if (mounted) setState(() => _devices = list);
    });
  }

  Future<void> _switchDriver(PrinterDriver driver) async {
    if (driver == _driver) return;
    await _stopScan();
    setState(() {
      _driver = driver;
      _printer = ref.read(printerForDriverProvider(driver));
      _devices = [];
    });
    _listenForDevices();
  }

  /// Android 12+ gates Bluetooth scanning and connecting behind runtime
  /// permissions; without them the scan silently finds nothing. Android 11
  /// and older gate BLE scan results behind fine location instead, so that
  /// is asked for too — for the BLE driver only, and only on API 30 and
  /// older (see [permissionsForScan]). Shows its own feedback on denial.
  Future<bool> _ensureBluetoothPermission() async {
    final permissions = permissionsForScan(await AndroidSdk.sdkInt(), _driver);
    final needsLocation = permissions.contains(Permission.locationWhenInUse);

    final statuses = await permissions
        .where((p) => p != Permission.locationWhenInUse)
        .toList()
        .request();
    if (!statuses.values.every((s) => s.isGranted || s.isLimited)) {
      _showPermissionSnackBar(
        'Bluetooth permission is required',
        offerSettings: statuses.values.any((s) => s.isPermanentlyDenied),
      );
      return false;
    }

    if (needsLocation) return _ensureLocationForBle();
    return true;
  }

  /// Fine location for BLE scanning on Android 11 and older.
  Future<bool> _ensureLocationForBle() async {
    const location = Permission.locationWhenInUse;
    var status = await location.status;
    if (status.isGranted || status.isLimited) return true;

    if (!status.isPermanentlyDenied) {
      if (!mounted) return false;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Location access'),
          content: const Text(
            'Android 11 and older require location access to find Bluetooth '
            'printers. This app has no internet access, so your location '
            'never leaves this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (proceed == true) status = await location.request();
    }

    if (status.isGranted || status.isLimited) return true;
    _showPermissionSnackBar(
      'Bluetooth printers can\'t be found without location access. '
      'Paired printers still work.',
      offerSettings: status.isPermanentlyDenied,
    );
    return false;
  }

  void _showPermissionSnackBar(String message, {required bool offerSettings}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: offerSettings
            ? const SnackBarAction(
                label: 'Open settings',
                onPressed: openAppSettings,
              )
            : null,
      ),
    );
  }

  Future<void> _startScan() async {
    if (!await _ensureBluetoothPermission()) return;
    setState(() {
      _scanning = true;
      _devices = [];
    });
    try {
      await _printer.startScan();
    } catch (e) {
      if (mounted) {
        setState(() => _scanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start Bluetooth scan: $e')),
        );
      }
    }
  }

  Future<void> _stopScan() async {
    await _printer.stopScan();
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _selectDevice(DiscoveredPrinter device) async {
    await ref.read(settingsProvider.notifier).setPrinterDevice(
          address: device.address,
          name: device.name,
          driver: device.driver.key,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "${device.name}" as the active printer')),
      );
    }
  }

  Future<void> _disconnectSavedPrinter() =>
      ref.read(settingsProvider.notifier).clearPrinterDevice();

  Future<void> _printTestPage() async {
    final address = ref.read(printerDeviceAddressProvider);
    final name = ref.read(printerDeviceNameProvider);
    final paper = ref.read(printerPaperWidthProvider);
    final storeName = ref.read(settingsProvider).businessNameOrDefault;
    if (address == null || name == null) return;

    setState(() => _testing = true);
    await withErrorSnackbar(
      context,
      () async {
        // Print with the driver the device was saved under, not the one the
        // scan list happens to be showing.
        await ref.read(receiptPrinterProvider).printTestPage(
              PrinterTarget(address: address, name: name),
              storeName: storeName,
              paperMm: paper,
            );
        return true;
      },
      failurePrefix: 'Test print failed',
    );
    if (mounted) setState(() => _testing = false);
  }

  Future<void> _setPaperWidth(int mm) =>
      ref.read(settingsProvider.notifier).setPrinterPaperWidth(mm);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final savedAddr = ref.watch(printerDeviceAddressProvider);
    final savedName = ref.watch(printerDeviceNameProvider);
    final savedDriver = PrinterDriver.fromKey(ref.watch(printerDriverProvider));
    final paper = ref.watch(printerPaperWidthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Printer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Saved printer card ────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Printer', style: tt.titleMedium),
                  const SizedBox(height: 8),
                  if (savedAddr == null)
                    Text('None paired yet',
                        style:
                            tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
                  else ...[
                    Text(savedName ?? 'Unknown', style: tt.titleSmall),
                    Text(
                      '$savedAddr · ${_driverLabel(savedDriver)}',
                      style:
                          tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _testing ? null : _printTestPage,
                            icon: _testing
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.print_outlined),
                            label: const Text('Print Test Page'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: _disconnectSavedPrinter,
                            icon: const Icon(Icons.link_off_rounded),
                            label: const Text('Forget'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Printer type ──────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Printer Type', style: tt.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    _driverHelp(_driver),
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<PrinterDriver>(
                    showSelectedIcon: false,
                    segments: [
                      const ButtonSegment(
                        value: PrinterDriver.escPos,
                        label: Text('Bluetooth LE'),
                      ),
                      if (classicBluetoothDriversAvailable) ...const [
                        ButtonSegment(
                          value: PrinterDriver.spp,
                          label: Text('Classic'),
                        ),
                        ButtonSegment(
                          value: PrinterDriver.star,
                          label: Text('Star'),
                        ),
                      ],
                    ],
                    selected: {_driver},
                    onSelectionChanged: (s) => _switchDriver(s.first),
                  ),
                  if (!classicBluetoothDriversAvailable) ...[
                    const SizedBox(height: 8),
                    Text(
                      kStarAndroidOnlyNote,
                      style:
                          tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Paper width ───────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Paper Width', style: tt.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Match your printer roll. Receipts are reformatted automatically.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 58, label: Text('58 mm')),
                      ButtonSegment(value: 80, label: Text('80 mm')),
                    ],
                    selected: {paper},
                    onSelectionChanged: (s) => _setPaperWidth(s.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Scan card ─────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          switch (_driver) {
                            PrinterDriver.escPos => 'Nearby Bluetooth Printers',
                            PrinterDriver.spp => 'Paired Printers',
                            PrinterDriver.star => 'Paired Star Printers',
                          },
                          style: tt.titleMedium,
                        ),
                      ),
                      if (_scanning)
                        TextButton.icon(
                          onPressed: _stopScan,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('Stop'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: _startScan,
                          icon: const Icon(Icons.bluetooth_searching_rounded),
                          label: Text(_driver == PrinterDriver.spp
                              ? 'List'
                              : 'Scan'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_devices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _scanning
                            ? 'Scanning for printers…'
                            : _driver == PrinterDriver.spp
                                ? 'Tap List to show printers paired in Android '
                                    'Bluetooth settings.'
                                : 'Tap Scan to find a printer.',
                        style:
                            tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    )
                  else
                    ..._devices.map((d) {
                      final isActive = d.address == savedAddr;
                      return ListTile(
                        leading: Icon(
                          switch (d.transport) {
                            PrinterTransport.usb => Icons.usb_rounded,
                            PrinterTransport.network => Icons.lan_rounded,
                            _ => Icons.bluetooth_rounded,
                          },
                          color: isActive ? cs.primary : cs.onSurfaceVariant,
                        ),
                        title: Text(d.name),
                        subtitle: Text(d.address),
                        trailing: isActive
                            ? Icon(Icons.check_circle_rounded,
                                color: cs.primary)
                            : const Icon(Icons.chevron_right_rounded),
                        onTap: () => _selectDevice(d),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _driverLabel(PrinterDriver driver) => switch (driver) {
        PrinterDriver.escPos => 'Bluetooth LE',
        PrinterDriver.spp => 'Bluetooth Classic',
        PrinterDriver.star => 'Star',
      };

  String _driverHelp(PrinterDriver driver) => switch (driver) {
        PrinterDriver.escPos =>
          'Most newer ESC/POS printers. Switch the printer on and scan — no '
              'pairing needed.',
        PrinterDriver.spp =>
          'Older and cheaper ESC/POS printers. Pair the printer in Android '
              'Bluetooth settings first, then list it here. Not available on '
              'iPhone or iPad, which only allow certified accessories.',
        PrinterDriver.star =>
          'Star TSP100III and friends. Pair in Bluetooth settings first. '
              'These print receipts as images — they cannot be sent text.',
      };
}
