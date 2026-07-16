package com.example.tekartik_kiosk_app

import android.app.ActivityManager
import android.content.Context
import androidx.test.core.app.ActivityScenario
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tekartik.kiosk.KioskUtils
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class KioskInstrumentedTest {

    private fun grantUsageStatsPermission() {
        try {
            val packageName = InstrumentationRegistry.getInstrumentation().targetContext.packageName
            val testPackageName = InstrumentationRegistry.getInstrumentation().context.packageName
            val uiAutomation = InstrumentationRegistry.getInstrumentation().uiAutomation
            uiAutomation.executeShellCommand("appops set $packageName GET_USAGE_STATS allow")
            uiAutomation.executeShellCommand("appops set $testPackageName GET_USAGE_STATS allow")
            // Sleep a bit to let the setting apply
            Thread.sleep(1000)
        } catch (e: Exception) {
            println("Failed to grant usage stats permission programmatically: ${e.message}")
        }
    }

    @Test
    fun listPackagesTest() {
        val appContext = InstrumentationRegistry.getInstrumentation().targetContext
        
        // 1. List installed packages using KioskUtils class from kiosk package
        println("=== INSTALLED PACKAGES ===")
        val installedPackageInfos = KioskUtils.getInstalledPackageInfos(appContext)
        assertNotNull("Installed package list should not be null", installedPackageInfos)
        assertTrue("Installed package list should not be empty", installedPackageInfos.isNotEmpty())
        for (info in installedPackageInfos) {
            println("Installed package: ${info.packageName} (Name: ${info.appName}, User: ${info.user}, Launchable: ${info.launchable})")
        }

        // 2. List running packages from native API (ActivityManager)
        println("=== RUNNING PROCESSES AND PACKAGES ===")
        val activityManager = appContext.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val runningProcesses = activityManager.runningAppProcesses
        assertNotNull("Running processes list should not be null", runningProcesses)
        assertTrue("Running processes list should not be empty", runningProcesses.isNotEmpty())
        for (processInfo in runningProcesses) {
            println("Running process: ${processInfo.processName} (Importance: ${processInfo.importance})")
            processInfo.pkgList?.forEach { pkg ->
                println("  Running package: $pkg")
            }
        }
    }

    @Test
    fun testGetCurrentPackageName() {
        grantUsageStatsPermission()
        val appContext = InstrumentationRegistry.getInstrumentation().targetContext
        println("=== CURRENT PACKAGE NAME ===")
        val currentPackageName = KioskUtils.getCurrentPackageName(appContext)
        println("Current package name (via KioskUtils): $currentPackageName")
    }

    @Test
    fun testQueryUsageStats() {
        grantUsageStatsPermission()
        val appContext = InstrumentationRegistry.getInstrumentation().targetContext
        println("=== QUERY USAGE STATS ===")
        val ts = System.currentTimeMillis()
        val usageStatsManager = appContext.getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
        // Query last 5 minutes
        val usageStats = usageStatsManager.queryUsageStats(
            android.app.usage.UsageStatsManager.INTERVAL_BEST, 
            ts - 300000, 
            ts
        )
        if (usageStats.isNullOrEmpty()) {
            println("UsageStats list is null or empty. Checking if permission is granted...")
            val appOpsManager = appContext.getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
            val mode = appOpsManager.checkOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS, 
                android.os.Process.myUid(), 
                appContext.packageName
            )
            println("Usage stats permission mode: $mode (Allowed is ${android.app.AppOpsManager.MODE_ALLOWED})")
        } else {
            println("Found ${usageStats.size} usage stats entries:")
            for (stat in usageStats) {
                println("Package: ${stat.packageName}")
                println("  Last Time Used: ${stat.lastTimeUsed}")
                println("  Total Time In Foreground: ${stat.totalTimeInForeground} ms")
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                    println("  Last Time Visible: ${stat.lastTimeVisible}")
                }
            }
        }
    }

    @Suppress("DEPRECATION")
    @Test
    fun testGetRunningTasks() {
        val appContext = InstrumentationRegistry.getInstrumentation().targetContext
        println("=== GET RUNNING TASKS ===")
        
        // Launch the activity so we have a task running
        ActivityScenario.launch(MainActivity::class.java).use {
            val activityManager = appContext.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val runningTasks = activityManager.getRunningTasks(10)
            if (runningTasks.isNullOrEmpty()) {
                println("No running tasks found.")
            } else {
                println("Found ${runningTasks.size} running tasks:")
                for (task in runningTasks) {
                    println("Task ID: ${task.id}")
                    println("  Top Activity: ${task.topActivity}")
                    println("  Base Activity: ${task.baseActivity}")
                    println("  Number of Activities: ${task.numActivities}")
                    println("  Number of Running Activities: ${task.numRunning}")
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                        println("  Task Description: ${task.taskDescription}")
                    }
                }
            }
        }
    }
}
