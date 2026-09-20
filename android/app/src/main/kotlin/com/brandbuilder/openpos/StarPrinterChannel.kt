package com.brandbuilder.openpos

import android.content.Context
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import com.starmicronics.stario10.InterfaceType
import com.starmicronics.stario10.StarConnectionSettings
import com.starmicronics.stario10.StarDeviceDiscoveryManager
import com.starmicronics.stario10.StarDeviceDiscoveryManagerFactory
import com.starmicronics.stario10.StarPrinter
import com.starmicronics.stario10.starxpandcommand.DocumentBuilder
import com.starmicronics.stario10.starxpandcommand.PrinterBuilder
import com.starmicronics.stario10.starxpandcommand.StarXpandCommandBuilder
import com.starmicronics.stario10.starxpandcommand.printer.CutType
import com.starmicronics.stario10.starxpandcommand.printer.ImageParameter
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Bridge to Star's StarXpand SDK for TSP100III printers over classic
 * Bluetooth. Deliberately thin: discovery and printing an already-rendered
 * image, nothing else.
 *
 * The TSP100III is graphics-only — it cannot be sent text — so the Dart side
 * rasterises the receipt and passes PNG pages down. See
 * `lib/features/printing/data/star_printer.dart`.
 *
 * Only the Bluetooth interface is enabled here. The app is offline by
 * design, so LAN/Wi-Fi printer discovery is intentionally never requested.
 */
class StarPrinterChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val methods = MethodChannel(messenger, METHOD_CHANNEL).apply {
        setMethodCallHandler(this@StarPrinterChannel)
    }
    private val discoveryEvents = EventChannel(messenger, EVENT_CHANNEL).apply {
        setStreamHandler(this@StarPrinterChannel)
    }

    private val main = Handler(Looper.getMainLooper())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var manager: StarDeviceDiscoveryManager? = null
    private var sink: EventChannel.EventSink? = null

    fun dispose() {
        stopDiscovery()
        methods.setMethodCallHandler(null)
        discoveryEvents.setStreamHandler(null)
        scope.cancel()
    }

    // ── EventChannel.StreamHandler ────────────────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    // ── MethodChannel.MethodCallHandler ───────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startDiscovery" -> startDiscovery(result)
            "stopDiscovery" -> {
                stopDiscovery()
                result.success(null)
            }
            "printImages" -> printImages(call, result)
            else -> result.notImplemented()
        }
    }

    private fun startDiscovery(result: MethodChannel.Result) {
        stopDiscovery()
        try {
            val found = StarDeviceDiscoveryManagerFactory.create(
                listOf(InterfaceType.Bluetooth),
                context,
            )
            found.discoveryTime = DISCOVERY_MILLIS
            found.callback = object : StarDeviceDiscoveryManager.Callback {
                override fun onPrinterFound(printer: StarPrinter) {
                    val model = printer.information?.model?.name
                    main.post {
                        sink?.success(
                            mapOf(
                                "address" to printer.connectionSettings.identifier,
                                "name" to (model ?: "Star printer"),
                            ),
                        )
                    }
                }

                override fun onDiscoveryFinished() {
                    main.post { sink?.success(mapOf("finished" to true)) }
                }
            }
            found.startDiscovery()
            manager = found
            result.success(null)
        } catch (e: Throwable) {
            // Bluetooth off, permission not granted, SDK failure — the Dart
            // side turns this into a snackbar.
            result.error("discovery_failed", e.message ?: e.toString(), null)
        }
    }

    private fun stopDiscovery() {
        manager?.stopDiscovery()
        manager = null
    }

    private fun printImages(call: MethodCall, result: MethodChannel.Result) {
        val address = call.argument<String>("address")
        val images = call.argument<List<ByteArray>>("images")
        val width = call.argument<Int>("width") ?: DEFAULT_WIDTH_DOTS
        if (address.isNullOrEmpty() || images.isNullOrEmpty()) {
            result.error("bad_args", "address and images are required", null)
            return
        }

        scope.launch {
            val printer = StarPrinter(
                StarConnectionSettings(InterfaceType.Bluetooth, address),
                context,
            )
            try {
                val page = PrinterBuilder()
                for (bytes in images) {
                    val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                        ?: throw IllegalArgumentException("Receipt image could not be decoded")
                    page.actionPrintImage(ImageParameter(bitmap, width))
                }
                page.actionCut(CutType.Partial)

                val commands = StarXpandCommandBuilder()
                    .addDocument(DocumentBuilder().addPrinter(page))
                    .getCommands()

                printer.openAsync().await()
                printer.printAsync(commands).await()
                main.post { result.success(null) }
            } catch (e: Throwable) {
                main.post {
                    result.error("print_failed", e.message ?: e.toString(), null)
                }
            } finally {
                runCatching { printer.closeAsync().await() }
            }
        }
    }

    private companion object {
        const val METHOD_CHANNEL = "pos_app/star_printer"
        const val EVENT_CHANNEL = "pos_app/star_printer/devices"
        const val DISCOVERY_MILLIS = 10_000
        /** 72mm of printable width at 203 dpi — an 80mm roll. */
        const val DEFAULT_WIDTH_DOTS = 576
    }
}
