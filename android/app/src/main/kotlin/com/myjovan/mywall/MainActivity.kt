package com.myjovan.mywall

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.myjovan.mywall/age_signals"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAgeSignals") {
                try {
                    // Placeholder implementation
                    // Google Play akan menangani age verification di console mereka
                    val map = mapOf(
                        "under13" to false,
                        "parentalSupervision" to false,
                        "ageRange" to "UNKNOWN"
                    )
                    result.success(map)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to get age signals", e.message)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}