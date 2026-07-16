package com.tekartik.kiosk

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        try {
            try {
                if (Intent.ACTION_BOOT_COMPLETED == intent.action) {
                    val launchPackageName = getLaunchPackageName(context)
                    if (launchPackageName != null) {
                        Log.i(TAG, "BOOT detected launching $launchPackageName")
                        KioskUtils.launchPackage(context, launchPackageName)
                    } else {
                        if (Mode.DEBUG) {
                            Log.i(TAG, "BOOT detected no app to launch")
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "BootReceiver error $e", e)
            }
        } catch (ignore: Exception) {
        }
    }

    companion object {
        private const val TAG = "/TKiosk"

        const val LAUNCH_PACKAGE_NAME_PREF_KEY = "packageName"
        const val PREFS_NAME = "tekartik_kiosk_boot_receiver"

        private fun getBootSharedPreferences(context: Context): SharedPreferences {
            return context.applicationContext.getSharedPreferences(PREFS_NAME, 0)
        }

        fun setLaunchPackageName(context: Context, packageName: String?) {
            val editor = getBootSharedPreferences(context).edit()
            if (packageName == null) {
                editor.remove(LAUNCH_PACKAGE_NAME_PREF_KEY)
            } else {
                editor.putString(LAUNCH_PACKAGE_NAME_PREF_KEY, packageName)
            }
            editor.apply()
        }

        fun getLaunchPackageName(context: Context): String? {
            return getBootSharedPreferences(context).getString(LAUNCH_PACKAGE_NAME_PREF_KEY, null)
        }
    }
}
