import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/utils/async_feedback.dart';
import 'package:pos_app/features/printing/domain/receipt_printer.dart';

class PrinterSetupScreen extends ConsumerStatefulWidget {
  const PrinterSetupScreen({super.key});

  @override
  ConsumerState<PrinterSetupScreen> createState() => _PrinterSetupScreenState();
}

class _PrinterSetupScreenState extends ConsumerState<PrinterSetupScreen> {
  /// Driver used for scanning. Starts on whatever the saved printer uses.
  late PrinterDriver _driver =
      PrinterDriver.fromKey(ref.read(printerDriverProvider));

  ReceiptPrinter get _printer => ref.read(printerForDriverProvider(_driver));
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
    _printer.stopScan();
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
      _devices = [];
    });
    _listenForDevices();
  }

  /// Android 12+ gates Bluetooth scanning and connecting behind runtime
  /// permissions; without them the scan silently finds nothing.
  Future<bool> _ensureBluetoothPermission() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  Future<void> _startScan() async {
    if (!await _ensureBluetoothPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth permission is required')),
        );
      }
      return;
    }
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
                    'Star prints receipts as images — the TSP100III cannot be '
                    'sent text. Pair the printer in Android Bluetooth settings '
                    'first, then scan here.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<PrinterDriver>(
                    segments: const [
                      ButtonSegment(
                        value: PrinterDriver.escPos,
                        label: Text('ESC/POS'),
                      ),
                      ButtonSegment(
                        value: PrinterDriver.star,
                        label: Text('Star'),
                      ),
                    ],
                    selected: {_driver},
                    onSelectionChanged: (s) => _switchDriver(s.first),
                  ),
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
                          _driver == PrinterDriver.star
                              ? 'Paired Star Printers'
                              : 'Nearby Bluetooth Printers',
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
                          label: const Text('Scan'),
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
        PrinterDriver.escPos => 'ESC/POS',
        PrinterDriver.star => 'Star',
      };
}
