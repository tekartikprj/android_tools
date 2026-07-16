package com.tekartik.kiosk

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray

/**
 * Native watchdog options, persisted in shared preferences so that the
 * kiosk service can read them whenever it runs.
 */
class KioskOptions(
    /** Main package the watchdog keeps in the foreground, null for legacy mode (restore this app). */
    var mainPackage: String? = null,
    /** Extra packages allowed in the foreground (this app is always allowed). */
    var allowedPackages: List<String> = emptyList(),
    /** Watchdog check frequency in milliseconds. */
    var checkDelayMs: Long = DEFAULT_CHECK_DELAY_MS,
) {

    fun toMap(): Map<String, Any?> {
        val map = HashMap<String, Any?>()
        map["package"] = mainPackage
        map["allowedPackages"] = allowedPackages
        map["checkDelayMs"] = checkDelayMs
        return map
    }

    override fun toString() = toMap().toString()

    companion object {
        const val DEFAULT_CHECK_DELAY_MS = 400L
        const val MIN_CHECK_DELAY_MS = 50L

        const val PACKAGE_KEY = "package"
        const val ALLOWED_PACKAGES_KEY = "allowedPackages"
        const val CHECK_DELAY_MS_KEY = "checkDelayMs"

        private const val PREFS_NAME = "tekartik_kiosk_options"

        private fun getSharedPreferences(context: Context): SharedPreferences {
            return context.applicationContext.getSharedPreferences(PREFS_NAME, 0)
        }

        fun fromMap(map: Map<*, *>): KioskOptions {
            val mainPackage = map[PACKAGE_KEY] as? String
            val allowedPackages =
                (map[ALLOWED_PACKAGES_KEY] as? List<*>)?.filterIsInstance<String>() ?: emptyList()
            val checkDelayMs = (map[CHECK_DELAY_MS_KEY] as? Number)?.toLong()
                ?: DEFAULT_CHECK_DELAY_MS
            return KioskOptions(
                mainPackage = mainPackage,
                allowedPackages = allowedPackages,
                checkDelayMs = checkDelayMs.coerceAtLeast(MIN_CHECK_DELAY_MS)
            )
        }

        fun load(context: Context): KioskOptions {
            val prefs = getSharedPreferences(context)
            val allowedPackages = try {
                prefs.getString(ALLOWED_PACKAGES_KEY, null)?.let { text ->
                    val jsonArray = JSONArray(text)
                    (0 until jsonArray.length()).map { jsonArray.getString(it) }
                } ?: emptyList()
            } catch (ignore: Exception) {
                emptyList()
            }
            return KioskOptions(
                mainPackage = prefs.getString(PACKAGE_KEY, null),
                allowedPackages = allowedPackages,
                checkDelayMs = prefs.getLong(CHECK_DELAY_MS_KEY, DEFAULT_CHECK_DELAY_MS)
                    .coerceAtLeast(MIN_CHECK_DELAY_MS)
            )
        }

        fun save(context: Context, options: KioskOptions) {
            val editor = getSharedPreferences(context).edit()
            val mainPackage = options.mainPackage
            if (mainPackage == null) {
                editor.remove(PACKAGE_KEY)
            } else {
                editor.putString(PACKAGE_KEY, mainPackage)
            }
            editor.putString(ALLOWED_PACKAGES_KEY, JSONArray(options.allowedPackages).toString())
            editor.putLong(CHECK_DELAY_MS_KEY, options.checkDelayMs)
            editor.apply()
        }
    }
}
