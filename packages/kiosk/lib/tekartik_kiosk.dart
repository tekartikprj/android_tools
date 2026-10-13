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

  /// Invokes [method], its result must be a map converted using [fromMap].
  static Future<T> _invokeMap<T>(
    String method,
    T Function(Map map) fromMap, [
    Object? arguments,
  ]) async {
    var result = await _channel.invokeMethod<Object?>(method, arguments);
    if (result is Map) {
      return fromMap(result);
    }
    throw ArgumentError.value(result);
  }

  /// Invokes [method], its result must be a map with a 'list' of maps, each
  /// one converted using [fromMap].
  static Future<List<T>> _invokeList<T>(
    String method,
    T Function(Map map) fromMap,
  ) async {
    var result = await _channel.invokeMethod<Object?>(method);
    if (result is Map) {
      var list = result['list'];
      if (list is List) {
        return list.map((map) => fromMap(map as Map)).toList();
      }
    }
    throw ArgumentError.value(result);
  }

  @override
  Future<RunningPackageInfo> getCurrentRunningPackageInfo() => _invokeMap(
    'getCurrentRunningPackageInfo',
    (map) => RunningPackageInfo()..fromMap(map),
  );

  @override
  Future<List<RunningProcessInfo>> getRunningProcesses() => _invokeList(
    'getRunningProcesses',
    (map) => RunningProcessInfo()..fromMap(map),
  );

  @override
  Future<PermissionInfo> getPermissionInfo() =>
      _invokeMap('getPermissionInfo', (map) => PermissionInfo()..fromMap(map));

  /// The response is returned right away so you need polling on the permission
  @override
  Future<PermissionInfo> requestPermissionForUsageStat() => _invokeMap(
    'requestPermissionForUsageStat',
    (map) => PermissionInfo()..fromMap(map),
  );

  /// The response is returned right away so you need polling on the permission
  @override
  Future<PermissionInfo> requestOverlayPermission() => _invokeMap(
    'requestOverlayPermission',
    (map) => PermissionInfo()..fromMap(map),
  );

  @override
  Future<PackageInfo> getPackageInfo({String? packageName}) => _invokeMap(
    'getPackageInfo',
    (map) => PackageInfo()..fromMap(map),
    {'package': packageName},
  );

  @override
  Future<List<PackageInfo>> getInstalledPackageInfos() => _invokeList(
    'getInstalledPackageInfos',
    (map) => PackageInfo()..fromMap(map),
  );

  @override
  Future<void> launch({String? packageName}) async {
    await _channel.invokeMethod('launch', {'package': packageName});
  }

  @override
  Future<BootReceiverOptions> getBootReceiverOptions() => _invokeMap(
    'getBootReceiverOptions',
    (map) => BootReceiverOptions()..fromMap(map),
  );

  @override
  Future<void> setBootReceiverOptions(BootReceiverOptions options) async {
    await _channel.invokeMethod('setBootReceiverOptions', options.toMap());
  }

  @override
  Future<void> setKioskOptions(KioskOptions options) async {
    await _channel.invokeMethod('setKioskOptions', options.toMap());
  }

  @override
  Future<KioskOptions> getKioskOptions() =>
      _invokeMap('getKioskOptions', (map) => KioskOptions()..fromMap(map));

  @override
  Future<void> startKioskMode({KioskOptions? options}) async {
    await _channel.invokeMethod('startKioskMode', options?.toMap());
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
  Future<ModeInfo> getModeInfo() =>
      _invokeMap('getModeInfo', (map) => ModeInfo()..fromMap(map));
}
