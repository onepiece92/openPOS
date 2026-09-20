package com.brandbuilder.openpos

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var starPrinter: StarPrinterChannel? = null
    private var sppPrinter: SppPrinterChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        starPrinter = StarPrinterChannel(applicationContext, messenger)
        sppPrinter = SppPrinterChannel(applicationContext, messenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        starPrinter?.dispose()
        starPrinter = null
        sppPrinter?.dispose()
        sppPrinter = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
