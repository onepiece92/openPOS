import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/utils/async_feedback.dart';
import 'package:pos_app/features/printing/domain/print_receipt.dart';
import 'package:pos_app/features/printing/domain/render_receipt.dart';

class PrinterSetupScreen extends ConsumerStatefulWidget {
  const PrinterSetupScreen({super.key});

  @override
  ConsumerState<PrinterSetupScreen> createState() => _PrinterSetupScreenState();
}

class _PrinterSetupScreenState extends ConsumerState<PrinterSetupScreen> {
  final _ftp = FlutterThermalPrinter.instance;
  StreamSubscription<List<Printer>>? _devicesSub;
  List<Printer> _devices = [];
  bool _scanning = false;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _devicesSub = _ftp.devicesStream.listen((list) {
      if (mounted) setState(() => _devices = list);
    });
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    _ftp.stopScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _devices = [];
    });
    try {
      await _ftp.getPrinters(connectionTypes: const [ConnectionType.BLE]);
    } catch (_) {
      // Surface a snackbar but keep the page usable.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start Bluetooth scan')),
        );
      }
    }
  }

  Future<void> _stopScan() async {
    await _ftp.stopScan();
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _selectDevice(Printer device) async {
    final box = ref.read(settingsBoxProvider);
    final address = device.address;
    final name = device.name ?? 'Unknown';
    if (address == null || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device has no address')),
      );
      return;
    }
    await savePrinterDevice(box, address: address, name: name);
    ref.invalidate(printerDeviceAddressProvider);
    ref.invalidate(printerDeviceNameProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "$name" as the active printer')),
      );
    }
  }

  Future<void> _disconnectSavedPrinter() async {
    final box = ref.read(settingsBoxProvider);
    await clearPrinterDevice(box);
    ref.invalidate(printerDeviceAddressProvider);
    ref.invalidate(printerDeviceNameProvider);
  }

  Future<void> _printTestPage() async {
    final address = ref.read(printerDeviceAddressProvider);
    final name = ref.read(printerDeviceNameProvider);
    final paper = ref.read(printerPaperWidthProvider);
    final storeName = ref.read(businessNameProvider);
    if (address == null || name == null) return;

    setState(() => _testing = true);
    await withErrorSnackbar(
      context,
      () async {
        final bytes = await renderTestPageBytes(
          storeName: storeName.isEmpty ? 'My Store' : storeName,
          paperMm: paper,
        );
        await printBytesToBleAddress(
          address: address,
          name: name,
          bytes: bytes,
        );
        return true;
      },
      failurePrefix: 'Test print failed',
    );
    if (mounted) setState(() => _testing = false);
  }

  Future<void> _setPaperWidth(int mm) async {
    final box = ref.read(settingsBoxProvider);
    await savePrinterPaperWidth(box, mm);
    ref.invalidate(printerPaperWidthProvider);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final savedAddr = ref.watch(printerDeviceAddressProvider);
    final savedName = ref.watch(printerDeviceNameProvider);
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
                        style: tt.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant))
                  else ...[
                    Text(savedName ?? 'Unknown',
                        style: tt.titleSmall),
                    Text(savedAddr,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
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
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
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
                      Text('Nearby Bluetooth Printers',
                          style: tt.titleMedium),
                      const Spacer(),
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
                        style: tt.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    )
                  else
                    ..._devices.map((d) {
                      final isActive = d.address == savedAddr;
                      return ListTile(
                        leading: Icon(
                          d.connectionType == ConnectionType.BLE
                              ? Icons.bluetooth_rounded
                              : Icons.usb_rounded,
                          color: isActive ? cs.primary : cs.onSurfaceVariant,
                        ),
                        title: Text(d.name ?? 'Unknown'),
                        subtitle: Text(d.address ?? ''),
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
}
