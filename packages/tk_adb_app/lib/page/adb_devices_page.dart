import 'package:tk_adb_app/import.dart';
import 'package:tk_adb_app/page/adb_device_page.dart';

class AdbDevicesPageBlocState {
  final AdbDevicesBlocState state;
  List<AdbDeviceInfo> get adbDeviceInfos => state.adbDeviceInfos;

  AdbDevicesPageBlocState({required this.state});
}

class AdbDevicesPageBloc extends BaseBloc {
  final _state = BehaviorSubject<AdbDevicesPageBlocState>();
  StreamSubscription? _blocSubscription;
  ValueStream<AdbDevicesPageBlocState> get state => _state;
  AdbDevicesPageBloc() {
    _blocSubscription = adbDevicesBloc.state.listen((state) {
      _state.add(AdbDevicesPageBlocState(state: state));
    });
    refresh();
  }
  @override
  void dispose() {
    _state.close();
    _blocSubscription?.cancel();
    super.dispose();
  }

  Future refresh() async {
    await adbDevicesBloc.refresh();
  }
}

class AdbDevicesPage extends StatefulWidget {
  const AdbDevicesPage({super.key});

  @override
  State<AdbDevicesPage> createState() => _AdbDevicesPageState();
}

class _AdbDevicesPageState extends State<AdbDevicesPage> {
  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<AdbDevicesPageBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADB devices'),
      ),
      body: ValueStreamBuilder<AdbDevicesPageBlocState>(
        stream: bloc.state,
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          var adbDeviceInfos = snapshot.data!.adbDeviceInfos;
          return ListView.builder(
            itemCount: adbDeviceInfos.length,
            itemBuilder: (context, index) {
              var adbDeviceInfo = adbDeviceInfos[index];
              return ListTile(
                title: Text(adbDeviceInfo.serial!),
                onTap: () async {
                  await goToAdbDevicePage(context,
                      adbDeviceInfo: adbDeviceInfo);
                  await bloc.refresh();
                },
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> goToAdbDevicesPage(BuildContext context) async {
  await Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (context) => BlocProvider(
                blocBuilder: () => AdbDevicesPageBloc(),
                child: const AdbDevicesPage(),
              )));
}
