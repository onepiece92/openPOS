package com.brandbuilder.openpos

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var starPrinter: StarPrinterChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        starPrinter = StarPrinterChannel(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        starPrinter?.dispose()
        starPrinter = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
