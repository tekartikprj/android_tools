// ignore: depend_on_referenced_packages
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_kiosk/tekartik_kiosk.dart';
import 'package:tekartik_test_menu_flutter/test.dart';

var kiosk = tekartikKioskPlugin;

void main() {
  mainMenu(() {
    /*
  test('crash', () {
    fail('fail');
  });
  */
    group('group', () {
      test('success', () {
        expect(true, isTrue);
        write('success');
      });
    });

    menu('kiosk', () {
      item('getCurrentRunningPackageInfo', () async {
        var info = await kiosk.getCurrentRunningPackageInfo();
        write(jsonPretty(info.toMap()));
      });
      item('getPermissionInfo', () async {
        var info = await kiosk.getPermissionInfo();
        write(jsonPretty(info.toMap()));
      });
      item('requestPermissionInfo', () async {
        var info = await kiosk.requestPermissionForUsageStat();
        write(jsonPretty(info.toMap()));
      });
      item('getPackageInfo', () async {
        var info = await kiosk.getPackageInfo();
        write(jsonPretty(info.toMap()));
      });
      item('getInstalledPackageInfos (user only)', () async {
        var info = (await kiosk.getInstalledPackageInfos())
            .where((item) => item.user ?? false)
            .map((item) => item.toMap());
        write(jsonPretty(info.toList()));
        write(info.length);
      });
      item('getInstalledPackageInfos (launchable)', () async {
        var info = (await kiosk.getInstalledPackageInfos())
            .where((item) => item.launchable ?? false)
            .map((item) => item.toMap());
        write(jsonPretty(info.toList()));
        write(info.length);
      });
      item('getInstalledPackageInfos (all)', () async {
        var info = (await kiosk.getInstalledPackageInfos())
            .map((item) => item.toMap());
        write(jsonPretty(info.toList()));
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

      item('restore to Front during 1 mn', () async {
        var currentPackage = (await kiosk.getPackageInfo()).package;
        String? previousPackageName;
        for (var i = 0; i < 60; i++) {
          var info = await kiosk.getCurrentRunningPackageInfo();
          if (info.package != previousPackageName) {
            previousPackageName = info.package;
            write(
                '${DateTime.now().toIso8601String().substring(7, 12)} $previousPackageName');
          }
          if (previousPackageName != currentPackage) {
            write('launching $currentPackage');
            await kiosk.launch();
          }
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      });

      item('restore to example app during 1 mn', () async {
        var currentPackage = (await kiosk.getPackageInfo()).package;
        var appPackage = 'com.example.kiosk';
        String? previousPackageName;
        for (var i = 0; i < 60; i++) {
          var info = await kiosk.getCurrentRunningPackageInfo();
          if (info.package != previousPackageName) {
            previousPackageName = info.package;
            write(
                '${DateTime.now().toIso8601String().substring(7, 12)} $previousPackageName');
          }
          if (previousPackageName != currentPackage &&
              previousPackageName != appPackage) {
            write('launching $appPackage');
            await kiosk.launch(packageName: appPackage);
          }
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      });
      item('launch example app', () async {
        await kiosk.launch(packageName: 'com.example.kiosk');
      });
    });
  }, showConsole: true);
}
