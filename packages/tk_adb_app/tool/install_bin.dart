import 'build_menu.dart';

/// Installs the `tk_adb_app` command (`dart install`).
Future<void> main() async {
  await appLauncher.install();
}
