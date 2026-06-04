package com.kreativekarakana.karakana

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "karakana/screenshot")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableScreenshotPrevention" -> {
                        window.setFlags(
                            android.view.WindowManager.LayoutParams.FLAG_SECURE,
                            android.view.WindowManager.LayoutParams.FLAG_SECURE
                        )
                        result.success(null)
                    }
                    "disableScreenshotPrevention" -> {
                        window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    "isScreenCaptured" -> {
                        // Android screen capture detection is device/vendor specific;
                        // FLAG_SECURE is primary protection.
                        result.success(false)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
