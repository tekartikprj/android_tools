package com.tekartik.kiosk;

import android.annotation.TargetApi;
import android.app.Activity;
import android.app.ActivityManager;
import android.app.ActivityOptions;
import android.app.AppOpsManager;
import android.app.Application;
import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Process;
import android.os.SystemClock;
import android.text.format.DateUtils;
import android.util.Log;

import androidx.annotation.RequiresApi;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import static android.app.ActivityManager.LOCK_TASK_MODE_NONE;

public class KioskUtils {

    private static final String TAG = "/TKioskUtils";

    static final public String RESTART_AFTER_CRASH = "tk_kiosk_mode_restart_after_crash"; // boolean

    private static Activity currentActivity;
    private static int timeout;
    private static Thread CurrentThreadTimeout = null;

    static private boolean pausedAllowFirstPackage = false;
    static String firstAllowedPackageName;
    static long pausedStartUptime;

    /*
    public static void setKioskModeActive(final boolean active, final Activity activity, final int timeoutSeconds, TimeOutCallback callback) {
        currentActivity = activity;
        registeredCallback = callback;
        KioskUtils.timeout = timeoutSeconds * 1000;

        reloadTimeout();

        setKioskMode(active, activity);
    }

    static void setDefaultUncaughtExceptionHandler(Activity activity, Thread.UncaughtExceptionHandler handler) {
        final Application application = activity.getApplication();
        android.util.Log.d(TAG, "setCrashDefaultHandler");
        if (application instanceof AppListener) {
            ((AppListener) application).setDefaultUncaughtExceptionHandler(handler);
        } else {
            Thread.setDefaultUncaughtExceptionHandler(handler);
        }
    }

    public static void startKioskMode(final Activity activity, final Class<? extends Activity> activityClass) {
        if (DEBUG) {
            android.util.Log.d(TAG, "Starting kiosk mode");
            debugLastCurrentPackage = null;
        }

        Intent intent = new Intent(activity.getApplicationContext(), KioskService.class);
        intent.putExtra(KioskService.EXTRA_ACTIVITY_START_CLASS_NAME, activityClass.getName());

        final Application application = activity.getApplication();

        setDefaultUncaughtExceptionHandler(activity, new Thread.UncaughtExceptionHandler() {

            @Override
            public void uncaughtException(Thread thread, Throwable e) {

                e.printStackTrace();
                android.util.Log.e(TAG, "crash", e);

                // restart main activity
                Intent i = new Intent(application.getApplicationContext(), activityClass);
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                i.putExtra(RESTART_AFTER_CRASH, true);
                application.startActivity(i);

                Process.killProcess(Process.myPid());
                System.exit(0);
            }
        });

        // Set handler
        activity.startService(intent);

        //startPinnedMode(activity);

    }

    static public void pauseAllowFirstPackage() {
        pausedStartUptime = SystemClock.uptimeMillis();
        firstAllowedPackageName = null;
        pausedAllowFirstPackage = true;

        if (DEBUG) {
            android.util.Log.d(TAG, "pausing allowing package");
        }
    }

    static public void resume() {
        pausedAllowFirstPackage = false;
        if (DEBUG) {
            android.util.Log.d(TAG, "resuming");
        }
    }
    */
    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    static private boolean inLockTaskMode(Context context) {
        ActivityManager activityManager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return activityManager.getLockTaskModeState() != LOCK_TASK_MODE_NONE;
        } else {
            return inLockTaskModePre23(activityManager);
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    @SuppressWarnings("deprecation")
    static private boolean inLockTaskModePre23(ActivityManager activityManager) {
        return activityManager.isInLockTaskMode();
    }

    static public void startPinnedMode(Activity activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            if (!inLockTaskMode(activity)) {
                try {
                    activity.startLockTask();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }

    static public boolean getPinnedMode(Activity activity) {
        return inLockTaskMode(activity);
    }
    static public void stopPinnedMode(Activity activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            if (inLockTaskMode(activity)) {
                try {
                    activity.stopLockTask();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

        }
    }

    /*
    public static void stopKioskMode(Activity activity) {
        if (DEBUG) {
            android.util.Log.d(TAG, "Stopping kiosk mode");
        }
        Context context = activity.getApplicationContext();
        Intent intent = new Intent(context, KioskService.class);
        context.stopService(intent);

        //Thread.setDefaultUncaughtExceptionHandler(mPreviousCrashHandler);
        setDefaultUncaughtExceptionHandler(activity, null);
        //stopPinnedMode(activity);
    }

    private static void setKioskMode(final boolean active, final Activity activity) {
        if (active) {

            uiChangeListener(activity);


            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {

                try {
                    ComponentName deviceAdmin = new ComponentName(activity, BasicDeviceAdminReceiver.class);
                    DevicePolicyManager mDpm = (DevicePolicyManager) activity.getSystemService(Context.DEVICE_POLICY_SERVICE);
                    if (!mDpm.isAdminActive(deviceAdmin)) {
                        //Toast.makeText(Act,"not_device_admin" , Toast.LENGTH_SHORT).show();
                        android.util.Log.w(TAG, "DeviceOwner : " + "not_device_admin");
                    }

                    if (mDpm.isDeviceOwnerApp(activity.getPackageName())) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            android.util.Log.w(TAG, "DeviceOwner : " + "DEVICE OWNER!!!!");
                            //Toast.makeText(Act, "DEVICE OWNER!!!!", Toast.LENGTH_SHORT).show();
                            mDpm.setLockTaskPackages(deviceAdmin, new String[]{activity.getPackageName()});
                            //mDpm.clearDeviceOwnerApp(Act.getPackageName());
                        }
                    } else {
                        //Toast.makeText(Act, "not_device_owner", Toast.LENGTH_SHORT).show();
                        android.util.Log.w(TAG, "DeviceOwner : " + "not_isDeviceOwnerApp");
                    }
                } catch (Exception ex) {
                    android.util.Log.w(TAG, "DeviceOwner : " + ex.toString());
                }


                if (inLockTaskMode(activity)) {
                    ;// code your logic here
                } else {
                    activity.startLockTask();
                }

                // Needed to allow usage stats
                if (needPermissionForBlocking(activity.getApplicationContext())) {
                    Toast.makeText(activity, "Le mode kiosk nécessite la permission décrite dans cet écran", Toast.LENGTH_SHORT);
                    Intent intent = new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS);
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    activity.startActivity(intent);
                }

            }
        } else {
            //Toast.makeText(activity.getApplicationContext(), activity.getString(R.string.kioskbyebye), Toast.LENGTH_SHORT).show();
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                try {

                    activity.stopLockTask();

                } catch (Exception ex) {
                    ;
                }

            }
        }

    }
    */
    static private String debugLastCurrentPackage;

    static public boolean isInBackground(Context context) {
        try {
            String currentPackageName = getCurrentPackageName(context);
            if (currentPackageName == null) {
                return false;
            }

            if (Mode.DEBUG) {
                if (!currentPackageName.equals(debugLastCurrentPackage)) {
                    debugLastCurrentPackage = currentPackageName;
                    Log.d(TAG, "current package name: " + currentPackageName);
                }
            }

            String packageName = context.getApplicationContext().getPackageName();
            if (packageName.equals(currentPackageName)) {
                if (Mode.DEBUG) {
                    Log.d(TAG, "current package name: " + currentPackageName + " vs " + packageName);
                }
                return false;
            }
            // Allow some system dialog

            if ("android".equals(currentPackageName)) {
                if (Mode.DEBUG) {
                    Log.d(TAG, "android system");
                }
                return false;
            }
            /*
            Don't handle that, it prevent from brining the last used apps and killing the application
            if ("com.android.systemui".equals(currentPackageName)) {
                if (Mode.DEBUG) {
                    Log.d(TAG, "android system ui");
                }
                return false;
            }*/

            if (pausedAllowFirstPackage) {
                if (firstAllowedPackageName == null) {
                    firstAllowedPackageName = currentPackageName;
                }

                // Allow for 15mn max
                if (SystemClock.uptimeMillis() - pausedStartUptime > DateUtils.MINUTE_IN_MILLIS * 15) {
                    return false;
                }
                if (firstAllowedPackageName.equals(currentPackageName)) {
                    return false;
                }
            }
            if (Mode.DEBUG) {
                Log.d(TAG, "In background");
            }
            return true;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;

    }

    /// true if the activity was started and we wait for the result
    static public boolean requestPermissionForUsageStat(Activity activity, int requestCode) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            return requestPermissionForUsageStat21(activity, requestCode);
        }
        return false;

    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    static private boolean requestPermissionForUsageStat21(Activity activity, int requestCode) {
        if (needPermissionForUsageStat(activity.getApplicationContext())) {
            Intent intent = new Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            activity.startActivityForResult(intent, requestCode);
            return true;
        } else {
            return false;
        }
    }

    @SuppressWarnings("deprecation")
    static public String getCurrentPackageName14(Context context) {
        ActivityManager am = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
        java.util.List<ActivityManager.RunningTaskInfo> taskInfo = am.getRunningTasks(1);
        ComponentName componentInfo = taskInfo.get(0).topActivity;
        return componentInfo.getPackageName();
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    static public String getCurrentPackageName21(Context context) {
        try {
            long ts = System.currentTimeMillis();
            UsageStatsManager mUsageStatsManager = (UsageStatsManager) context.getSystemService(Context.USAGE_STATS_SERVICE);
            java.util.List<UsageStats> usageStats = mUsageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_BEST, ts - 60000, ts);
            //Log.i(TAG, "usageStats " + usageStats);
            if (usageStats == null || usageStats.size() == 0 || usageStats.isEmpty()) {
                return null;
            } else {
                RecentUseComparator21 mRecentComp = new RecentUseComparator21();

                Collections.sort(usageStats, mRecentComp);
                return usageStats.get(0).getPackageName();
            }
        } catch (Exception ex) {
            android.util.Log.e(TAG, "isInBackground", ex);
            return null;
        }
    }

    static public String getCurrentPackageName(Context context) {

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return getCurrentPackageName14(context);
        } else {
            return getCurrentPackageName21(context);
        }

    }


    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    static class RecentUseComparator21 implements Comparator<UsageStats> {

        @Override
        public int compare(UsageStats lhs, UsageStats rhs) {
            return (lhs.getLastTimeUsed() > rhs.getLastTimeUsed()) ? -1 : (lhs.getLastTimeUsed() == rhs.getLastTimeUsed()) ? 0 : 1;
        }
    }

    //PAUL le 03-05 suite à android 6.0!!!
    public static void uiChangeListener(final Activity Act) {
        /*
        final View decorView = Act.getWindow().getDecorView();
        decorView.setOnSystemUiVisibilityChangeListener(new View.OnSystemUiVisibilityChangeListener() {
            @Override
            public void onSystemUiVisibilityChange(int visibility) {
                if ((visibility & View.SYSTEM_UI_FLAG_FULLSCREEN) == 0) {
                    decorView.setSystemUiVisibility(
                            View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                                    | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                                    | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                                    | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                                    | View.SYSTEM_UI_FLAG_FULLSCREEN
                                    | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
                }
            }
        });
        */
    }


    public static boolean needPermissionForUsageStat(Context context) {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && needPermissionForUsageStats21(context);
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    public static boolean needPermissionForUsageStats21(Context context) {
        try {
            PackageManager packageManager = context.getPackageManager();
            ApplicationInfo applicationInfo = packageManager.getApplicationInfo(context.getPackageName(), 0);
            AppOpsManager appOpsManager = (AppOpsManager) context.getSystemService(Context.APP_OPS_SERVICE);
            int mode = appOpsManager.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, applicationInfo.uid, applicationInfo.packageName);
            return (mode != AppOpsManager.MODE_ALLOWED);
        } catch (PackageManager.NameNotFoundException e) {
            return true;
        }
    }

    static class KioskPackageInfo {
        boolean user;
        boolean launchable;
        CharSequence packageName;
        CharSequence appName;
        String versionName;

    }

    // Null means not found
    public static KioskPackageInfo getPackageInfo(Context context, String packageName) {
        try {
            PackageManager packageManager = context.getPackageManager();
            PackageInfo packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_META_DATA);
            KioskPackageInfo kioskPackageInfo = packageInfoToKioskPackageInfo(packageManager, packageInfo);

            return kioskPackageInfo;
        } catch (PackageManager.NameNotFoundException e) {
            return null;
        }
    }

    static void launchPackage(Context context, String packageName) {

        PackageManager packageManager = context.getPackageManager();
        Intent launchIntent = packageManager.getLaunchIntentForPackage(packageName);
        if (launchIntent != null) {
            if (Mode.DEBUG) {
                Log.d(TAG, "Launching " + packageName + " intent " + Integer.toHexString(launchIntent.getFlags()));
            }
            // ! https://stackoverflow.com/questions/12074980/bring-application-to-front-after-user-clicks-on-home-button
            launchIntent.setPackage(null);
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK);
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED);
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_PREVIOUS_IS_TOP);

            if (Mode.DEBUG) {
                Log.d(TAG, "Launching " + packageName + " intent " + Integer.toHexString(launchIntent.getFlags()));
            }
            ActivityOptions options = null;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                options = ActivityOptions.makeBasic();
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    // No - security issue
                    // BootReceiver error java.lang.SecurityException: Permission Denial: starting Intent { act=android.intent.action.MAIN cat=[android.intent.category.LAUNCHER] flg=0x15228000 cmp=com.tekartik.simple_kiosk_app/com.tekartik.example.MainActivity } from ProcessRecord{817a7c6 5973:com.tekartik.simple_kiosk_app/u0a301} (pid=5973, uid=10301) with lockTaskMode=true
                    //options.setLockTaskEnabled(true);
                }
            }
            context.startActivity(launchIntent, options == null ? null : options.toBundle());
        } else {
            if (Mode.DEBUG) {
                Log.d(TAG, "No launch intent for " + packageName);
            }
        }
    }
    static KioskPackageInfo packageInfoToKioskPackageInfo(PackageManager packageManager, PackageInfo packageInfo) {
        ApplicationInfo applicationInfo = packageInfo.applicationInfo;
        // ApplicationInfo applicationInfo = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA);
        KioskPackageInfo kioskPackageInfo = new KioskPackageInfo();
        if (applicationInfo != null) {

            Intent launchIntent = packageManager.getLaunchIntentForPackage(packageInfo.packageName);
            if (launchIntent != null) {
                kioskPackageInfo.launchable = true;
            }
            kioskPackageInfo.appName = packageManager.getApplicationLabel(applicationInfo);
            if ((applicationInfo.flags & ApplicationInfo.FLAG_SYSTEM) == 0) {
                kioskPackageInfo.user = true;
            }
        }
        kioskPackageInfo.packageName = packageInfo.packageName;
        kioskPackageInfo.versionName = packageInfo.versionName;
        // Launchable

        return kioskPackageInfo;
    }

    // Null means not found
    public static List<KioskPackageInfo> getInstalledPackageInfos(Context context) {

        PackageManager packageManager = context.getPackageManager();
        List<PackageInfo> packageInfos = packageManager.getInstalledPackages(PackageManager.GET_META_DATA);
        List<KioskPackageInfo> kioskPackageInfos = new ArrayList<>();
        for (PackageInfo packageInfo : packageInfos) {
            kioskPackageInfos.add(packageInfoToKioskPackageInfo(packageManager, packageInfo));
        }

        return kioskPackageInfos;
    }


    static private boolean kioskModeOn = false;
    public static void startKioskMode(Context context) {
        if (Mode.DEBUG) {
            Log.d(TAG, "Starting kiosk mode");
            debugLastCurrentPackage = null;
        }

        Intent intent = new Intent(context.getApplicationContext(), KioskService.class);


        // Set handler
        ComponentName componentName = context.startService(intent);
        if (componentName == null) {
            throw new IllegalStateException("Kiosk service not found");
        }
        kioskModeOn = true;
        //startPinnedMode(activity);

    }


    public static void stopKioskMode(Context context) {
        if (Mode.DEBUG) {
            Log.d(TAG, "Stopping kiosk mode");
        }
        Intent intent = new Intent(context, KioskService.class);
        context.stopService(intent);
        kioskModeOn = false;

        //stopPinnedMode(activity);
    }

    public static boolean isKioskModeOn(Context context) {
        return kioskModeOn;
    }

}
