import 'package:tekartik_flutter_build/app_launcher.dart';

/// `tk_adb_app [-- --upgrade]`, see [flutterAppLauncherMain].
Future<void> main(List<String> arguments) => flutterAppLauncherMain(
  arguments,
  packageName: 'tk_adb_app',
  description:
      'Runs the adb tools desktop app (AVD manager, adb devices, kill '
      'emulators).',
  // Runs adb, emulator and avdmanager from the Android sdk.
  macosSandbox: false,
);
