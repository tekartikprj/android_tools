package com.tekartik.kiosk

import android.annotation.TargetApi
import android.app.Activity
import android.app.ActivityManager
import android.app.ActivityOptions
import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.SystemClock
import android.text.format.DateUtils
import android.util.Log
import androidx.annotation.RequiresApi

object KioskUtils {

    private const val TAG = "/TKioskUtils"

    const val RESTART_AFTER_CRASH = "tk_kiosk_mode_restart_after_crash" // boolean

    private var pausedAllowFirstPackage = false
    private var firstAllowedPackageName: String? = null
    private var pausedStartUptime: Long = 0

    private var debugLastCurrentPackage: String? = null

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    private fun inLockTaskMode(context: Context): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            activityManager.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
        } else {
            inLockTaskModePre23(activityManager)
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    @Suppress("DEPRECATION")
    private fun inLockTaskModePre23(activityManager: ActivityManager): Boolean {
        return activityManager.isInLockTaskMode
    }

    fun startPinnedMode(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            if (!inLockTaskMode(activity)) {
                try {
                    activity.startLockTask()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }

    fun getPinnedMode(activity: Activity): Boolean {
        return inLockTaskMode(activity)
    }

    fun stopPinnedMode(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            if (inLockTaskMode(activity)) {
                try {
                    activity.stopLockTask()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }

    fun isInBackground(context: Context): Boolean {
        try {
            val currentPackageName = getCurrentPackageName(context) ?: return false

            if (Mode.DEBUG) {
                if (currentPackageName != debugLastCurrentPackage) {
                    debugLastCurrentPackage = currentPackageName
                    Log.d(TAG, "current package name: $currentPackageName")
                }
            }

            val packageName = context.applicationContext.packageName
            if (packageName == currentPackageName) {
                if (Mode.DEBUG) {
                    Log.d(TAG, "current package name: $currentPackageName vs $packageName")
                }
                return false
            }
            // Allow some system dialog

            if ("android" == currentPackageName) {
                if (Mode.DEBUG) {
                    Log.d(TAG, "android system")
                }
                return false
            }
            /*
            Don't handle that, it prevent from brining the last used apps and killing the application
            if ("com.android.systemui" == currentPackageName) {
                if (Mode.DEBUG) {
                    Log.d(TAG, "android system ui")
                }
                return false
            }*/

            if (pausedAllowFirstPackage) {
                if (firstAllowedPackageName == null) {
                    firstAllowedPackageName = currentPackageName
                }

                // Allow for 15mn max
                if (SystemClock.uptimeMillis() - pausedStartUptime > DateUtils.MINUTE_IN_MILLIS * 15) {
                    return false
                }
                if (firstAllowedPackageName == currentPackageName) {
                    return false
                }
            }
            if (Mode.DEBUG) {
                Log.d(TAG, "In background")
            }
            return true
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }

    /** true if the activity was started and we wait for the result */
    fun requestPermissionForUsageStat(activity: Activity, requestCode: Int): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            return requestPermissionForUsageStat21(activity, requestCode)
        }
        return false
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    private fun requestPermissionForUsageStat21(activity: Activity, requestCode: Int): Boolean {
        return if (needPermissionForUsageStat(activity.applicationContext)) {
            val intent = Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            activity.startActivityForResult(intent, requestCode)
            true
        } else {
            false
        }
    }

    @Suppress("DEPRECATION")
    fun getCurrentPackageName14(context: Context): String? {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val taskInfo = am.getRunningTasks(1)
        val componentInfo = taskInfo[0].topActivity
        return componentInfo?.packageName
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    fun getCurrentPackageName21(context: Context): String? {
        return try {
            val ts = System.currentTimeMillis()
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val usageStats: List<UsageStats>? = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_BEST, ts - 60000, ts)
            //Log.i(TAG, "usageStats " + usageStats)
            if (usageStats.isNullOrEmpty()) {
                null
            } else {
                usageStats.maxByOrNull { it.lastTimeUsed }?.packageName
            }
        } catch (ex: Exception) {
            Log.e(TAG, "isInBackground", ex)
            null
        }
    }

    fun getCurrentPackageName(context: Context): String? {
        return if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            getCurrentPackageName14(context)
        } else {
            getCurrentPackageName21(context)
        }
    }

    fun needPermissionForUsageStat(context: Context): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && needPermissionForUsageStats21(context)
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    fun needPermissionForUsageStats21(context: Context): Boolean {
        return try {
            val packageManager = context.packageManager
            val applicationInfo = packageManager.getApplicationInfo(context.packageName, 0)
            val appOpsManager = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            @Suppress("DEPRECATION")
            val mode = appOpsManager.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, applicationInfo.uid, applicationInfo.packageName)
            mode != AppOpsManager.MODE_ALLOWED
        } catch (e: PackageManager.NameNotFoundException) {
            true
        }
    }

    class KioskPackageInfo {
        var user = false
        var launchable = false
        var packageName: CharSequence? = null
        var appName: CharSequence? = null
        var versionName: String? = null
    }

    // Null means not found
    fun getPackageInfo(context: Context, packageName: String): KioskPackageInfo? {
        return try {
            val packageManager = context.packageManager
            val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_META_DATA)
            packageInfoToKioskPackageInfo(packageManager, packageInfo)
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }
    }

    fun launchPackage(context: Context, packageName: String) {
        val packageManager = context.packageManager
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        if (launchIntent != null) {
            if (Mode.DEBUG) {
                Log.d(TAG, "Launching $packageName intent ${Integer.toHexString(launchIntent.flags)}")
            }
            // ! https://stackoverflow.com/questions/12074980/bring-application-to-front-after-user-clicks-on-home-button
            launchIntent.setPackage(null)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_PREVIOUS_IS_TOP)

            if (Mode.DEBUG) {
                Log.d(TAG, "Launching $packageName intent ${Integer.toHexString(launchIntent.flags)}")
            }
            var options: ActivityOptions? = null
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                options = ActivityOptions.makeBasic()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    // No - security issue
                    // BootReceiver error java.lang.SecurityException: Permission Denial: starting Intent { act=android.intent.action.MAIN cat=[android.intent.category.LAUNCHER] flg=0x15228000 cmp=com.tekartik.simple_kiosk_app/com.tekartik.example.MainActivity } from ProcessRecord{817a7c6 5973:com.tekartik.simple_kiosk_app/u0a301} (pid=5973, uid=10301) with lockTaskMode=true
                    //options.setLockTaskEnabled(true)
                }
            }
            context.startActivity(launchIntent, options?.toBundle())
        } else {
            if (Mode.DEBUG) {
                Log.d(TAG, "No launch intent for $packageName")
            }
        }
    }

    private fun packageInfoToKioskPackageInfo(packageManager: PackageManager, packageInfo: PackageInfo): KioskPackageInfo {
        val applicationInfo: ApplicationInfo? = packageInfo.applicationInfo
        val kioskPackageInfo = KioskPackageInfo()
        if (applicationInfo != null) {
            val launchIntent = packageManager.getLaunchIntentForPackage(packageInfo.packageName)
            if (launchIntent != null) {
                kioskPackageInfo.launchable = true
            }
            kioskPackageInfo.appName = packageManager.getApplicationLabel(applicationInfo)
            if ((applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0) {
                kioskPackageInfo.user = true
            }
        }
        kioskPackageInfo.packageName = packageInfo.packageName
        kioskPackageInfo.versionName = packageInfo.versionName
        // Launchable

        return kioskPackageInfo
    }

    // Null means not found
    fun getInstalledPackageInfos(context: Context): List<KioskPackageInfo> {
        val packageManager = context.packageManager
        val packageInfos = packageManager.getInstalledPackages(PackageManager.GET_META_DATA)
        val kioskPackageInfos = ArrayList<KioskPackageInfo>()
        for (packageInfo in packageInfos) {
            kioskPackageInfos.add(packageInfoToKioskPackageInfo(packageManager, packageInfo))
        }
        return kioskPackageInfos
    }

    class KioskRunningProcessInfo {
        var processName: String? = null
        var importance: Int = 0
        var pkgList: List<String>? = null
    }

    fun getRunningProcesses(context: Context): List<KioskRunningProcessInfo> {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val runningProcesses = activityManager.runningAppProcesses ?: return emptyList()
        val list = ArrayList<KioskRunningProcessInfo>()
        for (processInfo in runningProcesses) {
            val info = KioskRunningProcessInfo()
            info.processName = processInfo.processName
            info.importance = processInfo.importance
            info.pkgList = processInfo.pkgList?.toList()
            list.add(info)
        }
        return list
    }

    private var kioskModeOn = false

    fun startKioskMode(context: Context) {
        if (Mode.DEBUG) {
            Log.d(TAG, "Starting kiosk mode")
            debugLastCurrentPackage = null
        }

        val intent = Intent(context.applicationContext, KioskService::class.java)

        // Set handler
        val componentName: ComponentName? = context.startService(intent)
        if (componentName == null) {
            throw IllegalStateException("Kiosk service not found")
        }
        kioskModeOn = true
        //startPinnedMode(activity)
    }

    fun stopKioskMode(context: Context) {
        if (Mode.DEBUG) {
            Log.d(TAG, "Stopping kiosk mode")
        }
        val intent = Intent(context, KioskService::class.java)
        context.stopService(intent)
        kioskModeOn = false

        //stopPinnedMode(activity)
    }

    @Suppress("UNUSED_PARAMETER")
    fun isKioskModeOn(context: Context): Boolean {
        return kioskModeOn
    }
}
