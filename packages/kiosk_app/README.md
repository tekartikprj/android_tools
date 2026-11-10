# tekartik_kiosk_app

An Android app to set up and watch a kiosk device with the
[tekartik_kiosk](../kiosk/README.md) plugin:

- **Dashboard**: the kiosk mode (the native watchdog keeping a target
  package in front: target package, check delay, extra allowed packages),
  the pinned mode (screen pinning), launch on boot, and the two permissions
  the watchdog needs (usage statistics, overlay), with a button to grant
  each.
- **Recorder**: the foreground package, polled every 0.5 s, each change
  logged (to check the watchdog).
- **Processes** and **Apps**: the running processes and the installed
  packages, to launch one or to pick the target package.

Android only. Run it on a device or an emulator:

```
cd packages/kiosk_app
flutter run -d <android device>
```

The options typed in the dashboard are used when you press START KIOSK (and
for the boot launch when you turn it on); they are saved by the plugin and
shown again at the next launch. The widget tests (`flutter test`) use a fake
plugin; `android/app/src/androidTest` holds instrumented tests of the native
utilities.
