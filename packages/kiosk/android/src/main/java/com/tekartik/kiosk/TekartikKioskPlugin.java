package com.tekartik.kiosk;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

/**
 * TekartikKioskPlugin
 */
public class TekartikKioskPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;
    private Context context;

    private ActivityPluginBinding currentActivity;

    static final String ERROR_CODE_DEFAULT = "error";

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        context = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "tekartik_kiosk");
        channel.setMethodCallHandler(this);

    }

    static class RequestPermissionData {
        ActivityPluginBinding activityPluginBinding;
        PluginRegistry.ActivityResultListener listener;

        void cleanup() {
            try {
                if (listener != null) {
                    activityPluginBinding.removeActivityResultListener(listener);
                }
            } catch (Exception ignore) {
            }
        }
    }

    Map<String, Object> getPermissionInfoMap() {
        Map<String, Object> map = new HashMap();
        map.put("needPermissionForUsageStat", KioskUtils.needPermissionForUsageStat(context));
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(context)) {
                map.put("needOverlayPermission", true);
            }
        }
        return map;
    }

    static class MethodInfo {
        final @NonNull
        MethodCall call;
        final @NonNull
        Result result;

        MethodInfo(@NonNull MethodCall call, @NonNull Result result) {
            this.call = call;
            this.result = result;
        }

        public String getMethod() {
            return call.method;
        }

        public void success(Object successResult) {
            result.success(successResult);
        }

        public void error(String errorCode, String message, Object call) {
            result.error(errorCode, message, call);
        }
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, final @NonNull Result result) {
        MethodInfo methodInfo = new MethodInfo(call, result);
        String method = methodInfo.getMethod();
        if (method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        }

        if (method.equals("getCurrentRunningPackageInfo")) {
            try {
                Map<String, Object> map = new HashMap();
                map.put("package", KioskUtils.getCurrentPackageName(context));

                result.success(map);
            } catch (Exception e) {
                result.error(ERROR_CODE_DEFAULT, e.getMessage(), null);
            }
        } else if (method.equals("getPermissionInfo")) {
            try {
                result.success(getPermissionInfoMap());
            } catch (Exception e) {
                result.error(ERROR_CODE_DEFAULT, e.getMessage(), null);
            }
        } else if (method.equals("requestPermissionForUsageStat")) {
            handleRequestPermissionForUsageStat(methodInfo);
        } else if (method.equals("getPackageInfo")) {
            handleGetPackageInfo(methodInfo);
        } else if (method.equals("requestOverlayPermission")) {
            handleRequestOverlayPermission(methodInfo);
        } else if (method.equals("launch")) {
            handleLaunch(methodInfo);
        } else if (method.equals("getInstalledPackageInfos")) {
            handleGetInstalledPackageInfos(methodInfo);
        } else if (method.equals("setBootReceiverOptions")) {
            handleSetBootReceiverOptions(methodInfo);
        } else if (method.equals("getBootReceiverOptions")) {
            handleGetBootReceiverOptions(methodInfo);
        } else if (method.equals("startKioskMode")) {
            handleStartKioskMode(methodInfo);
        } else if (method.equals("stopKioskMode")) {
            handleStopKioskMode(methodInfo);
        } else if (method.equals("startPinnedMode")) {
            handleStartPinnedMode(methodInfo);
        } else if (method.equals("stopPinnedMode")) {
            handleStopPinnedMode(methodInfo);
        }else if (method.equals("getModeInfo")) {
            handleGetModeInfo(methodInfo);
        }else if (method.equals("setDevMode")) {
            handleSetDevMode(methodInfo);
        }
        else {
            result.notImplemented();
        }
    }

    private void sendSuccessResultPermissionMap(MethodInfo methodInfo) {
        methodInfo.result.success(getPermissionInfoMap());
    }

    private void handleRequestPermissionForUsageStat(final MethodInfo methodInfo) {
        final RequestPermissionData data = new RequestPermissionData();
        data.activityPluginBinding = currentActivity;
        final int permissionRequestCode = 12346;
        try {
            if (KioskUtils.needPermissionForUsageStat(context)) {

                Activity activity = data.activityPluginBinding.getActivity();
                data.listener = new PluginRegistry.ActivityResultListener() {
                    @Override
                    public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {
                        if (requestCode == permissionRequestCode) {
                            data.cleanup();
                            sendSuccessResultPermissionMap(methodInfo);
                        }
                        return false;
                    }
                };

                data.activityPluginBinding.addActivityResultListener(data.listener);

                if (!KioskUtils.requestPermissionForUsageStat(activity, permissionRequestCode)) {
                    data.cleanup();
                    sendSuccessResultPermissionMap(methodInfo);
                }


            } else {
                data.cleanup();
                sendSuccessResultPermissionMap(methodInfo);
            }

        } catch (Exception e) {
            data.cleanup();
            methodInfo.result.error(ERROR_CODE_DEFAULT, e.getMessage(), null);
        }
    }

    private void handleRequestOverlayPermission(final MethodInfo methodInfo) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (!Settings.canDrawOverlays(context)) {
                    final RequestPermissionData data = new RequestPermissionData();
                    data.activityPluginBinding = currentActivity;
                    final int permissionRequestCode = 12347;
                    try {


                        Activity activity = data.activityPluginBinding.getActivity();
                        data.listener = new PluginRegistry.ActivityResultListener() {
                            @Override
                            public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {
                                if (requestCode == permissionRequestCode) {
                                    data.cleanup();
                                    sendSuccessResultPermissionMap(methodInfo);
                                }
                                return false;
                            }
                        };

                        data.activityPluginBinding.addActivityResultListener(data.listener);

                        Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:" + context.getPackageName()));
                        activity.startActivityForResult(intent, permissionRequestCode);

        /*
        Map<String, Object> map = new HashMap();
        map.put("needPermissionForUsageStat", KioskUtils.needPermissionForUsageStat(context));

        result.success(map);
        */


                    } catch (Exception e) {
                        data.cleanup();
                        methodInfo.result.error(ERROR_CODE_DEFAULT, e.getMessage(), null);
                    }
                    return;

                }
            }
            sendSuccessResultPermissionMap(methodInfo);
        } catch (Exception e) {
            handleException(methodInfo, e);
        }
    }

    private void handleGetPackageInfo(MethodInfo methodInfo) {
        try {
            String packageName = methodInfo.call.argument("package");
            if (packageName == null) {
                packageName = context.getPackageName();
            }
            methodInfo.success(toPackageInfoMap(KioskUtils.getPackageInfo(context, packageName)));
        } catch (Exception e) {
            handleException(methodInfo, e);
        }
    }

    private void handleLaunch(MethodInfo methodInfo) {
        try {
            String packageName = methodInfo.call.argument("package");
            if (packageName == null) {
                packageName = context.getPackageName();
            }
            KioskUtils.launchPackage(context, packageName);
            methodInfo.success(null);
        } catch (Exception e) {
            handleException(methodInfo, e);
        }
    }

    private void handleStartKioskMode(MethodInfo methodInfo) {
        try {
            KioskUtils.startKioskMode(context);
            methodInfo.success(null);
        } catch (Exception e) {
            handleException(methodInfo, e);
        }
    }

    private void handleStopKioskMode(MethodInfo methodInfo) {
        try {
            KioskUtils.stopKioskMode(context);
            methodInfo.success(null);
        } catch (Exception e) {
            handleException(methodInfo, e);
        }
    }


    private void handleStartPinnedMode(MethodInfo methodInfo) {
        try {
            KioskUtils.startPinnedMode(currentActivity.getActivity());
            methodInfo.success(null);
        } catch (Exception e) {
            handleException(methodInfo, e);
        }
    }

    private void handleStopPinnedMode(MethodInfo methodInfo) {
        try {
            KioskUtils.stopPinnedMode(currentActivity.getActivity());
            methodInfo.success(null);
        } catch (Exception e) {
            handleException(methodInfo, e);
        }
    }

    private void handleSetBootReceiverOptions(MethodInfo methodInfo) {
        try {
            String packageName = methodInfo.call.argument("package");
            BootReceiver.setLaunchPackageName(context, packageName);
            methodInfo.success(null);
        } catch (Exception e) {
            handleException(methodInfo, e);
        }
    }

    private void handleGetModeInfo(MethodInfo methodInfo) {
        try {
            boolean pinnedOn = KioskUtils.getPinnedMode(currentActivity.getActivity());
            Map<String, Object> map = new HashMap();
            map.put("kioskOn", KioskUtils.isKioskModeOn(context));
            map.put("pinnedOn", pinnedOn);
            map.put("pinnedSupported", (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP));
            methodInfo.success(map);
        } catch (Exception e) {
            handleException(methodInfo, e);
        }
    }


    private void handleSetDevMode(MethodInfo methodInfo) {
        try {
            boolean debugOn = methodInfo.call.argument("debug");
            Mode.DEBUG = debugOn;
            methodInfo.success(null);
        } catch (Exception e) {
            handleException(methodInfo, e);
        }
    }

    private void handleGetBootReceiverOptions(MethodInfo methodInfo) {
        try {

            String packageName = BootReceiver.getLaunchPackageName(context);

            Map<String, Object> map = new HashMap();
            map.put("package", packageName);
            methodInfo.success(map);
        } catch (Exception e) {
            handleException(methodInfo, e);
        }
    }


    private void handleGetInstalledPackageInfos(MethodInfo methodInfo) {
        try {
            methodInfo.result.success(toPackageInfosMap(KioskUtils.getInstalledPackageInfos(context)));
        } catch (Exception e) {
            handleException(methodInfo, e);
        }
    }

    private void handleException(MethodInfo methodInfo, Exception e) {
        try {
            methodInfo.error(ERROR_CODE_DEFAULT, e.getMessage(), methodInfo.call);
        } catch (Exception ignore) {
        }
    }

    Map<String, Object> toPackageInfoMap(@Nullable KioskUtils.KioskPackageInfo info) {
        if (info == null) {
            return null;
        }
        Map<String, Object> map = new HashMap<>();
        map.put("package", info.packageName);
        map.put("name", info.appName);
        map.put("version", info.versionName);
        map.put("user", info.user);
        map.put("launchable", info.launchable);
        //map.put("longVersionCode", info.longVersionCode);
        return map;
    }

    Map<String, Object> toPackageInfosMap(List<KioskUtils.KioskPackageInfo> infos) {
        Map<String, Object> map = new HashMap<>();
        List<Map<String, Object>> list = new ArrayList<>();
        for (KioskUtils.KioskPackageInfo info : infos) {
            list.add(toPackageInfoMap(info));
        }
        map.put("list", list);
        return map;
    }

    /*
    //PackageInfo getPackageInfo()
    void handleGetPackageInfo() {
        try {
            PackageManager packageManager = context.getPackageManager();
            ApplicationInfo applicationInfo = packageManager.getApplicationInfo(context.getPackageName(), 0);

        } catch (PackageManager.NameNotFoundException e) {
            return true;
        }
    }*/

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.currentActivity = binding;

    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }
}
