
package com.example.ramana
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// 🔥 IMPORTANT IMPORT
import com.example.ramana.printer.PrintHelper

class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.tvs.pos/printer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // OLD CHANNEL (optional)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "printText" -> {
                        val content = call.argument<String>("content")
                        if (content != null) {
                            result.success("Printing Started")
                        } else {
                            result.error("INVALID_ARGUMENT", "Content is null", null)
                        }
                    }
                    "cutPaper" -> {
                        result.success("Paper Cut")
                    }
                    else -> result.notImplemented()
                }
            }

        // 🔥 MAIN PRINTER CHANNEL
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tvs_printer")
            .setMethodCallHandler { call, result ->

                if (call.method == "printBitmap") {

                    val bytes = call.argument<ByteArray>("bytes")
                    val cutMode = call.argument<String>("cutMode") ?: "NORMAL"

                    if (bytes != null) {

                        val resultMessage =
                            PrintHelper.printBitmap(bytes, cutMode)

                        result.success(resultMessage)

                    } else {

                        result.error(
                            "NO_DATA",
                            "Bytes null",
                            null
                        )
                    }
                }



                else {

                    result.notImplemented()
                }
            }
    }
}