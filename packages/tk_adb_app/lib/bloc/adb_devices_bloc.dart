import 'package:tk_adb_app/import.dart';

class AdbDevicesBlocState {
  final List<AdbDeviceInfo> adbDeviceInfos;

  AdbDevicesBlocState({required this.adbDeviceInfos});
}

class AdbDevicesBloc extends BaseBloc {
  final _state = BehaviorSubject<AdbDevicesBlocState>();

  ValueStream<AdbDevicesBlocState> get state => _state;

  AdbDevicesBloc() {
    () async {
      while (!disposed) {
        refresh().unawait();
        await sleep(3000);
      }
    }();
  }

  @override
  void dispose() {
    _state.close();
    super.dispose();
  }

  Future refresh() async {
    var list = await getAdbDeviceInfos();
    _state.add(AdbDevicesBlocState(adbDeviceInfos: list));
  }
}

final adbDevicesBloc = AdbDevicesBloc();
