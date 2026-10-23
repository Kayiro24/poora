package com.poora.app

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import java.text.DateFormat
import java.util.Date

/**
 * Shown when a blocked app is opened during focus (or, in strict mode, when
 * Poora's uninstall/App info screens are opened). Plain views, Poora colours.
 */
class BlockedActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val strict = intent.getBooleanExtra(EXTRA_STRICT, false)
        val pkg = intent.getStringExtra(EXTRA_PACKAGE)
        val until = intent.getLongExtra(EXTRA_UNTIL, 0L)
        val label = pkg?.let {
            try {
                packageManager.getApplicationLabel(packageManager.getApplicationInfo(it, 0)).toString()
            } catch (_: Exception) {
                it
            }
        }
        val time = DateFormat.getTimeInstance(DateFormat.SHORT).format(Date(until))

        fun dp(v: Int) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics).toInt()
        fun text(s: String, size: Float, color: Int, bold: Boolean = false) = TextView(this).apply {
            text = s
            textSize = size
            setTextColor(color)
            gravity = Gravity.CENTER
            if (bold) typeface = Typeface.DEFAULT_BOLD
            setPadding(0, dp(8), 0, dp(8))
        }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(BG)
            setPadding(dp(32), dp(32), dp(32), dp(32))
        }
        root.addView(text(if (strict) "STRICT FOCUS" else "BLOCKED DURING FOCUS", 24f, SAGE, bold = true))
        root.addView(
            text(
                if (strict) "Poora can't be removed or changed until your focus ends at $time."
                else "${label ?: "This app"} is blocked until your focus ends at $time.",
                17f,
                TEXT,
            ),
        )
        root.addView(text("You versus you.", 15f, TEXT_2))
        root.addView(
            Button(this).apply {
                text = "Back to focus"
                setTextColor(INK)
                isAllCaps = false
                textSize = 17f
                background = GradientDrawable().apply {
                    cornerRadius = dp(28).toFloat()
                    setColor(SAGE)
                }
                setPadding(dp(28), dp(14), dp(28), dp(14))
                setOnClickListener {
                    startActivity(
                        Intent(this@BlockedActivity, MainActivity::class.java)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT),
                    )
                    finish()
                }
            },
            LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                topMargin = dp(24)
            },
        )
        setContentView(root)
    }

    companion object {
        const val EXTRA_PACKAGE = "package"
        const val EXTRA_UNTIL = "until"
        const val EXTRA_STRICT = "strict"
        private val BG = Color.parseColor("#151517")
        private val SAGE = Color.parseColor("#C6DAD2")
        private val TEXT = Color.parseColor("#F3F0EA")
        private val TEXT_2 = Color.parseColor("#A4A19C")
        private val INK = Color.parseColor("#151517")
    }
}
