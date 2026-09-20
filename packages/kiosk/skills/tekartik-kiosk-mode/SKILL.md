---
name: tekartik-kiosk-mode
description: >-
  Use when locking an android flutter app to the foreground with tekartik_kiosk:
  tekartikKioskPlugin, TekartikKiosk, startKioskMode/stopKioskMode, KioskOptions
  (package, allowedPackages, checkDelayMs, kioskCheckDelayMsDefault),
  setKioskOptions/getKioskOptions, startPinnedMode/stopPinnedMode (android
  screen pinning), getModeInfo/ModeInfo (kioskOn, pinnedOn, pinnedSupported),
  BootReceiverOptions to relaunch an app at boot, plus the android MainActivity
  KioskService.setStartClass wiring and TekartikKioskMock for tests.
---

# Kiosk and pinned mode (tekartik_kiosk)

`tekartik_kiosk` is an android-only flutter plugin that keeps one app in the
foreground: a native watchdog service (kiosk mode), android screen pinning
(pinned mode) and a boot receiver that relaunches an app after a reboot.
Package inspection and the permissions those calls need are in the sibling
skill [tekartik-kiosk-packages](../tekartik-kiosk-packages/SKILL.md).

## Guidelines

* The package lives in a private repository and is not on pub.dev; depend on
  it from git:

  ```yaml
  dependencies:
    tekartik_kiosk:
      git:
        url: https://github.com/tekartikprj/android_tools
        path: packages/kiosk
  ```

* Two libraries, and `tekartik_kiosk.dart` does **not** re-export the api:
  * `package:tekartik_kiosk/tekartik_kiosk.dart` → `tekartikKioskPlugin`
    (the ready to use instance) and `TekartikKioskPlugin`.
  * `package:tekartik_kiosk/tekartik_kiosk_api.dart` → the abstract
    `TekartikKiosk` and every data class (`KioskOptions`,
    `BootReceiverOptions`, `ModeInfo`, `PackageInfo`, `PermissionInfo`,
    `RunningPackageInfo`, `RunningProcessInfo`, `DevModeInfo`),
    `kioskCheckDelayMsDefault`, `TekartikKioskMock` and
    `TekartikKioskMockMixin`.

  Import both as soon as you name an option class.
* Android only: the plugin declares just the `android` platform
  (`com.tekartik.kiosk.TekartikKioskPlugin`). Every call goes through the
  `tekartik_kiosk` method channel and throws `MissingPluginException` on
  other platforms — guard with `Platform.isAndroid` in a multi platform app,
  and call `WidgetsFlutterBinding.ensureInitialized()` before the first call
  in `main`.
* Hold the plugin through the `TekartikKiosk` interface
  (`TekartikKiosk kiosk = tekartikKioskPlugin;`): `tekartikKioskPlugin` is a
  plain top level variable, so a test can swap in a `TekartikKioskMock`.
* Android wiring in the **app** (not the plugin): the watchdog needs the
  activity class to relaunch, so the app `MainActivity` must register it:

  ```kotlin
  package com.example.myapp

  import android.os.Bundle
  import com.tekartik.kiosk.KioskService
  import io.flutter.embedding.android.FlutterActivity

  class MainActivity : FlutterActivity() {
      override fun onCreate(savedInstanceState: Bundle?) {
          super.onCreate(savedInstanceState)
          KioskService.setStartClass(this.javaClass)
      }
  }
  ```

  The plugin manifest already declares `KioskService`, the `BootReceiver` and
  the `GET_TASKS`, `QUERY_ALL_PACKAGES`, `RECEIVE_BOOT_COMPLETED`,
  `WRITE_SETTINGS`, `READ_PHONE_STATE`, `PACKAGE_USAGE_STATS` and
  `SYSTEM_ALERT_WINDOW` permissions, so the app manifest needs nothing extra.
* Kiosk mode (`startKioskMode({options})` / `stopKioskMode()`) starts a
  foreground watchdog service that polls the foreground package every
  `KioskOptions.checkDelayMs` milliseconds (default
  `kioskCheckDelayMsDefault`, 400) and relaunches `KioskOptions.package`
  whenever something else shows up. The kiosk app itself and the `android`
  system package are always allowed, plus everything in
  `allowedPackages`. With a null `package` the legacy behaviour applies: the
  kiosk app is brought back whenever it goes to the background.
* `setKioskOptions(options)` persists the options natively (they survive a
  restart and are re-read on every watchdog tick), `getKioskOptions()` reads
  them back. Passing `options:` to `startKioskMode` does both at once; change
  the allowed list while running by calling `setKioskOptions` again, no
  restart needed.
* The watchdog needs the usage stats permission to see the foreground package
  and the overlay permission to start an activity from the background: check
  `getPermissionInfo()` and request both before `startKioskMode`, otherwise
  the service will keep opening the overlay settings screen instead of
  restoring the app.
* Pinned mode (`startPinnedMode()` / `stopPinnedMode()`) is android screen
  pinning (`Activity.startLockTask`): it needs a foreground activity, shows
  the system "app pinned" toast and, unless the device is owned by a device
  policy, the user can leave it with back+recents. It is independent of kiosk
  mode; the two can be combined.
* `getModeInfo()` returns a `ModeInfo` with `kioskOn` (watchdog service
  running), `pinnedOn` (screen pinning active) and `pinnedSupported`; poll it
  to drive a toggle in the ui rather than keeping your own flag.
* Boot: `setBootReceiverOptions(BootReceiverOptions(package: 'com.x.y'))`
  stores the package the `BOOT_COMPLETED` receiver launches after a reboot,
  `BootReceiverOptions(package: null)` clears it, `getBootReceiverOptions()`
  reads it. Recent android versions still require the user to have launched
  the app at least once.
* Option objects are mutable holders with `toMap()`/`fromMap(map)` and no
  `const` constructor; only `KioskOptions` and `BootReceiverOptions` take
  named parameters, the others (`ModeInfo`, `PermissionInfo`...) are filled
  by the plugin.
* `setDevMode(DevModeInfo())` is `@Deprecated('Dev only')`: it only turns on
  native logging. Do not ship a call to it.
* Tests: the plugin needs a device. In unit/widget tests assign a fake to
  `tekartikKioskPlugin` (`class _Kiosk with TekartikKioskMockMixin` and
  override just the methods the test hits — the mixin throws
  `UnimplementedError` for the rest) and restore the plugin in `tearDown`.
* Anti-patterns: calling `startKioskMode` without the usage stats and overlay
  permissions; a `Timer` loop in dart relaunching the app instead of the
  native watchdog (dart stops running once the app is in the background);
  forgetting `KioskService.setStartClass` in `MainActivity` (nothing is
  relaunched); a `checkDelayMs` of a few milliseconds (it is a polling thread
  and it drains the battery).

## Examples

Start the watchdog on this app, with a few allowed packages.

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_kiosk/tekartik_kiosk.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  TekartikKiosk kiosk = tekartikKioskPlugin;

  var permission = await kiosk.getPermissionInfo();
  if (permission.needPermissionForUsageStat) {
    await kiosk.requestPermissionForUsageStat(); // opens the settings screen
    return; // come back once the user granted it
  }
  if (permission.needOverlayPermission) {
    await kiosk.requestOverlayPermission();
    return;
  }

  var me = await kiosk.getPackageInfo();
  await kiosk.startKioskMode(
    options: KioskOptions(
      package: me.package,
      allowedPackages: ['com.android.settings'],
      checkDelayMs: kioskCheckDelayMsDefault,
    ),
  );
}
```

Toggle kiosk and pinned mode from the ui, reading the current state.

```dart
import 'package:tekartik_kiosk/tekartik_kiosk.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';

/// Turns kiosk mode (native watchdog) on or off, keeping [package] in front.
Future<ModeInfo> toggleKiosk(String package) async {
  TekartikKiosk kiosk = tekartikKioskPlugin;
  var info = await kiosk.getModeInfo();
  if (info.kioskOn) {
    await kiosk.stopKioskMode();
  } else {
    await kiosk.startKioskMode(options: KioskOptions(package: package));
  }
  return kiosk.getModeInfo();
}

/// Screen pinning, only when the device supports it.
Future<void> togglePinned() async {
  TekartikKiosk kiosk = tekartikKioskPlugin;
  var info = await kiosk.getModeInfo();
  if (!info.pinnedSupported) {
    return;
  }
  if (info.pinnedOn) {
    await kiosk.stopPinnedMode();
  } else {
    await kiosk.startPinnedMode();
  }
}
```

Widen the allowed packages while the watchdog is running, and relaunch at boot.

```dart
import 'package:tekartik_kiosk/tekartik_kiosk.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';

/// Adds [package] to the packages the watchdog tolerates in the foreground.
Future<void> allowPackage(String package) async {
  TekartikKiosk kiosk = tekartikKioskPlugin;
  var options = await kiosk.getKioskOptions();
  var allowed = <String>{...?options.allowedPackages, package}.toList();
  await kiosk.setKioskOptions(
    KioskOptions(
      package: options.package,
      allowedPackages: allowed,
      checkDelayMs: options.checkDelayMs,
    ),
  );
}

/// Launch the kiosk app again after a reboot (null to disable).
Future<String?> launchAtBoot(String? package) async {
  TekartikKiosk kiosk = tekartikKioskPlugin;
  await kiosk.setBootReceiverOptions(BootReceiverOptions(package: package));
  return (await kiosk.getBootReceiverOptions()).package;
}
```

Fake the plugin in a test.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_kiosk/tekartik_kiosk.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';

class _FakeKiosk with TekartikKioskMockMixin {
  var kioskOn = false;

  @override
  Future<void> startKioskMode({KioskOptions? options}) async {
    kioskOn = true;
  }

  @override
  Future<ModeInfo> getModeInfo() async => ModeInfo()
    ..fromMap({'kioskOn': kioskOn, 'pinnedOn': false, 'pinnedSupported': true});
}

void main() {
  late TekartikKiosk saved;
  setUp(() {
    saved = tekartikKioskPlugin;
    tekartikKioskPlugin = _FakeKiosk();
  });
  tearDown(() => tekartikKioskPlugin = saved);

  test('kiosk mode', () async {
    await tekartikKioskPlugin.startKioskMode();
    expect((await tekartikKioskPlugin.getModeInfo()).kioskOn, isTrue);
  });
}
```
