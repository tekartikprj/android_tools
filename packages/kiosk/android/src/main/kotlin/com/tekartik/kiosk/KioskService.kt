package com.tekartik.kiosk

import android.app.Service
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.Process
import android.provider.Settings
import android.util.Log
import kotlin.system.exitProcess

/**
 * Created by Tekartik on 29/08/2016.
 */

/* Add to manifest
        <service android:name="com.tekartik.lib.kiosk.KioskService" android:exported="false"/>

        <uses-permission android:name="android.permission.GET_TASKS"/>
        <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
        tools:ignore="ProtectedPermissions"/>

        ajouter dans activity
         @Override
        public void onBackPressed() {

        }

        <receiver android:name="a2k.liba2k_kioskmode.BootReceiver">
            <intent-filter >
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
            </intent-filter>
        </receiver>

 */

class KioskService : Service() {

    private var thread: Thread? = null
    private var running = false
    private var debugLastPackage: String? = null

    override fun onDestroy() {
        Log.d(TAG, "Stopping service 'KioskService'")
        if (running) {
            restoreApp()
        }
        running = false
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (thread != null) {
            Log.i(TAG, "onStartCommand: service 'KioskService' already running")
            return START_STICKY
        }
        Log.i(TAG, "onStartCommand: Starting service 'KioskService'")
        running = true

        // start a thread that periodically checks if app is in the foreground
        thread = Thread {
            try {
                Log.d(TAG, "in thread")

                Thread.setDefaultUncaughtExceptionHandler { _, e ->
                    e.printStackTrace()
                    Log.e(TAG, "crash", e)

                    // restart main activity
                    restoreApp()

                    Process.killProcess(Process.myPid())
                    exitProcess(0)
                }
                do {
                    val options = KioskOptions.load(this)
                    handleKioskMode(options)
                    try {
                        Thread.sleep(options.checkDelayMs)
                    } catch (e: InterruptedException) {
                        e.printStackTrace()
                    }
                } while (running)
                Thread.setDefaultUncaughtExceptionHandler(null)
                Log.d(TAG, "thread done")
                stopSelf()
            } catch (e: Exception) {
                Log.d(TAG, "thread exception $e")
                stopSelf()
            }
        }

        Log.e(TAG, "Starting thread")

        thread!!.start()
        return START_STICKY
    }

    private fun handleKioskMode(options: KioskOptions) {
        val mainPackage = options.mainPackage
        if (mainPackage == null) {
            // Legacy mode: bring this app back when it goes to the background
            if (KioskUtils.isInBackground(this)) {
                Log.i(TAG, "in background")
                restoreApp() // restore!
            }
            return
        }
        // Watchdog mode: keep the main package (or an allowed package) in the foreground
        val currentPackage = KioskUtils.getCurrentPackageName(this) ?: return
        if (Mode.DEBUG) {
            if (currentPackage != debugLastPackage) {
                debugLastPackage = currentPackage
                Log.d(TAG, "foreground package: $currentPackage")
            }
        }
        if (currentPackage == mainPackage ||
            currentPackage == packageName ||
            // Allow some system dialogs
            currentPackage == "android" ||
            options.allowedPackages.contains(currentPackage)
        ) {
            return
        }
        Log.i(TAG, "unauthorized package $currentPackage, relaunching $mainPackage")
        launchMainPackage(mainPackage)
    }

    private fun launchMainPackage(mainPackage: String) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                // Cannot start an activity from the background without the overlay permission
                Log.d(TAG, "ACTION_MANAGE_OVERLAY_PERMISSION")
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
                return
            }
            KioskUtils.launchPackage(this, mainPackage)
        } catch (e: Exception) {
            Log.e(TAG, "launchMainPackage error $e")
        }
    }

    private fun restoreApp() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                Log.d(TAG, "ACTION_MANAGE_OVERLAY_PERMISSION")
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
            } else {
                startApp()
            }
        } else {
            startApp()
        }
    }

    private fun startApp() {
        Log.d(TAG, "Restarting app")
        val pm = packageManager
        val launchIntent = pm.getLaunchIntentForPackage(packageName)!!
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            launchIntent.addFlags(
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
            )
        } else {
            launchIntent.addFlags(
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
            )
        }
        startActivity(launchIntent)
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    companion object {
        @JvmField
        var TAG = "/TKioskService"

        @JvmField
        var EXTRA_ACTIVITY_START_CLASS_NAME = "activity_start_class_name"

        private var startActivityClass: Class<*>? = null

        @JvmStatic
        fun setStartClass(cls: Class<*>?) {
            startActivityClass = cls
        }
    }
}
