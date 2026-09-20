import Flutter
import StarIO10
import UIKit

/// Bridge to Star's StarXpand SDK for TSP100III printers over Bluetooth.
/// Mirrors `android/app/src/main/kotlin/.../StarPrinterChannel.kt`:
/// discovery and printing an already-rendered image, nothing else.
///
/// The TSP100III is graphics-only — it cannot be sent text — so the Dart
/// side rasterises the receipt and passes PNG pages down. See
/// `lib/features/printing/data/star_printer.dart`.
///
/// On iOS the printer is an MFi accessory: it must be paired in Settings ›
/// Bluetooth, and the app must declare `jp.star-m.starpro` under
/// `UISupportedExternalAccessoryProtocols` in Info.plist, or discovery
/// finds nothing.
///
/// Only the Bluetooth interface is enabled here. The app is offline by
/// design, so LAN/Wi-Fi printer discovery is intentionally never requested.
final class StarPrinterChannel: NSObject {
    private static let methodChannelName = "pos_app/star_printer"
    private static let eventChannelName = "pos_app/star_printer/devices"
    private static let discoveryMillis = 10_000
    /// 72mm of printable width at 203 dpi — an 80mm roll.
    private static let defaultWidthDots = 576

    private let methods: FlutterMethodChannel
    private let discoveryEvents: FlutterEventChannel
    private var manager: (any StarDeviceDiscoveryManager)?
    private var sink: FlutterEventSink?

    init(messenger: FlutterBinaryMessenger) {
        methods = FlutterMethodChannel(
            name: Self.methodChannelName, binaryMessenger: messenger)
        discoveryEvents = FlutterEventChannel(
            name: Self.eventChannelName, binaryMessenger: messenger)
        super.init()
        methods.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
        discoveryEvents.setStreamHandler(self)
    }

    func dispose() {
        stopDiscovery()
        methods.setMethodCallHandler(nil)
        discoveryEvents.setStreamHandler(nil)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startDiscovery":
            startDiscovery(result)
        case "stopDiscovery":
            stopDiscovery()
            result(nil)
        case "printImages":
            printImages(call.arguments as? [String: Any] ?? [:], result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // ── Discovery ─────────────────────────────────────────────────────────

    private func startDiscovery(_ result: @escaping FlutterResult) {
        stopDiscovery()
        do {
            let found = try StarDeviceDiscoveryManagerFactory.create(
                interfaceTypes: [InterfaceType.bluetooth])
            found.discoveryTime = Self.discoveryMillis
            found.delegate = self
            try found.startDiscovery()
            manager = found
            result(nil)
        } catch {
            // Bluetooth off, accessory protocol not declared, SDK failure —
            // the Dart side turns this into a snackbar.
            result(FlutterError(
                code: "discovery_failed",
                message: "\(error)",
                details: nil))
        }
    }

    private func stopDiscovery() {
        manager?.stopDiscovery()
        manager = nil
    }

    // ── Printing ──────────────────────────────────────────────────────────

    private func printImages(_ args: [String: Any], _ result: @escaping FlutterResult) {
        guard let address = args["address"] as? String, !address.isEmpty,
              let pages = args["images"] as? [FlutterStandardTypedData], !pages.isEmpty
        else {
            result(FlutterError(
                code: "bad_args",
                message: "address and images are required",
                details: nil))
            return
        }
        let width = args["width"] as? Int ?? Self.defaultWidthDots

        let images = pages.compactMap { UIImage(data: $0.data) }
        guard images.count == pages.count else {
            result(FlutterError(
                code: "print_failed",
                message: "Receipt image could not be decoded",
                details: nil))
            return
        }

        let page = StarXpandCommand.PrinterBuilder()
        for image in images {
            _ = page.actionPrintImage(
                StarXpandCommand.Printer.ImageParameter(image: image, width: width))
        }
        _ = page.actionCut(StarXpandCommand.Printer.CutType.partial)

        let commands = StarXpandCommand.StarXpandCommandBuilder()
            .addDocument(StarXpandCommand.DocumentBuilder().addPrinter(page))
            .getCommands()

        let printer = StarPrinter(
            StarConnectionSettings(interfaceType: .bluetooth, identifier: address))

        Task {
            do {
                try await printer.open()
                try await printer.print(command: commands)
                await printer.close()
                Self.onMain { result(nil) }
            } catch {
                await printer.close()
                Self.onMain {
                    result(FlutterError(
                        code: "print_failed",
                        message: "\(error)",
                        details: nil))
                }
            }
        }
    }

    /// Channel replies and events must reach Flutter on the platform thread.
    private static func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}

// ── Discovery results ─────────────────────────────────────────────────────

extension StarPrinterChannel: StarDeviceDiscoveryManagerDelegate {
    func manager(_ manager: any StarDeviceDiscoveryManager, didFind printer: StarPrinter) {
        let identifier = printer.connectionSettings.identifier
        let model = printer.information.map { String(describing: $0.model) }
        Self.onMain { [weak self] in
            self?.sink?([
                "address": identifier,
                "name": model ?? "Star printer",
            ])
        }
    }

    func managerDidFinishDiscovery(_ manager: any StarDeviceDiscoveryManager) {
        Self.onMain { [weak self] in
            self?.sink?(["finished": true])
        }
    }
}

// ── Discovery event stream ────────────────────────────────────────────────

extension StarPrinterChannel: FlutterStreamHandler {
    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        sink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }
}
