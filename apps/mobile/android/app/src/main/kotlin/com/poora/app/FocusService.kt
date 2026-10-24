package com.poora.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.text.DateFormat
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.TemporalAdjusters
import java.util.Date

/**
 * Poora's always-on foreground service:
 *  - the **focus bar** notification: today's and this week's total focus,
 *    or the running session with a live countdown;
 *  - the **focus guard** without Accessibility: while a focus phase is armed
 *    it checks the foreground app (Usage access) and covers blocked apps —
 *    and in strict mode the package installer and Settings — with the block
 *    screen (needs "Display over other apps" to start from the background);
 *  - strict mode: swiping Poora away during strict focus brings it back.
 * Keeps running when Poora's UI is closed; restarted after a reboot.
 */
class FocusService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var lastText = ""
    private var lastNotified = 0L
    private var lastBlock = 0L

    private val tick = object : Runnable {
        override fun run() {
            val guard = GuardState.read(this@FocusService)
            refreshBar(force = false)
            if (guard.active) checkForeground(guard)
            handler.postDelayed(this, if (guard.active) 600L else 20_000L)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createChannel(this)
        val n = buildBar(this, System.currentTimeMillis())
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIFICATION_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, n)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        handler.removeCallbacks(tick)
        refreshBar(force = true)
        handler.post(tick)
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(tick)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /** Strict focus: closing Poora from Recents doesn't end it — Poora comes straight back. */
    override fun onTaskRemoved(rootIntent: Intent?) {
        val g = GuardState.read(this)
        if (g.active && g.strict) {
            startActivity(
                Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
        super.onTaskRemoved(rootIntent)
    }

    private fun refreshBar(force: Boolean) {
        val now = System.currentTimeMillis()
        val text = barText(this, now)
        // Only re-post when what's shown changes (or every minute for the chronometer).
        if (!force && text == lastText && now - lastNotified < 60_000) return
        lastText = text
        lastNotified = now
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).notify(NOTIFICATION_ID, buildBar(this, now))
    }

    private fun checkForeground(guard: GuardState.State) {
        val pkg = foregroundPackage() ?: return
        if (pkg == packageName) return
        val strictHit = guard.strict && isGuardedSystemPackage(pkg)
        if (pkg !in guard.blocked && !strictHit) return
        val now = System.currentTimeMillis()
        if (now - lastBlock < 1500) return
        lastBlock = now
        startActivity(
            Intent(this, BlockedActivity::class.java)
                .putExtra(BlockedActivity.EXTRA_PACKAGE, pkg)
                .putExtra(BlockedActivity.EXTRA_STRICT, strictHit)
                .putExtra(BlockedActivity.EXTRA_UNTIL, guard.activeUntil)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
        )
    }

    /** The app most recently brought to the foreground, from usage events. */
    private fun foregroundPackage(): String? {
        val usm = getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val events = usm.queryEvents(now - 10_000, now)
        val e = UsageEvents.Event()
        var last: String? = null
        while (events.hasNextEvent()) {
            events.getNextEvent(e)
            if (e.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) last = e.packageName
        }
        // Nothing moved in the window: the previous app is still in front.
        if (last != null) lastSeenForeground = last
        return lastSeenForeground
    }

    private var lastSeenForeground: String? = null

    companion object {
        const val NOTIFICATION_ID = 7001
        private const val CHANNEL = "focus_bar"
        private const val PREFS = "poora_bar"

        private val VENDOR_SECURITY_APPS = setOf(
            "com.miui.securitycenter",
            "com.coloros.safecenter",
            "com.oplus.safecenter",
            "com.samsung.android.lool",
            "com.huawei.systemmanager",
        )

        fun isGuardedSystemPackage(pkg: String) =
            pkg.contains("packageinstaller") || pkg.endsWith(".settings") || pkg == "com.android.settings" ||
                pkg in VENDOR_SECURITY_APPS

        fun start(c: Context) {
            val i = Intent(c, FocusService::class.java)
            if (Build.VERSION.SDK_INT >= 26) c.startForegroundService(i) else c.startService(i)
        }

        fun stop(c: Context) = c.stopService(Intent(c, FocusService::class.java))

        fun enabled(c: Context) = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean("enabled", true)

        fun save(c: Context, json: String, enabled: Boolean) {
            c.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString("data", json)
                .putBoolean("enabled", enabled)
                .apply()
        }

        private fun data(c: Context): JSONObject =
            try {
                JSONObject(c.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString("data", "{}") ?: "{}")
            } catch (_: Exception) {
                JSONObject()
            }

        private fun createChannel(c: Context) {
            if (Build.VERSION.SDK_INT < 26) return
            val ch = NotificationChannel(CHANNEL, "Focus bar", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Today's focus and your week, always in the notification bar"
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
            }
            (c.getSystemService(NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(ch)
        }

        private fun fmtLong(min: Long): String = when {
            min < 60 -> "$min min"
            min % 60 == 0L -> "${min / 60} h"
            else -> "${min / 60} h ${min % 60} min"
        }

        /** Minutes of focus per ISO day, with the live session added to today. */
        private fun minutes(d: JSONObject, now: Long): Map<String, Long> {
            val days = d.optJSONObject("days") ?: JSONObject()
            val out = mutableMapOf<String, Long>()
            days.keys().forEach { out[it] = days.optDouble(it, 0.0).toLong() }
            val live = d.optJSONObject("live")
            if (live != null) {
                val base = live.optLong("focusMs", 0L)
                val since = live.optLong("since", 0L)
                val cap = live.optLong("capMs", Long.MAX_VALUE)
                val ms = minOf(base + if (since > 0) now - since else 0L, cap)
                val today = LocalDate.now().toString()
                out[today] = (out[today] ?: 0L) + ms / 60_000
            }
            return out
        }

        private fun barText(c: Context, now: Long): String {
            val d = data(c)
            val m = minutes(d, now)
            return "${m[LocalDate.now().toString()] ?: 0}|${d.optJSONObject("live")?.optLong("endsAt") ?: 0}|$m"
        }

        fun buildBar(c: Context, now: Long): Notification {
            val d = data(c)
            val m = minutes(d, now)
            val today = LocalDate.now()
            val todayMin = m[today.toString()] ?: 0L
            val mondayFirst = d.optBoolean("mondayFirst", true)
            val start = today.with(TemporalAdjusters.previousOrSame(if (mondayFirst) DayOfWeek.MONDAY else DayOfWeek.SUNDAY))
            val weekMin = (0L until 7L).sumOf { m[start.plusDays(it).toString()] ?: 0L }
            val live = d.optJSONObject("live")
            val endsAt = live?.optLong("endsAt", 0L) ?: 0L
            val running = endsAt > now
            // Just two numbers — today and this week — or the session while focusing.
            val title = if (running) {
                val strict = live?.optBoolean("strict") == true
                "${if (strict) "Strict focus" else "Focusing"} · ends ${DateFormat.getTimeInstance(DateFormat.SHORT).format(Date(endsAt))}"
            } else {
                "Today ${fmtLong(todayMin)} focused"
            }
            val text = if (running) "Today ${fmtLong(todayMin)} · This week ${fmtLong(weekMin)}" else "This week ${fmtLong(weekMin)}"
            val open = PendingIntent.getActivity(
                c,
                0,
                Intent(c, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            val b = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(c, CHANNEL) else @Suppress("DEPRECATION") Notification.Builder(c)
            b.setSmallIcon(R.drawable.ic_notification)
                .setColor(0xFF86AD9E.toInt())
                .setContentTitle(title)
                .setContentText(text)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setShowWhen(running)
                .setContentIntent(open)
                .setCategory(if (running) Notification.CATEGORY_PROGRESS else Notification.CATEGORY_STATUS)
            if (running) {
                b.setWhen(endsAt).setUsesChronometer(true)
                if (Build.VERSION.SDK_INT >= 24) b.setChronometerCountDown(true)
            }
            return b.build()
        }
    }
}

/** Starts the focus service after a reboot, so the bar and the guard come back on their own. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED && intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) return
        val guard = GuardState.read(context)
        if (FocusService.enabled(context) || guard.active) FocusService.start(context)
    }
}

/** "poora/focusbar": the app pushes today's numbers and the live session. */
class FocusBarChannel(private val context: Context, messenger: BinaryMessenger) {
    init {
        MethodChannel(messenger, "poora/focusbar").setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    FocusService.save(context, call.argument<String>("data") ?: "{}", enabled)
                    val needed = enabled || GuardState.read(context).active
                    try {
                        if (needed) FocusService.start(context) else FocusService.stop(context)
                        result.success(true)
                    } catch (e: Exception) {
                        // Starting a foreground service from the background can be refused; the next update retries.
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}

/** Uninstall protection: while Poora is a device admin, Android won't uninstall it until it's deactivated. */
class PooraAdminReceiver : android.app.admin.DeviceAdminReceiver() {
    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        val g = GuardState.read(context)
        return if (g.active && g.strict) {
            "Strict focus is running. Poora's uninstall protection stays on until it ends. You versus you."
        } else {
            "Turning this off lets Poora be uninstalled during strict focus."
        }
    }
}

/** "poora/perms": status and system screens for every special permission Poora uses. */
class PermissionsChannel(private val context: Context, messenger: BinaryMessenger, private val activity: () -> android.app.Activity?) {
    init {
        MethodChannel(messenger, "poora/perms").setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> result.success(
                    mapOf(
                        "usage" to hasUsageAccess(),
                        "overlay" to (Build.VERSION.SDK_INT < 23 || Settings.canDrawOverlays(context)),
                        "accessibility" to FocusGuardService.isEnabled(context),
                        "admin" to adminActive(),
                        "battery" to batteryUnrestricted(),
                    ),
                )
                "open" -> {
                    open(call.argument<String>("which") ?: "")
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasUsageAccess(): Boolean {
        val ops = context.getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
        @Suppress("DEPRECATION")
        val mode = ops.checkOpNoThrow(android.app.AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), context.packageName)
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }

    private fun admin() = android.content.ComponentName(context, PooraAdminReceiver::class.java)

    private fun adminActive(): Boolean {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as android.app.admin.DevicePolicyManager
        return dpm.isAdminActive(admin())
    }

    private fun batteryUnrestricted(): Boolean {
        if (Build.VERSION.SDK_INT < 23) return true
        val pm = context.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        return pm.isIgnoringBatteryOptimizations(context.packageName)
    }

    private fun open(which: String) {
        val pkg = android.net.Uri.parse("package:${context.packageName}")
        val intent = when (which) {
            "usage" -> Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            "overlay" -> Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, pkg)
            "accessibility" -> Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            // Android 13+ greys out Accessibility for apps installed from a file until
            // "Allow restricted settings" is chosen in App info's ⋮ menu.
            "appInfo" -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pkg)
            "admin" -> Intent(android.app.admin.DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                .putExtra(android.app.admin.DevicePolicyManager.EXTRA_DEVICE_ADMIN, admin())
                .putExtra(
                    android.app.admin.DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                    "Uninstall protection for strict focus: Poora can't be removed while a strict session runs. " +
                        "Poora uses no other admin power.",
                )
            "battery" -> @Suppress("BatteryLife") Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, pkg)
            else -> return
        }
        val a = activity()
        try {
            if (a != null) a.startActivity(intent) else context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (_: Exception) {
            context.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pkg).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
    }
}
