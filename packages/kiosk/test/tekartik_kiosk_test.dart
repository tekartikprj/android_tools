import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_kiosk/tekartik_kiosk.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('plugin', () {
    const channel = MethodChannel('tekartik_kiosk');
    late List<MethodCall> calls;

    /// Fake native results by method name.
    late Map<String, Object?> results;
    var plugin = TekartikKioskPlugin();

    setUp(() {
      calls = [];
      results = {};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return results[call.method];
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getModeInfo', () async {
      var map = {'kioskOn': true, 'pinnedOn': true, 'pinnedSupported': true};
      results['getModeInfo'] = map;
      var info = await plugin.getModeInfo();
      expect(info.kioskOn, isTrue);
      expect(info.pinnedOn, isTrue);
      expect(info.toMap(), map);
    });

    test('kiosk options', () async {
      var options = KioskOptions(
        package: 'com.example.app',
        allowedPackages: ['com.android.settings'],
        checkDelayMs: 500,
      );
      await plugin.startKioskMode(options: options);
      expect(calls.single.method, 'startKioskMode');
      // Native code stores and returns what it got.
      results['getKioskOptions'] = calls.single.arguments;
      var read = await plugin.getKioskOptions();
      expect(read.toMap(), options.toMap());
    });

    test('getPackageInfo', () async {
      var map = {'package': 'com.example.app', 'name': 'Example'};
      results['getPackageInfo'] = map;
      var info = await plugin.getPackageInfo(packageName: 'com.example.app');
      expect(calls.single.arguments, {'package': 'com.example.app'});
      expect(info.toMap(), {...map, 'version': null});
    });

    test('lists', () async {
      results['getInstalledPackageInfos'] = {
        'list': [
          {'package': 'com.alpha', 'name': 'Alpha'},
          {'package': 'com.beta', 'name': 'Beta'},
        ],
      };
      var packages = await plugin.getInstalledPackageInfos();
      expect(packages.map((e) => e.package), ['com.alpha', 'com.beta']);

      results['getRunningProcesses'] = {
        'list': [
          {'processName': 'com.alpha', 'importance': 100},
        ],
      };
      var processes = await plugin.getRunningProcesses();
      expect(processes.single.processName, 'com.alpha');
      expect(processes.single.importance, 100);
    });

    test('other results', () async {
      results['getPermissionInfo'] = {'needOverlayPermission': true};
      expect((await plugin.getPermissionInfo()).needOverlayPermission, isTrue);
      results['getBootReceiverOptions'] = {'package': 'com.example.app'};
      expect(
        (await plugin.getBootReceiverOptions()).package,
        'com.example.app',
      );
      results['getCurrentRunningPackageInfo'] = {'package': 'com.example.app'};
      expect(
        (await plugin.getCurrentRunningPackageInfo()).package,
        'com.example.app',
      );
    });

    test('invalid results', () async {
      await expectLater(plugin.getModeInfo(), throwsArgumentError);
      results['getInstalledPackageInfos'] = {'list': 'invalid'};
      await expectLater(plugin.getInstalledPackageInfos(), throwsArgumentError);
      results['getRunningProcesses'] = <String, Object?>{};
      await expectLater(plugin.getRunningProcesses(), throwsArgumentError);
    });
  });
}
