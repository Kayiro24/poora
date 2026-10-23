package com.poora.app

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

/**
 * "poora/usage": optional distracting-app detection for focus sessions.
 * Uses Usage access (PACKAGE_USAGE_STATS), which the user grants in system
 * settings. Everything is computed on the device; nothing leaves it.
 */
class UsageChannel(private val context: Context, messenger: BinaryMessenger) {
    private val io = Executors.newSingleThreadExecutor()

    init {
        MethodChannel(messenger, "poora/usage").setMethodCallHandler { call, result ->
            when (call.method) {
                "hasAccess" -> result.success(hasAccess())
                "requestAccess" -> {
                    context.startActivity(
                        Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                    result.success(null)
                }
                "launchableApps" -> io.execute {
                    val apps = launchableApps()
                    android.os.Handler(context.mainLooper).post { result.success(apps) }
                }
                "usage" -> {
                    val from = call.argument<Number>("from")!!.toLong()
                    val to = call.argument<Number>("to")!!.toLong()
                    val packages = call.argument<List<String>>("packages")!!.toSet()
                    if (!hasAccess()) {
                        result.success(emptyMap<String, Long>())
                    } else {
                        io.execute {
                            val usage = foregroundTime(from, to, packages)
                            android.os.Handler(context.mainLooper).post { result.success(usage) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasAccess(): Boolean {
        val ops = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ops.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        } else {
            @Suppress("DEPRECATION")
            ops.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /** Apps with a launcher icon (excluding Poora), sorted by name, with a small PNG icon. */
    private fun launchableApps(): List<Map<String, Any>> {
        val pm = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val infos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(intent, 0)
        }
        return infos
            .filter { it.activityInfo.packageName != context.packageName }
            .distinctBy { it.activityInfo.packageName }
            .map { info ->
                mapOf(
                    "package" to info.activityInfo.packageName,
                    "label" to info.loadLabel(pm).toString(),
                    "icon" to iconPng(info.loadIcon(pm)),
                )
            }
            .sortedBy { (it["label"] as String).lowercase() }
    }

    private fun iconPng(d: android.graphics.drawable.Drawable): ByteArray {
        val size = 72
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        d.setBounds(0, 0, size, size)
        d.draw(c)
        val out = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
        bmp.recycle()
        return out.toByteArray()
    }

    /** Milliseconds each of [packages] spent in the foreground between [from] and [to]. */
    private fun foregroundTime(from: Long, to: Long, packages: Set<String>): Map<String, Long> {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usm.queryEvents(from, to)
        val openedAt = HashMap<String, Long>()
        val total = HashMap<String, Long>()
        val e = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(e)
            val pkg = e.packageName ?: continue
            if (pkg !in packages) continue
            when (e.eventType) {
                UsageEvents.Event.MOVE_TO_FOREGROUND -> openedAt[pkg] = e.timeStamp
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    val start = openedAt.remove(pkg) ?: continue
                    total[pkg] = (total[pkg] ?: 0L) + (e.timeStamp - start).coerceAtLeast(0L)
                }
            }
        }
        // Still open when the window ended.
        for ((pkg, start) in openedAt) total[pkg] = (total[pkg] ?: 0L) + (to - start).coerceAtLeast(0L)
        return total.filterValues { it > 0L }
    }
}
