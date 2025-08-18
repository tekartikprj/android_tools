import 'package:festenao_common_flutter/common_utils_widget.dart';
import 'package:tk_adb_app/import.dart';

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
    () async {
      while (!disposed) {
        refresh().unawait();
        await sleep(60000);
      }
    }();
  }

  Future refresh() async {
    var result = await DeviceAdb(
      deviceSerial,
    ).getDumpsysPackageInfo(packageName);
    add(AdbPackageScreenBlocState(dumpsysPackageResult: result));
  }
}
