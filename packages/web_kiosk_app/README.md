# tekartik_web_kiosk_app

An Android kiosk app showing one web page full screen (a `webview_flutter`
web view), built on the `tekartik_kiosk` plugin of this repository.

- Configure: the url, a 4 digit passcode (`0000` when none) and the "Web kiosk
  enabled" switch. Enabling it asks for the usage stats and overlay
  permissions and sets the boot receiver, so the app comes back after a
  reboot.
- Start: the page, in pinned and kiosk mode when enabled (the plugin brings
  the app back to the front). Back navigates in the page; at its first page,
  back asks for the passcode, then stops the kiosk and the pinned mode and
  returns to the start screen.

Android only (the kiosk plugin); the settings are kept in a local sembast
database.

```sh
flutter run -d <android device>
```
