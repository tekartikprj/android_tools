import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';

void main() {
  group('api', () {
    test('ModeInfo', () {
      // As sent by the native code.
      var map = {'kioskOn': true, 'pinnedOn': true, 'pinnedSupported': true};
      var info = ModeInfo()..fromMap(map);
      expect(info.pinnedOn, isTrue);
      expect(info.toMap(), map);
      var copy = ModeInfo()..fromMap(info.toMap());
      expect(copy.toMap(), map);

      map = {'kioskOn': false, 'pinnedOn': false, 'pinnedSupported': false};
      expect((ModeInfo()..fromMap(map)).toMap(), map);
      expect((ModeInfo()..fromMap({})).toMap(), map);
    });

    test('KioskOptions', () {
      var options = KioskOptions(
        package: 'com.example.app',
        allowedPackages: ['com.android.settings'],
        checkDelayMs: 1000,
      );
      var map = {
        'package': 'com.example.app',
        'allowedPackages': ['com.android.settings'],
        'checkDelayMs': 1000,
      };
      expect(options.toMap(), map);
      expect((KioskOptions()..fromMap(map)).toMap(), map);

      expect(KioskOptions().toMap(), {
        'package': null,
        'allowedPackages': <String>[],
        'checkDelayMs': kioskCheckDelayMsDefault,
      });
      var empty = KioskOptions()..fromMap({});
      expect(empty.package, isNull);
      expect(empty.allowedPackages, isNull);
      expect(empty.checkDelayMs, isNull);
    });

    test('PermissionInfo', () {
      var map = {
        'needPermissionForUsageStat': true,
        'needOverlayPermission': false,
      };
      expect((PermissionInfo()..fromMap(map)).toMap(), map);
    });

    test('PackageInfo', () {
      var map = {
        'package': 'com.example.app',
        'name': 'Example',
        'version': '1.0.0',
        'user': true,
        'launchable': true,
      };
      expect((PackageInfo()..fromMap(map)).toMap(), map);
    });

    test('RunningProcessInfo', () {
      var map = {
        'processName': 'com.example.app',
        'importance': 100,
        'packages': ['com.example.app'],
      };
      expect((RunningProcessInfo()..fromMap(map)).toMap(), map);
    });

    test('BootReceiverOptions', () {
      var map = {'package': 'com.example.app'};
      expect((BootReceiverOptions()..fromMap(map)).toMap(), map);
    });
  });
}
