import 'package:flutter_test/flutter_test.dart';
import 'package:tk_adb_app/src/adb_device_shell.dart';

void main() {
  test('adbPackageInfosParseLines', () {
    var packages = adbPackageInfosParseLines([
      'package:com.example.a versionCode:12',
      'package:com.example.b',
      '',
      'not a package',
    ]);
    expect(packages.map((package) => package.name), [
      'com.example.a',
      'com.example.b',
    ]);
    expect(packages.map((package) => package.versionCode), [12, 0]);
    expect(packages.every((package) => !package.system), isTrue);
    expect(
      adbPackageInfosParseLines([
        'package:android versionCode:36',
      ], system: true).single.system,
      isTrue,
    );
  });

  test('adbPackageInfosSort', () {
    var packages = [
      AdbPackageInfo('z.system', 1, true),
      AdbPackageInfo('b', 1, false),
      AdbPackageInfo('a.system', 1, true),
      AdbPackageInfo('a', 1, false),
    ];
    adbPackageInfosSort(packages);
    expect(packages.map((package) => package.name), [
      'a',
      'b',
      'a.system',
      'z.system',
    ]);
  });
}
