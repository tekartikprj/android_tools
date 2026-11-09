# tekartik_kiosk

An Android only Flutter plugin to keep an app in front, for a kiosk device:

* kiosk mode: a native watchdog service that brings back an app (this one,
  or another package) when something else comes to the foreground,
* pinned mode: Android screen pinning (`Activity.startLockTask`),
* a boot receiver that launches an app after a reboot,
* the installed packages, the foreground package, and launching a package.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`, Flutter):

```yaml
dependencies:
  tekartik_kiosk:
    git:
      url: https://github.com/tekartikprj/android_tools
      path: packages/kiosk
```

The plugin manifest declares its service, its boot receiver and the
permissions (`PACKAGE_USAGE_STATS`, `SYSTEM_ALERT_WINDOW`,
`QUERY_ALL_PACKAGES`, `RECEIVE_BOOT_COMPLETED`...): nothing to add to the
app manifest nor to its `MainActivity`.

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_kiosk/tekartik_kiosk.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  TekartikKiosk kiosk = tekartikKioskPlugin;

  // The watchdog needs to see the foreground app (usage stats) and to start
  // an activity from the background (overlay).
  var permission = await kiosk.getPermissionInfo();
  if (permission.needPermissionForUsageStat) {
    await kiosk.requestPermissionForUsageStat(); // opens the settings
    return; // check again when the user comes back
  }
  if (permission.needOverlayPermission) {
    await kiosk.requestOverlayPermission();
    return;
  }

  // Keep this app in front, the Settings app allowed too.
  var me = await kiosk.getPackageInfo();
  await kiosk.startKioskMode(
    options: KioskOptions(
      package: me.package,
      allowedPackages: ['com.android.settings'],
    ),
  );
}
```

Android only: on the other platforms each call throws a
`MissingPluginException`. The example app (`example/`) is a test menu
calling each method on a device.

## What to use

* `package:tekartik_kiosk/tekartik_kiosk.dart`: `tekartikKioskPlugin`, the
  plugin instance (a variable: a test can replace it).
* `package:tekartik_kiosk/tekartik_kiosk_api.dart`: the `TekartikKiosk`
  interface, the option and info classes, `TekartikKioskMockMixin` for test
  fakes.
* Kiosk mode: `startKioskMode(options: KioskOptions(...))`,
  `stopKioskMode()`, `setKioskOptions`/`getKioskOptions` (saved on the
  device, read at each check, every `checkDelayMs`, 400 ms by default).
* Pinned mode: `startPinnedMode()`, `stopPinnedMode()`, `getModeInfo()`.
* Boot: `setBootReceiverOptions(BootReceiverOptions(package: ...))`.
* Packages: `getPackageInfo()`, `getInstalledPackageInfos()`,
  `getCurrentRunningPackageInfo()`, `launch(packageName: ...)`.

## Common pitfalls

* Grant the usage stats and overlay permissions before `startKioskMode`:
  without them the watchdog cannot see the foreground app, or opens the
  overlay settings screen instead of the app.
* `requestPermissionForUsageStat()` and `requestOverlayPermission()` do not
  give the user's choice: poll `getPermissionInfo()` (on resume for
  example).
* A native error is a `PlatformException` (since 2026-11-09: before, a
  handled native error, such as `getModeInfo()` without an activity, left the
  call pending for ever).
* The watchdog is a started service, not a foreground one: Android may stop
  it while the kiosk app is in the background (another package kept in
  front).
* `getModeInfo().kioskOn` is kept in memory by the plugin: it is false after
  the app process restarted, even if the service runs again.
* `KioskService.setStartClass` (documented before) is not used: the app is
  relaunched with its launch intent.

## Agent skills

[skills/tekartik-kiosk-mode](skills/tekartik-kiosk-mode/SKILL.md) and
[skills/tekartik-kiosk-packages](skills/tekartik-kiosk-packages/SKILL.md).
