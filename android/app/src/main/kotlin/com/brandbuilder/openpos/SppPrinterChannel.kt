package com.brandbuilder.openpos

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Classic-Bluetooth (SPP) transport for ESC/POS printers — the inexpensive
 * thermal printers that never moved to BLE and therefore cannot be reached
 * by `flutter_thermal_printer`.
 *
 * Deliberately thin: list the devices Android has already paired, and write
 * a finished byte stream to one. Pairing stays in Android's own settings,
 * where the PIN prompt lives.
 *
 * See `lib/features/printing/data/spp_printer.dart`.
 */
class SppPrinterChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val methods = MethodChannel(messenger, CHANNEL).apply {
        setMethodCallHandler(this@SppPrinterChannel)
    }
    private val main = Handler(Looper.getMainLooper())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    fun dispose() {
        methods.setMethodCallHandler(null)
        scope.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pairedDevices" -> pairedDevices(result)
            "printBytes" -> printBytes(call, result)
            else -> result.notImplemented()
        }
    }

    /** Dart requests BLUETOOTH_CONNECT before calling either method. */
    @SuppressLint("MissingPermission")
    private fun pairedDevices(result: MethodChannel.Result) {
        try {
            val adapter = adapter()
            if (adapter == null) {
                result.error("bluetooth_unavailable", "No Bluetooth adapter", null)
                return
            }
            if (!adapter.isEnabled) {
                result.error("bluetooth_off", "Bluetooth is switched off", null)
                return
            }
            result.success(
                adapter.bondedDevices.orEmpty().map { device ->
                    mapOf(
                        "address" to device.address,
                        "name" to (device.name ?: device.address),
                        "printerLike" to device.looksLikePrinter(),
                    )
                },
            )
        } catch (e: SecurityException) {
            result.error("permission_denied", "Bluetooth permission not granted", null)
        }
    }

    @SuppressLint("MissingPermission")
    private fun printBytes(call: MethodCall, result: MethodChannel.Result) {
        val address = call.argument<String>("address")
        val bytes = call.argument<ByteArray>("bytes")
        if (address.isNullOrEmpty() || bytes == null || bytes.isEmpty()) {
            result.error("bad_args", "address and bytes are required", null)
            return
        }

        scope.launch {
            var socket: BluetoothSocket? = null
            try {
                val adapter = adapter() ?: throw IOException("No Bluetooth adapter")
                if (!adapter.isEnabled) throw IOException("Bluetooth is switched off")
                // Discovery starves an RFCOMM connection of bandwidth.
                adapter.cancelDiscovery()

                socket = adapter.getRemoteDevice(address)
                    .createRfcommSocketToServiceRecord(SPP_UUID)
                socket.connect()

                // These printers have small buffers and drop whatever arrives
                // faster than the head can print it, so meter the raster out.
                val out = socket.outputStream
                var offset = 0
                while (offset < bytes.size) {
                    val end = minOf(offset + CHUNK_BYTES, bytes.size)
                    out.write(bytes, offset, end - offset)
                    out.flush()
                    offset = end
                    delay(CHUNK_PAUSE_MILLIS)
                }
                // Closing too early truncates the tail of the receipt.
                delay(DRAIN_MILLIS)
                main.post { result.success(null) }
            } catch (e: SecurityException) {
                main.post {
                    result.error("permission_denied", "Bluetooth permission not granted", null)
                }
            } catch (e: Throwable) {
                main.post { result.error("print_failed", e.message ?: e.toString(), null) }
            } finally {
                runCatching { socket?.close() }
            }
        }
    }

    private fun adapter(): BluetoothAdapter? =
        (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter

    @SuppressLint("MissingPermission")
    private fun BluetoothDevice.looksLikePrinter(): Boolean {
        val deviceClass = bluetoothClass ?: return false
        return deviceClass.majorDeviceClass == BluetoothClass.Device.Major.IMAGING ||
            deviceClass.deviceClass == PRINTER_DEVICE_CLASS
    }

    private companion object {
        const val CHANNEL = "pos_app/spp_printer"

        /** Serial Port Profile — what every ESC/POS printer exposes. */
        val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

        const val CHUNK_BYTES = 1024
        const val CHUNK_PAUSE_MILLIS = 20L
        const val DRAIN_MILLIS = 400L

        /** BluetoothClass "imaging / printer". */
        const val PRINTER_DEVICE_CLASS = 0x0680
    }
}
