import 'package:tk_adb_app/import.dart';

class AvdManagerBlocState {
  final List<AvdInfo?> avdInfos;

  AvdManagerBlocState({required this.avdInfos});
}

class AvdManagerBloc extends BaseBloc {
  final _state = BehaviorSubject<AvdManagerBlocState>();
  ValueStream<AvdManagerBlocState> get state => _state;
  AvdManagerBloc() {
    refresh();
  }
  @override
  void dispose() {
    _state.close();
    super.dispose();
  }

  Future refresh() async {
    var list = await getAvdInfos();
    _state.add(AvdManagerBlocState(avdInfos: list));
  }
}

final avdManagerBloc = AvdManagerBloc();
