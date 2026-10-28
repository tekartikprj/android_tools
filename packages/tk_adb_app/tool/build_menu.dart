import 'package:tekartik_build_menu_flutter/app_build_menu.dart';
import 'package:tekartik_flutter_build/app_build_menu.dart'
    show menuFlutterAppHostLauncherContent;
import 'package:tekartik_flutter_build/app_launcher.dart';

/// Builds (`deploy/<platform>`), runs and installs the desktop release,
/// shared with `bin/tk_adb_app.dart`.
var appLauncher = FlutterAppHostLauncher(
  packageName: 'tk_adb_app',
  macosSandbox: false,
);

Future<void> main(List<String> arguments) async {
  mainMenuConsole(arguments, () {
    menuFlutterAppHostLauncherContent(launcher: appLauncher);
    menuFlutterAppContent(builder: appLauncher.appBuilder);
  });
}
