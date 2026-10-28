# tk_adb_app

Adb helper app: AVD manager, adb devices, kill the emulators.

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
