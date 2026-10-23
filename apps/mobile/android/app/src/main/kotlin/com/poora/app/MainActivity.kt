package com.poora.app

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the small "poora/dnd" channel used by "Silence phone during focus".
 * Reads/writes NotificationManager's interruption filter so the previous state
 * can be saved and restored exactly.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        UsageChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        GuardChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        // Fallback after a denied permission: Poora's notification settings.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "poora/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNotificationSettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "poora/dnd")
            .setMethodCallHandler { call, result ->
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                when (call.method) {
                    "hasAccess" -> result.success(nm.isNotificationPolicyAccessGranted)
                    "requestAccess" -> {
                        startActivity(
                            Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(null)
                    }
                    "getFilter" -> result.success(nm.currentInterruptionFilter)
                    "setFilter" -> {
                        val filter = call.argument<Int>("filter")
                        if (filter == null || !nm.isNotificationPolicyAccessGranted) {
                            result.success(false)
                        } else {
                            nm.setInterruptionFilter(filter)
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
