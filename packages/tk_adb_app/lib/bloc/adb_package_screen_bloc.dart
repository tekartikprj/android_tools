import 'package:festenao_common_flutter/common_utils_widget.dart';
import 'package:tk_adb_app/import.dart';
import 'package:tk_adb_app/src/bloc_poll.dart';

class AdbPackageScreenBlocState {
  final DumpsysPackageResult dumpsysPackageResult;

  AdbPackageScreenBlocState({required this.dumpsysPackageResult});
}

class AdbPackageScreenBloc
    extends AutoDisposeStateBaseBloc<AdbPackageScreenBlocState> {
  final String deviceSerial;
  final String packageName;

  AdbPackageScreenBloc({
    required this.deviceSerial,
    required this.packageName,
  }) {
    blocPollRefresh(this, const Duration(minutes: 1), refresh);
  }

  Future refresh() async {
    var result = await DeviceAdb(deviceSerial)
        .getDumpsysPackageInfo(packageName);
    if (!disposed) {
      add(AdbPackageScreenBlocState(dumpsysPackageResult: result));
    }
  }
}
