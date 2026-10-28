# tk_adb_app

Adb helper app: AVD manager, adb devices, kill the emulators.

## Screens

On the festenao theme (`festenao_theme` presets Festenao, Ardoise, Obsidian,
Contrast and light/dark, the palette button of the home page), the choice
kept in the app preferences.

- **Home**: the connected devices (live), the AVD manager, adb kill-server,
  adb connect, kill all emulators.
- **Device**: reboot, kill (an emulator), an adb command and its output, the
  installed packages with a filter; the **System** chip shows or hides the
  system packages (remembered). Uninstall one package with its trash icon, or
  select several (the checklist button or a long press, select all) and
  uninstall them with a single confirmation.

## Global command

`bin/tk_adb_app.dart` runs the desktop release built in `deploy/<platform>`
of the package sources, and builds it there (`flutter build <platform>`, the
platform project is created when missing) on the first run. The launcher
options come after `--`:

```bash
# from this folder (or dart run tool/install_bin.dart)
dart install .                   # or dart pub global activate --source path .

tk_adb_app                       # run it
tk_adb_app -- --upgrade          # rebuild the app, then run it
tk_adb_app -- --help
```

`dart install` resolves the dependencies from git (the workspace
`pubspec_overrides.yaml` does not apply), the sources then come from the
`pubspec.lock` of the installed bundle. Code in `tekartik_flutter_build`
(`app_launcher.dart`), shared with the `tool/` scripts and the dev menu
(`dart run tool/build_menu.dart`: build, run, debug run, install).

On macOS the app runs without the app sandbox (`macosSandbox: false`), so
that it can start adb and the emulators of the Android sdk.
