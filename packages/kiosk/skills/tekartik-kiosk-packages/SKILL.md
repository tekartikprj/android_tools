---
name: tekartik-kiosk-packages
description: >-
  Use when inspecting or launching android apps from flutter with
  tekartik_kiosk: getCurrentRunningPackageInfo/RunningPackageInfo,
  getRunningProcesses/RunningProcessInfo (processName, importance, packages),
  getPackageInfo and getInstalledPackageInfos/PackageInfo (package, name,
  version, user, launchable), launch(packageName:), and the usage stats and
  overlay permissions (getPermissionInfo, PermissionInfo,
  requestPermissionForUsageStat, requestOverlayPermission).
---

# Installed packages, foreground app and permissions (tekartik_kiosk)

Besides locking the screen, `tekartik_kiosk` exposes the android package
manager and usage stats: which app is in the foreground, what is installed,
and launching any of them by package name. Locking the app to the foreground
is in the sibling skill
[tekartik-kiosk-mode](../tekartik-kiosk-mode/SKILL.md), which also has the
dependency block and the android `MainActivity` wiring.

## Guidelines

* Android only, through the `tekartik_kiosk` method channel: every call throws
  `MissingPluginException` elsewhere. Call
  `WidgetsFlutterBinding.ensureInitialized()` first, and import both
  `package:tekartik_kiosk/tekartik_kiosk.dart` (for `tekartikKioskPlugin`) and
  `package:tekartik_kiosk/tekartik_kiosk_api.dart` (for `TekartikKiosk` and
  the result classes — the first library does not re-export them).
* Permissions first. `getPermissionInfo()` returns a `PermissionInfo` with
  `needPermissionForUsageStat` (needed by `getCurrentRunningPackageInfo` and
  by the kiosk watchdog) and `needOverlayPermission` (needed to bring an app
  to the front from the background).
* `requestPermissionForUsageStat()` and `requestOverlayPermission()` open the
  corresponding android settings screen and return **immediately** with the
  permission state as it was: the user grants it in another activity, so poll
  `getPermissionInfo()` (for instance on app resume, or every second for a
  few seconds) instead of trusting the returned value.
* `getCurrentRunningPackageInfo()` returns a `RunningPackageInfo` whose
  `package` is the foreground app package name (null when unknown). It is a
  poll, there is no stream: loop with a `Future.delayed` of a second or so and
  only react when the value changes.
* `getRunningProcesses()` returns `RunningProcessInfo`s with `processName`,
  `importance` (the android `RunningAppProcessInfo` importance, lower is more
  foreground) and `packages` (the package names in that process). Recent
  android versions only report your own process, so treat an almost empty list
  as normal, not as an error.
* `getPackageInfo({packageName})` returns the `PackageInfo` of one app, or of
  the current app when `packageName` is null — that is how you get your own
  package name and version. It throws when the package is not installed, so
  wrap it in a `try`/`catch` when the name comes from user data.
* `getInstalledPackageInfos()` lists every installed app as `PackageInfo`
  (`package`, `name`, `version`, `user`, `launchable`). Filter it: `user` is
  true for apps the user installed (false for system apps) and `launchable`
  is true when the app has a launcher intent. It is a full package manager
  scan, so call it once and cache the list rather than per rebuild.
* `launch({packageName})` starts an app with its default launch intent
  (the current app when `packageName` is null, which is how you bring your own
  kiosk app back to the front). It resolves as soon as the intent is sent,
  not when the app is visible; on android 10+ launching from the background
  needs the overlay permission.
* `PackageInfo` and friends are mutable holders with `toMap()`/`fromMap(map)`;
  `toMap()` is the quickest way to log one (`jsonPretty(info.toMap())` with
  `package:tekartik_common_utils`).
* Type your field as `TekartikKiosk` (`TekartikKiosk kiosk =
  tekartikKioskPlugin;`) so tests can replace it with a
  `TekartikKioskMockMixin` fake; see the mode skill for the pattern.
* Anti-patterns: reading `getCurrentRunningPackageInfo` before the usage stats
  permission is granted (it fails or always returns your own package);
  polling the foreground package every 50ms from dart (the native watchdog of
  `startKioskMode` does that job); assuming `getInstalledPackageInfos` is
  cheap or that `getRunningProcesses` sees other apps.

## Examples

Wait for the usage stats permission, then follow the foreground app.

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_kiosk/tekartik_kiosk.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  TekartikKiosk kiosk = tekartikKioskPlugin;

  var info = await kiosk.getPermissionInfo();
  if (info.needPermissionForUsageStat) {
    // Opens the settings screen and returns right away: poll afterwards.
    await kiosk.requestPermissionForUsageStat();
    while (info.needPermissionForUsageStat) {
      await Future<void>.delayed(const Duration(seconds: 1));
      info = await kiosk.getPermissionInfo();
    }
  }

  String? previous;
  for (var i = 0; i < 60; i++) {
    var running = await kiosk.getCurrentRunningPackageInfo();
    if (running.package != previous) {
      previous = running.package;
      print('foreground: $previous');
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}
```

List the launchable user apps and start one.

```dart
import 'package:tekartik_kiosk/tekartik_kiosk.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';

/// The apps the user installed that have a launcher icon, by name.
Future<List<PackageInfo>> launchableApps() async {
  TekartikKiosk kiosk = tekartikKioskPlugin;
  var all = await kiosk.getInstalledPackageInfos();
  var apps = all
      .where((info) => (info.user ?? false) && (info.launchable ?? false))
      .toList();
  apps.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
  return apps;
}

Future<void> openApp(String packageName) async {
  TekartikKiosk kiosk = tekartikKioskPlugin;
  try {
    var info = await kiosk.getPackageInfo(packageName: packageName);
    print('launching ${info.name} ${info.version}');
  } catch (e) {
    print('$packageName is not installed: $e');
    return;
  }
  await kiosk.launch(packageName: packageName);
}
```

Bring this app back to the front when something else took over.

```dart
import 'package:tekartik_kiosk/tekartik_kiosk.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';

/// Dart side watchdog, only useful while the app is running: prefer
/// startKioskMode() for a real kiosk (see the tekartik-kiosk-mode skill).
Future<void> restoreToFront({
  Duration every = const Duration(seconds: 1),
  int count = 60,
}) async {
  TekartikKiosk kiosk = tekartikKioskPlugin;
  var me = (await kiosk.getPackageInfo()).package;
  for (var i = 0; i < count; i++) {
    var running = await kiosk.getCurrentRunningPackageInfo();
    if (running.package != me) {
      await kiosk.launch(); // null packageName: this app
    }
    await Future<void>.delayed(every);
  }
}
```

Dump the running processes for debugging.

```dart
import 'package:tekartik_kiosk/tekartik_kiosk.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';

Future<void> dumpProcesses() async {
  TekartikKiosk kiosk = tekartikKioskPlugin;
  for (var process in await kiosk.getRunningProcesses()) {
    // importance: lower means closer to the foreground.
    print('${process.importance} ${process.processName} '
        '${process.packages?.join(',')}');
  }
}
```
