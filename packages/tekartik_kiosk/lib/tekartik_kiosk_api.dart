// You have generated a new plugin project without
// specifying the `--platforms` flag. A plugin project supports no platforms is generated.
// To add platforms, run `flutter create -t plugin --platforms <platforms> .` under the same
// directory. You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

// ignore: unnecessary_import, depend_on_referenced_packages
import 'package:tekartik_common_utils/bool_utils.dart';
// ignore: depend_on_referenced_packages
import 'package:tekartik_common_utils/common_utils_import.dart';

class PackageInfo {
  String? package;
  String? name;
  String? version;
  bool? user;
  bool? launchable;

  void fromMap(Map map) {
    package = map['package']?.toString();
    name = map['name']?.toString();
    version = map['version']?.toString();
    user = parseBool(map['user']);
    launchable = parseBool(map['launchable']);
  }

  Map<String, Object?> toMap() {
    return {
      'package': package,
      if (name != null) 'name': name,
      'version': version,
      if (user ?? false) 'user': user,
      if (launchable ?? false) 'launchable': launchable,
    };
  }

  @override
  String toString() => toMap().toString();
}

class BootReceiverOptions {
  String? package;

  void fromMap(Map map) {
    package = map['package']?.toString();
  }

  Map<String, Object?> toMap() {
    return {'package': package};
  }

  @override
  String toString() => toMap().toString();
}

class RunningPackageInfo {
  String? package;

  void fromMap(Map map) {
    package = map['package']?.toString();
  }

  Map<String, Object?> toMap() {
    return {'package': package};
  }

  @override
  String toString() => toMap().toString();
}

class ModeInfo {
  late bool kioskOn;
  late bool pinnedOn;
  late bool pinnedSupported;

  void fromMap(Map map) {
    kioskOn = parseBool(map['kioskOn']) ?? false;
    pinnedOn = parseBool(map['pinnedOn']) ?? false;
    pinnedSupported = parseBool(map['pinnedSupported']) ?? false;
  }

  Map<String, Object?> toMap() {
    return {
      'kioskOn': kioskOn,
      'pinnedModeOn': pinnedOn,
      'pinnedSupported': pinnedSupported
    };
  }

  @override
  String toString() => toMap().toString();
}

class DevModeInfo {
  bool? debug;

  Map<String, Object?> toMap() {
    return {'debug': debug ?? false};
  }

  @override
  String toString() => toMap().toString();
}

class PermissionInfo {
  late bool needPermissionForUsageStat;
  late bool needOverlayPermission;

  void fromMap(Map map) {
    needPermissionForUsageStat =
        parseBool(map['needPermissionForUsageStat']) ?? false;
    needOverlayPermission = parseBool(map['needOverlayPermission']) ?? false;
  }

  Map<String, Object?> toMap() {
    return {
      'needPermissionForUsageStat': needPermissionForUsageStat,
      'needOverlayPermission': needOverlayPermission
    };
  }

  @override
  String toString() => toMap().toString();
}

abstract class TekartikKiosk {
  /// Current Running package
  Future<RunningPackageInfo> getCurrentRunningPackageInfo();

  /// Permissin info (needed before calling getCurrentRunningPackageInfo)
  Future<PermissionInfo> getPermissionInfo();

  /// TODO result might be available later
  Future<PermissionInfo> requestPermissionForUsageStat();

  /// The response is returned right away so you need polling on the permission
  Future<PermissionInfo> requestOverlayPermission();

  /// Get package info, current if packageName is null, throw if not found
  Future<PackageInfo> getPackageInfo({String? packageName});

  /// List of installed package
  Future<List<PackageInfo>> getInstalledPackageInfos();

  /// Launch the package using the default launch intent
  Future<void> launch({String? packageName});

  /// Get boot options
  Future<BootReceiverOptions> getBootReceiverOptions();

  /// Set boot options
  Future<void> setBootReceiverOptions(BootReceiverOptions options);

  /// Start kiosk mode
  Future<void> startKioskMode();

  /// Stop kiosk mode
  Future<void> stopKioskMode();

  /// Start pinned mode
  Future<void> startPinnedMode();

  /// Stop pinned mode
  Future<void> stopPinnedMode();

  /// Get kiosk/pinned mode info
  Future<ModeInfo> getModeInfo();

  /// Set internal dev mode, deprecated on purpose
  @Deprecated('Dev only')
  Future<void> setDevMode(DevModeInfo info);
}

class TekartikKioskMock with TekartikKioskMockMixin implements TekartikKiosk {}

mixin TekartikKioskMockMixin implements TekartikKiosk {
  @override
  Future<RunningPackageInfo> getCurrentRunningPackageInfo() {
    throw UnimplementedError();
  }

  @override
  Future<PermissionInfo> getPermissionInfo() {
    throw UnimplementedError();
  }

  @override
  Future<PermissionInfo> requestPermissionForUsageStat() {
    throw UnimplementedError();
  }

  @override
  Future<PermissionInfo> requestOverlayPermission() {
    throw UnimplementedError();
  }

  @override
  Future<PackageInfo> getPackageInfo({String? packageName}) {
    throw UnimplementedError();
  }

  @override
  Future<List<PackageInfo>> getInstalledPackageInfos() {
    throw UnimplementedError();
  }

  @override
  Future<void> launch({String? packageName}) {
    throw UnimplementedError();
  }

  @override
  Future<BootReceiverOptions> getBootReceiverOptions() {
    throw UnimplementedError();
  }

  @override
  Future<void> setBootReceiverOptions(BootReceiverOptions options) {
    throw UnimplementedError();
  }

  @override
  Future<void> startKioskMode() {
    throw UnimplementedError();
  }

  @override
  Future<void> stopKioskMode() {
    throw UnimplementedError();
  }

  @override
  Future<void> startPinnedMode() {
    throw UnimplementedError();
  }

  @override
  Future<void> stopPinnedMode() {
    throw UnimplementedError();
  }

  @override
  Future<ModeInfo> getModeInfo() {
    throw UnimplementedError();
  }

  @override
  Future<void> setDevMode(DevModeInfo info) {
    throw UnimplementedError();
  }
}
