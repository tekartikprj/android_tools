// ignore_for_file: depend_on_referenced_packages

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_kiosk/tekartik_kiosk.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';
import 'package:tekartik_test_menu_flutter/test_menu_flutter.dart';

void main() {
  var kiosk = tekartikKioskPlugin;
  mainMenuFlutter(() {
    menu('permission', () {
      item('getPermissionInfo', () async {
        var info = await tekartikKioskPlugin.getPermissionInfo();
        write('info $info');
      });
      item('requestPermissionForUsageStat', () async {
        var info = await tekartikKioskPlugin.requestPermissionForUsageStat();
        write('info $info');
      });
      item('requestOverlayPermission', () async {
        var info = await tekartikKioskPlugin.requestOverlayPermission();
        write('info $info');
      });
    });
    menu('packageInfo', () {
      item('getPackageInfo', () async {
        var info = await kiosk.getPackageInfo();
        write(jsonPretty(info.toMap())!);
      });
      item('getInstalledPackageInfos (user only)', () async {
        var info = (await kiosk.getInstalledPackageInfos())
            .where((item) => item.user ?? false)
            .map((item) => item.toMap());
        write(jsonPretty(info.toList())!);
        write(info.length);
      });
      item('getInstalledPackageInfos (launchable)', () async {
        var info = (await kiosk.getInstalledPackageInfos())
            .where((item) => item.launchable ?? false)
            .map((item) => item.toMap());
        write(jsonPretty(info.toList())!);
        write(info.length);
      });
      item('getInstalledPackageInfos (all)', () async {
        var info = (await kiosk.getInstalledPackageInfos())
            .map((item) => item.toMap());
        write(jsonPretty(info.toList())!);
        write(info.length);
      });
      item('getCurrentRunning during 1 mn', () async {
        String? previousPackageName;
        for (var i = 0; i < 60; i++) {
          var info = await kiosk.getCurrentRunningPackageInfo();
          if (info.package != previousPackageName) {
            previousPackageName = info.package;
            write(
                '${DateTime.now().toIso8601String().substring(7, 12)} $previousPackageName');
          }
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      });
    });

    Future<void> modeInfo() async {
      write(jsonPretty((await tekartikKioskPlugin.getModeInfo()).toMap())!);
    }

    menu('kiosk', () {
      item('start', () async {
        await tekartikKioskPlugin.startKioskMode();
        await modeInfo();
      });
      item('stop', () async {
        await tekartikKioskPlugin.stopKioskMode();
        await modeInfo();
      });
      item('info', () async {
        await modeInfo();
      });
    });

    menu('boot receiver', () {
      item('set', () async {
        await tekartikKioskPlugin.setBootReceiverOptions(BootReceiverOptions()
          ..package = (await tekartikKioskPlugin.getPackageInfo()).package);
        write('set');
      });
      item('unset', () async {
        await tekartikKioskPlugin.setBootReceiverOptions(BootReceiverOptions());
        write('unset');
      });
    });

    menu('pinned', () {
      item('start', () async {
        await tekartikKioskPlugin.startPinnedMode();
        await modeInfo();
      });
      item('stop', () async {
        await tekartikKioskPlugin.stopPinnedMode();
        await modeInfo();
      });
      item('info', () async {
        await modeInfo();
      });
    });
  }, showConsole: true);
}
