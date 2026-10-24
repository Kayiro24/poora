package com.poora.app

import android.accessibilityservice.AccessibilityService
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * What the focus guard enforces, written by the app and read by the service.
 * Stored in SharedPreferences so it survives the app being killed and the
 * phone restarting; [activeUntil] makes it expire on its own at the end of
 * the focus phase even if Poora never runs again.
 */
object GuardState {
    private const val PREFS = "poora_guard"

    data class State(val activeUntil: Long, val strict: Boolean, val blocked: Set<String>) {
        val active get() = System.currentTimeMillis() < activeUntil
    }

    fun read(c: Context): State {
        val p = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return State(
            p.getLong("activeUntil", 0L),
            p.getBoolean("strict", false),
            p.getStringSet("blocked", emptySet()) ?: emptySet(),
        )
    }

    fun write(c: Context, activeUntil: Long, strict: Boolean, blocked: Collection<String>) {
        c.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putLong("activeUntil", activeUntil)
            .putBoolean("strict", strict)
            .putStringSet("blocked", blocked.toSet())
            .apply()
    }

    fun clear(c: Context) = write(c, 0L, false, emptySet())
}

/**
 * During focus: sends the user home from apps they chose to block, and in
 * strict mode keeps them out of Poora's uninstall dialog and its pages in
 * system Settings (App info, Accessibility), so focus can't be cut short by
 * removing the app. Does nothing outside a focus phase.
 */
class FocusGuardService : AccessibilityService() {
    private var lastCheck = 0L

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val pkg = event?.packageName?.toString() ?: return
        if (pkg == packageName) return
        val state = GuardState.read(this)
        if (!state.active) return

        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED && pkg in state.blocked) {
            performGlobalAction(GLOBAL_ACTION_HOME)
            startActivity(
                Intent(this, BlockedActivity::class.java)
                    .putExtra(BlockedActivity.EXTRA_PACKAGE, pkg)
                    .putExtra(BlockedActivity.EXTRA_UNTIL, state.activeUntil)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            )
            return
        }

        if (state.strict && isGuardedSystemScreen(pkg)) {
            // Content changes fire often; look at the window at most twice a second.
            val now = System.currentTimeMillis()
            if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED && now - lastCheck < 500) return
            lastCheck = now
            if (mentionsPoora()) {
                performGlobalAction(GLOBAL_ACTION_BACK)
                performGlobalAction(GLOBAL_ACTION_HOME)
                startActivity(
                    Intent(this, BlockedActivity::class.java)
                        .putExtra(BlockedActivity.EXTRA_STRICT, true)
                        .putExtra(BlockedActivity.EXTRA_UNTIL, state.activeUntil)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
                )
            }
        }
    }

    /** Package installers (uninstall dialogs) and Settings apps across vendors. */
    private fun isGuardedSystemScreen(pkg: String) =
        pkg.contains("packageinstaller") || pkg.contains("settings") || pkg in VENDOR_SECURITY_APPS

    private fun mentionsPoora(): Boolean {
        val root = rootInActiveWindow ?: return false
        val label = applicationInfo.loadLabel(packageManager).toString()
        return try {
            root.findAccessibilityNodeInfosByText(label).isNotEmpty()
        } finally {
            @Suppress("DEPRECATION")
            root.recycle()
        }
    }

    override fun onInterrupt() {}

    companion object {
        private val VENDOR_SECURITY_APPS = setOf(
            "com.miui.securitycenter",
            "com.coloros.safecenter",
            "com.oplus.safecenter",
            "com.samsung.android.lool",
            "com.huawei.systemmanager",
        )

        fun isEnabled(c: Context): Boolean {
            val enabled = Settings.Secure.getString(c.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES) ?: return false
            val me = ComponentName(c, FocusGuardService::class.java)
            return enabled.split(':').any { ComponentName.unflattenFromString(it) == me }
        }
    }
}

/** "poora/guard": the app arms the guard for each focus phase and clears it after. */
class GuardChannel(private val context: Context, messenger: BinaryMessenger) {
    init {
        MethodChannel(messenger, "poora/guard").setMethodCallHandler { call, result ->
            when (call.method) {
                "isEnabled" -> result.success(FocusGuardService.isEnabled(context))
                "openSettings" -> {
                    context.startActivity(
                        Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    )
                    result.success(null)
                }
                "arm" -> {
                    GuardState.write(
                        context,
                        call.argument<Number>("until")?.toLong() ?: 0L,
                        call.argument<Boolean>("strict") ?: false,
                        call.argument<List<String>>("blocked") ?: emptyList(),
                    )
                    // The service enforces the guard even without Accessibility (Usage access + overlay).
                    try {
                        FocusService.start(context)
                    } catch (_: Exception) {
                        // Refused from the background; Accessibility (if on) still enforces.
                    }
                    result.success(null)
                }
                "clear" -> {
                    GuardState.clear(context)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
