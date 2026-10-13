import 'package:tk_adb_app/import.dart';
import 'package:tk_adb_app/src/bloc_poll.dart';

class AdbDevicesBlocState {
  final List<AdbDeviceInfo> adbDeviceInfos;

  AdbDevicesBlocState({required this.adbDeviceInfos});
}

class AdbDevicesBloc extends BaseBloc {
  final _state = BehaviorSubject<AdbDevicesBlocState>();

  ValueStream<AdbDevicesBlocState> get state => _state;

  AdbDevicesBloc() {
    blocPollRefresh(this, const Duration(seconds: 3), refresh);
  }

  @override
  void dispose() {
    _state.close();
    super.dispose();
  }

  Future refresh() async {
    var list = await getAdbDeviceInfos();
    if (!disposed) {
      _state.add(AdbDevicesBlocState(adbDeviceInfos: list));
    }
  }
}

final adbDevicesBloc = AdbDevicesBloc();
