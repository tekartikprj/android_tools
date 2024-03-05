// You have generated a new plugin project without
// specifying the `--platforms` flag. A plugin project supports no platforms is generated.
// To add platforms, run `flutter create -t plugin --platforms <platforms> .` under the same
// directory. You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'dart:async';

import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';

// Default implementation uses plugin
TekartikKiosk tekartikKioskPlugin = TekartikKioskPlugin();

class TekartikKioskPlugin implements TekartikKiosk {
  static const MethodChannel _channel = MethodChannel('tekartik_kiosk');

  @override
  Future<RunningPackageInfo> getCurrentRunningPackageInfo() async {
    var result = await _channel.invokeMethod('getCurrentRunningPackageInfo');
    // devPrint(result);
    if (result is Map) {
      return RunningPackageInfo()..fromMap(result);
    } else {
      throw ArgumentError.value(result);
    }
  }

  @override
  Future<PermissionInfo> getPermissionInfo() async {
    var result = await _channel.invokeMethod('getPermissionInfo');
    // devPrint(result);
    if (result is Map) {
      return PermissionInfo()..fromMap(result);
    } else {
      throw ArgumentError.value(result);
    }
  }

  /// The response is returned right away so you need polling on the permission
  @override
  Future<PermissionInfo> requestPermissionForUsageStat() async {
    var result = await _channel.invokeMethod('requestPermissionForUsageStat');
    // devPrint(result);
    if (result is Map) {
      return PermissionInfo()..fromMap(result);
    } else {
      throw ArgumentError.value(result);
    }
  }

  /// The response is returned right away so you need polling on the permission
  @override
  Future<PermissionInfo> requestOverlayPermission() async {
    var result = await _channel.invokeMethod('requestOverlayPermission');
    // devPrint(result);
    if (result is Map) {
      return PermissionInfo()..fromMap(result);
    } else {
      throw ArgumentError.value(result);
    }
  }

  @override
  Future<PackageInfo> getPackageInfo({String? packageName}) async {
    var result =
        await _channel.invokeMethod('getPackageInfo', {'package': packageName});
    // devPrint(result);
    if (result is Map) {
      return PackageInfo()..fromMap(result);
    } else {
      throw ArgumentError.value(result);
    }
  }

  @override
  Future<List<PackageInfo>> getInstalledPackageInfos() async {
    var result = await _channel.invokeMethod('getInstalledPackageInfos');
    // devPrint(result);
    if (result is Map) {
      var list = result['list'];
      if (list is List) {
        return list.map((map) => PackageInfo()..fromMap(map as Map)).toList();
      }
    }
    throw ArgumentError.value(result);
  }

  @override
  Future<void> launch({String? packageName}) async {
    await _channel.invokeMethod('launch', {'package': packageName});
  }

  @override
  Future<BootReceiverOptions> getBootReceiverOptions() async {
    var result = await _channel.invokeMethod('getBootReceiverOptions');
    // devPrint(result);
    if (result is Map) {
      return BootReceiverOptions()..fromMap(result);
    } else {
      throw ArgumentError.value(result);
    }
  }

  @override
  Future<void> setBootReceiverOptions(BootReceiverOptions options) async {
    await _channel.invokeMethod('setBootReceiverOptions', options.toMap());
  }

  @override
  Future<void> startKioskMode() async {
    await _channel.invokeMethod('startKioskMode');
  }

  @override
  Future<void> stopKioskMode() async {
    await _channel.invokeMethod('stopKioskMode');
  }

  @override
  Future<void> startPinnedMode() async {
    await _channel.invokeMethod('startPinnedMode');
  }

  @override
  Future<void> stopPinnedMode() async {
    await _channel.invokeMethod('stopPinnedMode');
  }

  @override
  Future<void> setDevMode(DevModeInfo info) async {
    await _channel.invokeMethod('setDevMode', info.toMap());
  }

  @override
  Future<ModeInfo> getModeInfo() async {
    var result = await _channel.invokeMethod('getModeInfo');
    if (result is Map) {
      return ModeInfo()..fromMap(result);
    } else {
      throw ArgumentError.value(result);
    }
  }
}
