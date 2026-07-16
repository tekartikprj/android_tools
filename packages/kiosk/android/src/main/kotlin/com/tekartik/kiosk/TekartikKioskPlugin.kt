package com.tekartik.kiosk

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/**
 * TekartikKioskPlugin
 */
class TekartikKioskPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    private var currentActivity: ActivityPluginBinding? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "tekartik_kiosk")
        channel.setMethodCallHandler(this)
    }

    internal class RequestPermissionData {
        var activityPluginBinding: ActivityPluginBinding? = null
        var listener: PluginRegistry.ActivityResultListener? = null

        fun cleanup() {
            try {
                val listener = this.listener
                if (listener != null) {
                    activityPluginBinding?.removeActivityResultListener(listener)
                }
            } catch (ignore: Exception) {
            }
        }
    }

    private fun getPermissionInfoMap(): Map<String, Any?> {
        val map = HashMap<String, Any?>()
        map["needPermissionForUsageStat"] = KioskUtils.needPermissionForUsageStat(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(context)) {
                map["needOverlayPermission"] = true
            }
        }
        return map
    }

    internal class MethodInfo(val call: MethodCall, val result: Result) {
        val method: String get() = call.method

        fun success(successResult: Any?) {
            result.success(successResult)
        }

        fun error(errorCode: String, message: String?, details: Any?) {
            result.error(errorCode, message, details)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val methodInfo = MethodInfo(call, result)
        when (methodInfo.method) {
            "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")
            "getCurrentRunningPackageInfo" -> {
                try {
                    val map = HashMap<String, Any?>()
                    map["package"] = KioskUtils.getCurrentPackageName(context)
                    result.success(map)
                } catch (e: Exception) {
                    result.error(ERROR_CODE_DEFAULT, e.message, null)
                }
            }

            "getPermissionInfo" -> {
                try {
                    result.success(getPermissionInfoMap())
                } catch (e: Exception) {
                    result.error(ERROR_CODE_DEFAULT, e.message, null)
                }
            }

            "requestPermissionForUsageStat" -> handleRequestPermissionForUsageStat(methodInfo)
            "getPackageInfo" -> handleGetPackageInfo(methodInfo)
            "requestOverlayPermission" -> handleRequestOverlayPermission(methodInfo)
            "launch" -> handleLaunch(methodInfo)
            "getInstalledPackageInfos" -> handleGetInstalledPackageInfos(methodInfo)
            "setBootReceiverOptions" -> handleSetBootReceiverOptions(methodInfo)
            "getBootReceiverOptions" -> handleGetBootReceiverOptions(methodInfo)
            "startKioskMode" -> handleStartKioskMode(methodInfo)
            "stopKioskMode" -> handleStopKioskMode(methodInfo)
            "startPinnedMode" -> handleStartPinnedMode(methodInfo)
            "stopPinnedMode" -> handleStopPinnedMode(methodInfo)
            "getModeInfo" -> handleGetModeInfo(methodInfo)
            "setDevMode" -> handleSetDevMode(methodInfo)
            else -> result.notImplemented()
        }
    }

    private fun sendSuccessResultPermissionMap(methodInfo: MethodInfo) {
        methodInfo.result.success(getPermissionInfoMap())
    }

    private fun handleRequestPermissionForUsageStat(methodInfo: MethodInfo) {
        val data = RequestPermissionData()
        data.activityPluginBinding = currentActivity
        val permissionRequestCode = 12346
        try {
            if (KioskUtils.needPermissionForUsageStat(context)) {
                val activityPluginBinding = data.activityPluginBinding!!
                val activity = activityPluginBinding.activity
                data.listener = PluginRegistry.ActivityResultListener { requestCode, _, _ ->
                    if (requestCode == permissionRequestCode) {
                        data.cleanup()
                        sendSuccessResultPermissionMap(methodInfo)
                    }
                    false
                }

                activityPluginBinding.addActivityResultListener(data.listener!!)

                if (!KioskUtils.requestPermissionForUsageStat(activity, permissionRequestCode)) {
                    data.cleanup()
                    sendSuccessResultPermissionMap(methodInfo)
                }
            } else {
                data.cleanup()
                sendSuccessResultPermissionMap(methodInfo)
            }
        } catch (e: Exception) {
            data.cleanup()
            methodInfo.result.error(ERROR_CODE_DEFAULT, e.message, null)
        }
    }

    private fun handleRequestOverlayPermission(methodInfo: MethodInfo) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (!Settings.canDrawOverlays(context)) {
                    val data = RequestPermissionData()
                    data.activityPluginBinding = currentActivity
                    val permissionRequestCode = 12347
                    try {
                        val activityPluginBinding = data.activityPluginBinding!!
                        val activity = activityPluginBinding.activity
                        data.listener = PluginRegistry.ActivityResultListener { requestCode, _, _ ->
                            if (requestCode == permissionRequestCode) {
                                data.cleanup()
                                sendSuccessResultPermissionMap(methodInfo)
                            }
                            false
                        }

                        activityPluginBinding.addActivityResultListener(data.listener!!)

                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:${context.packageName}")
                        )
                        activity.startActivityForResult(intent, permissionRequestCode)
                    } catch (e: Exception) {
                        data.cleanup()
                        methodInfo.result.error(ERROR_CODE_DEFAULT, e.message, null)
                    }
                    return
                }
            }
            sendSuccessResultPermissionMap(methodInfo)
        } catch (e: Exception) {
            handleException(methodInfo, e)
        }
    }

    private fun handleGetPackageInfo(methodInfo: MethodInfo) {
        try {
            val packageName = methodInfo.call.argument<String>("package") ?: context.packageName
            methodInfo.success(toPackageInfoMap(KioskUtils.getPackageInfo(context, packageName)))
        } catch (e: Exception) {
            handleException(methodInfo, e)
        }
    }

    private fun handleLaunch(methodInfo: MethodInfo) {
        try {
            val packageName = methodInfo.call.argument<String>("package") ?: context.packageName
            if (Mode.DEBUG) {
                Log.d(KioskService.TAG, "Handling method launch for package $packageName")
            }
            KioskUtils.launchPackage(context, packageName)
            methodInfo.success(null)
        } catch (e: Exception) {
            handleException(methodInfo, e)
        }
    }

    private fun handleStartKioskMode(methodInfo: MethodInfo) {
        try {
            KioskUtils.startKioskMode(context)
            methodInfo.success(null)
        } catch (e: Exception) {
            handleException(methodInfo, e)
        }
    }

    private fun handleStopKioskMode(methodInfo: MethodInfo) {
        try {
            KioskUtils.stopKioskMode(context)
            methodInfo.success(null)
        } catch (e: Exception) {
            handleException(methodInfo, e)
        }
    }

    private fun handleStartPinnedMode(methodInfo: MethodInfo) {
        try {
            KioskUtils.startPinnedMode(currentActivity!!.activity)
            methodInfo.success(null)
        } catch (e: Exception) {
            handleException(methodInfo, e)
        }
    }

    private fun handleStopPinnedMode(methodInfo: MethodInfo) {
        try {
            KioskUtils.stopPinnedMode(currentActivity!!.activity)
            methodInfo.success(null)
        } catch (e: Exception) {
            handleException(methodInfo, e)
        }
    }

    private fun handleSetBootReceiverOptions(methodInfo: MethodInfo) {
        try {
            val packageName = methodInfo.call.argument<String>("package")
            BootReceiver.setLaunchPackageName(context, packageName)
            methodInfo.success(null)
        } catch (e: Exception) {
            handleException(methodInfo, e)
        }
    }

    private fun handleGetModeInfo(methodInfo: MethodInfo) {
        try {
            val pinnedOn = KioskUtils.getPinnedMode(currentActivity!!.activity)
            val map = HashMap<String, Any?>()
            map["kioskOn"] = KioskUtils.isKioskModeOn(context)
            map["pinnedOn"] = pinnedOn
            map["pinnedSupported"] = Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP
            methodInfo.success(map)
        } catch (e: Exception) {
            handleException(methodInfo, e)
        }
    }

    private fun handleSetDevMode(methodInfo: MethodInfo) {
        try {
            val debugOn = methodInfo.call.argument<Boolean>("debug")!!
            Mode.DEBUG = debugOn
            methodInfo.success(null)
        } catch (e: Exception) {
            handleException(methodInfo, e)
        }
    }

    private fun handleGetBootReceiverOptions(methodInfo: MethodInfo) {
        try {
            val packageName = BootReceiver.getLaunchPackageName(context)

            val map = HashMap<String, Any?>()
            map["package"] = packageName
            methodInfo.success(map)
        } catch (e: Exception) {
            handleException(methodInfo, e)
        }
    }

    private fun handleGetInstalledPackageInfos(methodInfo: MethodInfo) {
        try {
            methodInfo.result.success(toPackageInfosMap(KioskUtils.getInstalledPackageInfos(context)))
        } catch (e: Exception) {
            handleException(methodInfo, e)
        }
    }

    private fun handleException(methodInfo: MethodInfo, e: Exception) {
        try {
            methodInfo.error(ERROR_CODE_DEFAULT, e.message, methodInfo.call)
        } catch (ignore: Exception) {
        }
    }

    private fun toPackageInfoMap(info: KioskUtils.KioskPackageInfo?): Map<String, Any?>? {
        if (info == null) {
            return null
        }
        val map = HashMap<String, Any?>()
        map["package"] = info.packageName
        map["name"] = info.appName
        map["version"] = info.versionName
        map["user"] = info.user
        map["launchable"] = info.launchable
        //map["longVersionCode"] = info.longVersionCode
        return map
    }

    private fun toPackageInfosMap(infos: List<KioskUtils.KioskPackageInfo>): Map<String, Any?> {
        val map = HashMap<String, Any?>()
        val list = ArrayList<Map<String, Any?>?>()
        for (info in infos) {
            list.add(toPackageInfoMap(info))
        }
        map["list"] = list
        return map
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.currentActivity = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    }

    override fun onDetachedFromActivity() {
    }

    companion object {
        const val ERROR_CODE_DEFAULT = "error"
    }
}
