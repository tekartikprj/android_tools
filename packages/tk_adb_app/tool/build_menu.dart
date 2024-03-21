import 'dart:io';

import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

Future<void> buildRelease() async {
  await createProject('.');
  await buildProject('.');
}

Future<void> runRelease() async {
  await runBuiltProject('.');
}

Future main(List<String> arguments) async {
  var appPath = '.';
  mainMenuConsole(arguments, () {
    if (Platform.isWindows || Platform.isLinux) {
      /*item('build and run marker', () async {
        await createProject('.');
        await buildProject('.', target: 'lib/create_file_and_exit_main.dart');
        await runBuiltProject('.');
      });*/
      item('build and run $buildPlatformCurrent', () async {
        await buildRelease();
        await runRelease();
      });
      item('build $buildPlatformCurrent', () async {
        await buildRelease();
      });
      item('run $buildPlatformCurrent', () async {
        await runRelease();
      });
    }
    menuAppContent(path: appPath);
  });
}
