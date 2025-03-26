package com.tekartik.kiosk;

import android.app.Service;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.IBinder;
import android.os.Process;
import android.provider.Settings;
import android.util.Log;

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

public class KioskService extends Service {

    public static String TAG = "/TKioskService";

    public static String EXTRA_ACTIVITY_START_CLASS_NAME = "activity_start_class_name";

    private static final long INTERVALMS = 400;

    private Thread thread = null;
    private boolean running = false;

    private static Class<?> startActivityClass;

    public static void setStartClass(Class<?> cls) {
        startActivityClass = cls;
    }

    @Override
    public void onDestroy() {

        Log.d(TAG, "Stopping service 'KioskService'");
        if (running) {
            restoreApp();
        }
        running = false;
        super.onDestroy();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {

        if (thread != null) {
            Log.i(TAG, "onStartCommand: service 'KioskService' already running");
            return Service.START_STICKY;
        }
        Log.i(TAG, "onStartCommand: Starting service 'KioskService'");
        running = true;

        //if (startActivityClass == null) {
        //    Log.e(TAG, "Missing start class");
        //}
        /*

        try {
            String className = intent.getExtras().getString(EXTRA_ACTIVITY_START_CLASS_NAME, null);
            startActivityClass = Class.forName(className);
        } catch (Exception e) {
            // we get this on crash in debug - ignore
            // http://stackoverflow.com/questions/4679654/unable-to-start-service-service-name-with-null
            if (e.getCause() == null) {
                return Service.START_STICKY;
            }
            Log.e(TAG, "Missing start class");
            e.printStackTrace();
            throw new RuntimeException(e);

        }

         */

        // start a thread that periodically checks if app is in the foreground
        thread = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    Log.d(TAG, "in thread");

                    Thread.setDefaultUncaughtExceptionHandler(new Thread.UncaughtExceptionHandler() {

                        @Override
                        public void uncaughtException(Thread thread, Throwable e) {

                            e.printStackTrace();
                            Log.e(TAG, "crash", e);

                            // restart main activity
                            restoreApp();

                            Process.killProcess(Process.myPid());
                            System.exit(0);
                        }
                    });
                    do {

                        handleKioskMode();
                        try {
                            Thread.sleep(INTERVALMS);
                        } catch (InterruptedException e) {
                            e.printStackTrace();

                        }
                    } while (running);
                    Thread.setDefaultUncaughtExceptionHandler(null);
                    Log.d(TAG, "thread done");
                    stopSelf();
                } catch (Exception e) {
                    Log.d(TAG, "thread exception " + e);
                    stopSelf();
                }
            }
        });

        Log.e(TAG, "Starting thread");

        thread.start();
        return Service.START_STICKY;
    }

    private void handleKioskMode() {
        // is Kiosk Mode active?

        //if (KioskUtils.isKioskModeActive(ctx)) {
        //Log.i(TAG, "check kiosk mode");
        // is App in background?

        if (KioskUtils.isInBackground(this)) {
            Log.i(TAG, "in background");
            restoreApp(); // restore!
        }
        //}
    }


    private void restoreApp() {
        /*
        // Restart activity
        Log.d(TAG, "Restoring kiosk mode to " + startActivityClass.getName());
        Intent i = new Intent(this, startActivityClass);
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(i);

         */
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                Log.d(TAG, "ACTION_MANAGE_OVERLAY_PERMISSION");
                Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:" + this.getPackageName()));
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    intent.addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK);
                }
                startActivity(intent);
            } else {
                startApp();
            }
        } else {
            startApp();
        }
    }

    private void startApp() {

        Log.d(TAG, "Restarting app");
        PackageManager pm = getPackageManager();
        Intent launchIntent = pm.getLaunchIntentForPackage(getPackageName());
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            launchIntent.addFlags(
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT |
                            Intent.FLAG_ACTIVITY_NEW_TASK |
                            Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED);
        } else {
            launchIntent.addFlags(

                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT |

                            Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED);
        }
        //launchIntent.putExtra("some_data", "value");
        startActivity(launchIntent);

    }


    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}