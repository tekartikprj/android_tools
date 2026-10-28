import 'package:tk_adb_app/import.dart';

/// An installed package.
class AdbPackageInfo {
  /// The package name.
  final String name;

  /// Its version code, 0 when unknown.
  final int versionCode;

  /// True for a system package.
  final bool system;

  /// An installed package.
  AdbPackageInfo(this.name, this.versionCode, this.system);
}

/// Parses the output of `cmd package list packages --show-versioncode`
/// (`package:<name> versionCode:<code>` lines), the packages being [system]
/// ones or not.
List<AdbPackageInfo> adbPackageInfosParseLines(
  Iterable<String> lines, {
  bool system = false,
}) {
  var packages = <AdbPackageInfo>[];
  for (var line in lines) {
    String? name;
    int? versionCode;
    for (var keyValue in line.split(' ').map((e) => e.trim())) {
      var parts = keyValue.split(':');
      if (parts.length > 1) {
        if (parts[0] == 'package') {
          name = parts[1];
        } else if (parts[0] == 'versionCode') {
          versionCode = int.tryParse(parts[1]);
        }
      }
    }
    if (name != null) {
      packages.add(AdbPackageInfo(name, versionCode ?? 0, system));
    }
  }
  return packages;
}

/// Sorts [packages]: the third party ones first, then by name.
void adbPackageInfosSort(List<AdbPackageInfo> packages) {
  packages.sort((p1, p2) {
    if (p1.system != p2.system) {
      return p1.system ? 1 : -1;
    }
    return p1.name.compareTo(p2.name);
  });
}

/// The adb commands on one device used by the device page, faked in tests.
abstract class AdbDeviceShell {
  /// The installed packages, third party first.
  Future<List<AdbPackageInfo>> listPackages();

  /// Uninstalls [package], throws an [AdbUninstallException] on failure.
  Future<void> uninstall(String package);

  /// Reboots the device.
  Future<void> reboot();

  /// Kills the emulator.
  Future<void> killEmulator();

  /// Runs `adb -s <serial> <command>`, returns its output (stdout, then
  /// stderr).
  Future<String> command(String command);
}

/// An uninstall that failed.
class AdbUninstallException implements Exception {
  /// The package.
  final String package;

  /// What adb said.
  final String message;

  /// An uninstall that failed.
  AdbUninstallException(this.package, this.message);

  @override
  String toString() => '$package: $message';
}

/// The [AdbDeviceShell] running adb on the device [serial].
class AdbDeviceShellIo implements AdbDeviceShell {
  /// The device serial.
  final String serial;

  /// The adb commands on the device [serial].
  AdbDeviceShellIo(this.serial);

  Future<List<String>> _outLines(String command) async =>
      (await run('adb -s $serial $command')).outLines.toList();

  @override
  Future<List<AdbPackageInfo>> listPackages() async {
    var packages = <AdbPackageInfo>[
      ...adbPackageInfosParseLines(
        await _outLines(
          'shell cmd package list packages -s --show-versioncode',
        ),
        system: true,
      ),
      ...adbPackageInfosParseLines(
        await _outLines(
          'shell cmd package list packages -3 --show-versioncode',
        ),
      ),
    ];
    adbPackageInfosSort(packages);
    return packages;
  }

  @override
  Future<void> uninstall(String package) async {
    String output;
    try {
      output = (await run('adb -s $serial uninstall $package')).outText;
    } on ShellException catch (e) {
      output = [
        e.result?.outText,
        e.result?.errText,
      ].nonNulls.join('\n').trim();
      throw AdbUninstallException(package, output.isEmpty ? e.message : output);
    }
    if (!output.contains('Success')) {
      throw AdbUninstallException(package, output.trim());
    }
  }

  @override
  Future<void> reboot() async {
    await run('adb -s $serial reboot');
  }

  @override
  Future<void> killEmulator() async {
    await run('adb -s $serial emu kill');
  }

  @override
  Future<String> command(String command) async {
    try {
      var result = (await run('adb -s $serial $command', verbose: false)).first;
      return [
        result.outText,
        result.errText,
      ].where((text) => text.isNotEmpty).join('\n');
    } on ShellException catch (e) {
      return [
        e.result?.outText,
        e.result?.errText,
        if (e.result == null) e.message,
      ].nonNulls.where((text) => text.isNotEmpty).join('\n');
    }
  }
}
