package com.tekartik.kiosk;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.util.Log;

public class BootReceiver extends BroadcastReceiver {

    private static final String TAG = "/TKiosk"; // BootReceiver.class.getSimpleName();

    @Override
    public void onReceive(Context context, Intent intent) {


        try {
            try {
                if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
                    String launchPackageName = getLaunchPackageName(context);
                    if (launchPackageName != null) {

                        Log.i(TAG, "BOOT detected launching " + launchPackageName);
                        KioskUtils.launchPackage(context, launchPackageName);
                    } else {
                        if (Mode.DEBUG) {
                            Log.i(TAG, "BOOT detected no app to launch");
                        }
                    }
                }
            } catch (Exception e) {
                Log.e(TAG, "BootReceiver error " + e, e);
            }
        } catch (Exception ignore) {

        }
    }

    static final String LAUNCH_PACKAGE_NAME_PREF_KEY = "packageName";
    static final String PREFS_NAME = "tekartik_kiosk_boot_receiver";

    static SharedPreferences getBootSharedPreferences(Context context) {
        SharedPreferences sharedPreferences = context.getApplicationContext().getSharedPreferences(PREFS_NAME, 0);
        return sharedPreferences;
    }

    static public void setLaunchPackageName(Context context, String packageName) {
        SharedPreferences.Editor editor =
                getBootSharedPreferences(context).edit();
        if (packageName == null) {
            editor = editor.remove(LAUNCH_PACKAGE_NAME_PREF_KEY);

        } else {
            editor = editor.putString(LAUNCH_PACKAGE_NAME_PREF_KEY, packageName);
        }
        editor.apply();
        ;
    }

    static public String getLaunchPackageName(Context context) {
        String launchPackageName = getBootSharedPreferences(context).getString(LAUNCH_PACKAGE_NAME_PREF_KEY, null);
        return launchPackageName;
    }

}
